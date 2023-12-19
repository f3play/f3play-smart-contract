// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./MarketplaceSimple.sol";

contract Marketplace is MarketplaceSimple {
	using EnumerableSet for EnumerableSet.UintSet;
	EnumerableSet.UintSet private _listingIds;
	mapping(uint8 element => EnumerableSet.UintSet nfts) private _listingIdsByElement;
	mapping(uint8 rarity => EnumerableSet.UintSet nfts) private _listingIdsByRarity;
	mapping(uint16 elementAndRarity => EnumerableSet.UintSet nfts) private _listingIdsByElementAndRarity;
	mapping(address seller => EnumerableSet.UintSet nfts) private _listingIdsBySeller;

	struct Trade {
		uint256 listingId;
		address seller;
		address buyer;
		uint256 price;
		uint256 fee;
		uint256[] nftIds;
		uint256 timestamp;
		uint256 blockNumber;
	}

	mapping(uint256 tradeId => Trade) private _tradeById;
	uint256 private _tradeIdCounter;

	constructor(
		address _collection,
		address _currency,
		uint256 _feePerThousand,
		address _feeRecipient
	) MarketplaceSimple(_collection, _currency, _feePerThousand, _feeRecipient) {}

	function _combine(uint8 element, uint8 rarity) private pure returns (uint16) {
		return (uint16(element) << 8) + uint16(rarity);
	}

	function _addToMap(uint256 listingId, address seller, uint256[] calldata nftIds) private {
		_listingIds.add(listingId);
		_listingIdsBySeller[seller].add(listingId);

		for (uint256 i = 0; i < nftIds.length; i++) {
			F3NFT.Attribute memory attr = collection.attributes(nftIds[i]);
			_listingIdsByElement[attr.element].add(listingId);
			_listingIdsByRarity[attr.rarity].add(listingId);
			_listingIdsByElementAndRarity[_combine(attr.element, attr.rarity)].add(listingId);
		}
	}

	function _removeFromMap(uint256 listingId, address seller, uint256[] memory nftIds) private {
		_listingIds.remove(listingId);
		_listingIdsBySeller[seller].remove(listingId);

		for (uint256 i = 0; i < nftIds.length; i++) {
			F3NFT.Attribute memory attr = collection.attributes(nftIds[i]);
			_listingIdsByElement[attr.element].remove(listingId);
			_listingIdsByRarity[attr.rarity].remove(listingId);
			_listingIdsByElementAndRarity[_combine(attr.element, attr.rarity)].remove(listingId);
		}
	}

	function list(uint256[] calldata nftIds, uint256 price) external override nonReentrant whenNotPaused returns (uint256 listingId) {
		listingId = _list(nftIds, price);

		_addToMap(listingId, msg.sender, nftIds);
	}

	function unlist(uint256 listingId) external override nonReentrant {
		Listing memory listing = _unlist(listingId);

		_removeFromMap(listingId, listing.seller, listing.nftIds);
	}

	function buy(uint256 listingId) external payable override nonReentrant {
		(Listing memory listing, uint256 fee) = _buy(listingId);

		_removeFromMap(listingId, listing.seller, listing.nftIds);

		_tradeIdCounter++;
		_tradeById[_tradeIdCounter] = Trade({
			listingId: listingId,
			seller: listing.seller,
			buyer: msg.sender,
			price: listing.price,
			fee: fee,
			nftIds: listing.nftIds,
			timestamp: block.timestamp,
			blockNumber: block.number
		});
	}

	function recentTrades(uint256 offset, uint256 limit) external view returns (uint256 total, Trade[] memory trades) {
		total = _tradeIdCounter;
		if (offset >= total) {
			return (total, trades);
		}

		uint256 to = offset + limit;
		if (to > total) {
			to = total;
		}

		trades = new Trade[](to - offset);
		for (uint256 i = offset; i < to; i++) {
			trades[i - offset] = _tradeById[total - i];
		}

		return (total, trades);
	}

	function _listings(
		uint256 offset,
		uint256 limit,
		EnumerableSet.UintSet storage set
	) private view returns (uint256 total, Listing[] memory items) {
		total = set.length();
		if (offset >= total) {
			return (total, items);
		}

		uint256 to = offset + limit;
		if (to > total) {
			to = total;
		}

		items = new Listing[](to - offset);
		for (uint256 i = offset; i < to; i++) {
			items[i - offset] = _listingById[set.at(total - i - 1)];
		}
	}

	function recentListings(
		uint256 offset,
		uint256 limit,
		uint8 element,
		uint8 rarity
	) external view returns (uint256 total, Listing[] memory items) {
		if (element > 0 && rarity > 0) {
			return _listings(offset, limit, _listingIdsByElementAndRarity[_combine(element, rarity)]);
		} else if (element > 0) {
			return _listings(offset, limit, _listingIdsByElement[element]);
		} else if (rarity > 0) {
			return _listings(offset, limit, _listingIdsByRarity[rarity]);
		} else {
			return _listings(offset, limit, _listingIds);
		}
	}

	function recentListingsBySeller(
		uint256 offset,
		uint256 limit,
		address seller
	) external view returns (uint256 total, Listing[] memory items) {
		return _listings(offset, limit, _listingIdsBySeller[seller]);
	}
}
