// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/Pausable.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/token/ERC721/IERC721Receiver.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/utils/structs/EnumerableSet.sol";
import "./NFT/F3NFT.sol";

contract MarketplaceSimple is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
	using SafeERC20 for IERC20;

	F3NFT public immutable collection;
	IERC20 public immutable currency;
	uint256 public feePerThousand;
	address public feeRecipient;
	uint256 public maxListingCount = 4;

	error ErrInvalidItemLength(uint256 length);
	error ErrItemNotListed(uint256 nftId);
	error ErrItemAlreadyListed(uint256 nftId);
	error ErrNotItemOwner(uint256 nftId, address addr);
	error ErrNotListingOwner(uint256 listingId, address addr);
	error ErrInvalidPrice(uint256 price);
	error ErrItemTransactionFailed(uint256 nftId, address from, address to);
	error ErrTransactionFailed(uint256 amount, address from, address to);
	error ErrInvalidFeeRecipient(address addr);
	error ErrInvalidListingId(uint256 listingId);
	error ErrInvalidFeePerThousand(uint256 feePerThousand);

	struct Listing {
		uint256 id;
		address seller;
		uint256 price;
		uint256[] nftIds;
	}

	mapping(uint256 listingId => Listing) internal _listingById;
	mapping(uint256 nftId => uint256 listingId) internal _listingIdByNftId;
	uint256 internal _listingIdCounter;

	event Listed(address indexed seller, uint256 indexed listingId, uint256 price);
	event Unlisted(address indexed seller, uint256 indexed listingId);
	event Bought(address indexed seller, address indexed buyer, uint256 indexed listingId);
	event FeeRecipientChanged(address indexed feeRecipient);
	event FeePerThousandChanged(uint256 indexed feePerThousand);
	event MaxListingCountChanged(uint256 indexed maxListingCount);

	constructor(address _collection, address _currency, uint256 _feePerThousand, address _feeRecipient) {
		if (_feeRecipient == address(0)) {
			revert ErrInvalidFeeRecipient(_feeRecipient);
		}

		collection = F3NFT(_collection);
		currency = IERC20(_currency);
		feePerThousand = _feePerThousand;
		feeRecipient = _feeRecipient;
	}

	function setFeeRecipient(address _feeRecipient) external onlyOwner {
		if (_feeRecipient == address(0) || _feeRecipient == feeRecipient) {
			revert ErrInvalidFeeRecipient(_feeRecipient);
		}

		feeRecipient = _feeRecipient;
		emit FeeRecipientChanged(_feeRecipient);
	}

	function setFeePerThousand(uint256 _feePerThousand) external onlyOwner {
		if (_feePerThousand > 1000) {
			revert ErrInvalidFeePerThousand(_feePerThousand);
		}

		feePerThousand = _feePerThousand;
		emit FeePerThousandChanged(_feePerThousand);
	}

	function setMaxListingCount(uint256 _maxListingCount) external onlyOwner {
		maxListingCount = _maxListingCount;
		emit MaxListingCountChanged(_maxListingCount);
	}

	function _list(uint256[] calldata nftIds, uint256 price) internal returns (uint256 listingId) {
		if (nftIds.length == 0 || nftIds.length > maxListingCount) {
			revert ErrInvalidItemLength(nftIds.length);
		}
		if (price == 0) {
			revert ErrInvalidPrice(price);
		}

		listingId = ++_listingIdCounter;
		for (uint256 i = 0; i < nftIds.length; i++) {
			uint256 nftId = nftIds[i];
			if (_listingIdByNftId[nftId] != 0) {
				revert ErrItemAlreadyListed(nftId);
			}
			if (collection.ownerOf(nftId) != msg.sender) {
				revert ErrNotItemOwner(nftId, msg.sender);
			}
			_listingIdByNftId[nftId] = listingId;
			collection.safeTransferFrom(msg.sender, address(this), nftId);
		}

		_listingById[listingId] = Listing({ id: listingId, seller: (msg.sender), nftIds: nftIds, price: price });

		emit Listed(msg.sender, listingId, price);

		return listingId;
	}

	function list(uint256[] calldata nftIds, uint256 price) external virtual nonReentrant whenNotPaused returns (uint256 listingId) {
		return _list(nftIds, price);
	}

	function _unlist(uint256 listingId) internal returns (Listing memory listing) {
		listing = _listingById[listingId];
		if (listing.id != listingId) {
			revert ErrInvalidListingId(listingId);
		}

		if (listing.seller != msg.sender) {
			revert ErrNotListingOwner(listing.id, msg.sender);
		}

		for (uint256 i = 0; i < listing.nftIds.length; i++) {
			uint256 nftId = listing.nftIds[i];

			collection.safeTransferFrom(address(this), msg.sender, nftId);

			delete _listingIdByNftId[nftId];
		}

		delete _listingById[listingId];

		emit Unlisted(msg.sender, listingId);
	}

	function unlist(uint256 listingId) external virtual nonReentrant {
		_unlist(listingId);
	}

	function isNativeCurrency() public view returns (bool) {
		return address(currency) == address(0);
	}

	function _buy(uint256 listingId) internal returns (Listing memory listing, uint256 fee) {
		listing = _listingById[listingId];
		if (listing.id != listingId) {
			revert ErrInvalidListingId(listingId);
		}

		if (isNativeCurrency() && listing.price != msg.value) {
			revert ErrInvalidPrice(listing.price);
		}

		fee = (listing.price * feePerThousand) / 1000;
		uint256 profit = listing.price - fee;
		if (isNativeCurrency()) {
			payable(listing.seller).transfer(profit);
			payable(feeRecipient).transfer(fee);
		} else {
			currency.safeTransferFrom(msg.sender, listing.seller, profit);
			currency.safeTransferFrom(msg.sender, feeRecipient, fee);
		}

		for (uint256 i = 0; i < listing.nftIds.length; i++) {
			uint256 nftId = listing.nftIds[i];
			collection.safeTransferFrom(address(this), msg.sender, nftId);

			delete _listingIdByNftId[nftId];
		}

		delete _listingById[listingId];
		emit Bought(listing.seller, msg.sender, listingId);

		return (listing, fee);
	}

	function buy(uint256 listingId) external payable virtual nonReentrant {
		require(isNativeCurrency() || msg.value == 0, "MarketplaceSimple: msg.value must be 0 when not using native currency");
		_buy(listingId);
	}

	function listingByNftId(uint256 nftId) external view returns (bool isListed, Listing memory listing) {
		uint256 listingId = _listingIdByNftId[nftId];
		if (listingId > 0) {
			return (true, _listingById[listingId]);
		}
	}

	function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
		return IERC721Receiver.onERC721Received.selector;
	}
}
