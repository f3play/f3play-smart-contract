// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin/token/ERC1155/ERC1155.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC1155/extensions/ERC1155Burnable.sol";
import "openzeppelin/access/AccessControl.sol";
import "./interfaces/IF3NFT.sol";
import "./interfaces/ISecureRandom.sol";
import "./interfaces/IPoolReward.sol";
import "./interfaces/IF3Box.sol";
import "./interfaces/IReferral.sol";
import "forge-std/console.sol";
import "./utils/PreventContractCall.sol";
import "./F3Token.sol";
import "openzeppelin/security/Pausable.sol";

contract F3Box is IF3Box, PreventContractCall, ERC1155, ERC1155Burnable, AccessControl, Pausable {
	uint256 public constant FEE_NOMINATOR = 1000;
	uint256 public constant FEE_PERCENT = 60;
	uint256 public BOX_PRICE;
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	uint256 public boxCounter;

	mapping(address => mapping(uint256 => OpenBoxHistory)) private _openBoxHistories;
	mapping(address => uint256) private _openBoxHistoryCounter;

	IF3NFT public f3NFT;
	IERC20 public currencyToken;
	F3 public f3Token;
	IPoolReward public poolReward;
	IReferral public immutable referral;
	ISecureRandom private _secureRandom;
	address private _feeReceiver;

	// define events
	event PoolRewardSet(address poolReward);
	event BoxOpened(address indexed owner, uint256[] nfts, uint256 tokenAmount);
	event BuyBox(address indexed owner, uint256 quantity, uint256 totalPrice);
	// define errors
	error NotEnoughBoxes();

	constructor(
		address currencyTokenAddress_,
		address f3NFTAddress_,
		address secureRandomAddress_,
		address poolRewardAddress_,
		address f3TokenAddress_,
		address refferal_
	) ERC1155("") {
		require(f3NFTAddress_ != address(0), "F3Box: f3NFTAddress_");
		require(secureRandomAddress_ != address(0), "F3Box: secureRandomAddress_");
		require(poolRewardAddress_ != address(0), "F3Box: poolRewardAddress_");
		require(f3TokenAddress_ != address(0), "F3Box: f3TokenAddress_");
		require(refferal_ != address(0), "F3Box: refferal_");
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

		currencyToken = IERC20(currencyTokenAddress_);
		f3NFT = IF3NFT(f3NFTAddress_);
		poolReward = IPoolReward(poolRewardAddress_);
		_secureRandom = ISecureRandom(secureRandomAddress_);
		f3Token = F3(f3TokenAddress_);
		referral = IReferral(refferal_);
		_feeReceiver = msg.sender;

		if (isNativeCurrency()) {
			BOX_PRICE = 15 ether / 1000;
		} else {
			BOX_PRICE = 3 ether;
		}
	}

	function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_pause();
	}

	function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_unpause();
	}

	function setPoolReward(address poolReward_) external onlyRole(DEFAULT_ADMIN_ROLE) {
		poolReward = IPoolReward(poolReward_);
		emit PoolRewardSet(poolReward_);
	}

	function openBoxHistories(address owner_, uint256 tokenId_) external view returns (OpenBoxHistory memory) {
		return _openBoxHistories[owner_][tokenId_];
	}

	function openBoxHistoryCounter(address owner_) external view returns (uint256) {
		return _openBoxHistoryCounter[owner_];
	}

	function buyBox(uint256 quantity, address ref) public payable onlyEOA whenNotPaused {
		require(quantity > 0, "F3Box: quantity must be greater than 0");
		referral.register(msg.sender, ref);

		uint256 price = quantity * BOX_PRICE;

		uint256 fee = (price * FEE_PERCENT) / FEE_NOMINATOR;

		if (isNativeCurrency()) {
			require(price == msg.value, "F3Box: price must be equal to msg.value");
		} else {
			require(msg.value == 0, "F3Box: msg.value must be equal to 0");
		}

		uint256 refReward = (price * referral.rewardPercentRootOfReferral(msg.sender)) / FEE_NOMINATOR;

		if (refReward > 0) {
			address root = referral.rootOf(msg.sender);
			_transferCurrencty(msg.sender, root, refReward);

			referral.updateBalance(root, msg.sender, refReward);
		}

		_transferCurrencty(msg.sender, _feeReceiver, fee - refReward);
		_transferCurrencty(msg.sender, address(poolReward), price - fee);

		poolReward.updateReward();

		emit BuyBox(msg.sender, quantity, price);

		_mint(msg.sender, 0, quantity, "");
	}

	function mint(address to_, uint256 amount) external onlyRole(MINTER_ROLE) {
		_mint(to_, 0, amount, "");
	}

	function openBox(uint256 quantity) public onlyEOA whenNotPaused {
		require(quantity <= 10 && quantity > 0, "F3Box: quantity must be less or equal than 10");

		if (balanceOf(msg.sender, 0) < quantity) {
			revert NotEnoughBoxes();
		}

		uint256 tokenId = f3NFT.tokenIdCounter();
		uint256[] memory ids = new uint256[](quantity);

		uint256 seed = _secureRandom.seed();
		uint256 f3TokenAmount = _secureRandom.random(0, 200 * quantity, seed) * 1 ether;
		try f3Token.mint(msg.sender, f3TokenAmount) {} catch {
			f3TokenAmount = 0;
		}

		for (uint256 i = 0; i < quantity; i++) {
			f3NFT.safeMint(msg.sender, _randomAttribute(seed));
			ids[i] = tokenId + i + 1;
		}

		OpenBoxHistory memory history = OpenBoxHistory({
			owner: msg.sender,
			nfts: ids,
			tokenAmount: f3TokenAmount,
			openedAt: block.timestamp
		});

		_openBoxHistories[msg.sender][_openBoxHistoryCounter[msg.sender]] = history;
		_openBoxHistoryCounter[msg.sender]++;
		_openBoxHistories[address(0)][_openBoxHistoryCounter[address(0)]] = history;
		_openBoxHistoryCounter[address(0)]++;

		emit BoxOpened(msg.sender, ids, f3TokenAmount);

		_burn(msg.sender, 0, quantity);
	}

	function _randomAttribute(uint256 seed) internal returns (IF3NFT.Attribute memory attribute) {
		attribute.element = _randomElement(seed);
		attribute.rarity = _randomRarity(attribute.element, seed);
		attribute.baseRate = _randomBaseRate(attribute.rarity, seed);
		attribute.baseAttack = _randomBaseRate(attribute.rarity, seed);
		attribute.baseDefense = _randomBaseRate(attribute.rarity, seed);

		attribute.hashRate = attribute.baseRate;
		attribute.attack = attribute.baseAttack;
		attribute.defense = attribute.baseDefense;

		attribute.level = 1;
		attribute.bornAt = block.timestamp;
	}

	function _randomRarity(uint256 element, uint256 seed) internal returns (uint8) {
		uint256 random = _secureRandom.random(1, 10000, seed);

		if (random > 5000) {
			return 1;
		} else if (random > 1500) {
			return 2;
		} else if (random > 300) {
			return 3;
		} else if (random > 50) {
			if (element % 3 == 0) {
				return 3;
			}
			return 4;
		} else {
			if (element % 3 > 0) {
				return 3;
			}
			return 5;
		}
	}

	function _randomElement(uint256 seed_) internal returns (uint8) {
		return uint8(_secureRandom.random(1, 9, seed_));
	}

	function _randomBaseRate(uint32 rarity_, uint256 seed_) internal returns (uint16 rate) {
		if (rarity_ == 1) {
			rate = 10;
		} else if (rarity_ == 2) {
			rate = 20;
		} else if (rarity_ == 3) {
			rate = 40;
		} else if (rarity_ == 4) {
			rate = uint16(_secureRandom.random(100, 200, seed_));
		} else if (rarity_ == 5) {
			rate = uint16(_secureRandom.random(500, 1000, seed_));
		}
	}

	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal override {
		if (from == address(0)) {
			for (uint256 i = 0; i < amounts.length; ) {
				unchecked {
					boxCounter += amounts[i];
					i++;
				}
			}
		}
	}

	function isNativeCurrency() public view returns (bool) {
		return address(currencyToken) == address(0);
	}

	function _transferCurrencty(address sender_, address receiver_, uint256 amount_) internal {
		if (isNativeCurrency()) {
			payable(receiver_).transfer(amount_);
		} else {
			currencyToken.transferFrom(sender_, receiver_, amount_);
		}
	}

	// The following functions are overrides required by Solidity.
	function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}
