pragma solidity ^0.8.0;

import "./BokkyPooBahsRedBlackTreeLibrary_vn.sol";
import "openzeppelin/utils/structs/EnumerableSet.sol";

library EloRanking {
	using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
	using EnumerableSet for EnumerableSet.AddressSet;

	uint256 public constant TOP = 150;
	uint256 public constant NEW_SCORE = 1500;

	struct Data {
		uint256 count;
		BokkyPooBahsRedBlackTreeLibrary.Tree rankedTree;
		mapping(address => UserInfo) users;
		EnumerableSet.AddressSet ranked;
		EnumerableSet.AddressSet unRanked;
		address[] rankedFinal;
	}

	struct UserInfo {
		uint256 score;
		uint256 battleCount;
		uint256 status; // 0: not registered, 1: registered
	}

	function exists(Data storage self, address addr) internal view returns (bool) {
		return self.users[addr].status != 0;
	}

	function add(Data storage self, address addr) internal returns (bool) {
		if (exists(self, addr)) {
			return false;
		}

		self.users[addr] = UserInfo({ status: 1, battleCount: 0, score: NEW_SCORE });

		self.unRanked.add(addr);
		self.count++;

		return true;
	}

	function finalizeRank(Data storage self) internal {
		if (self.rankedFinal.length > 0) {
			return;
		}
		uint256 count = 0;
		address next = address(uint160(self.rankedTree.last()));
		while (count < 100) {
			if (next == address(0)) {
				break;
			}
			self.rankedFinal.push(next);
			next = address(uint160(self.rankedTree.prev(uint160(next))));
			count++;
		}
	}

	function changeScore(Data storage self, address addr, uint256 newScore) internal {
		require(exists(self, addr), "EloRanking: user not exists");

		bool isRankedUser = self.ranked.contains(addr);
		self.users[addr].score = newScore;
		if (isRankedUser) {
			self.rankedTree.remove(uint160(addr));
			self.rankedTree.insert(uint160(addr), _lessThan, _getSlot(self));
		} else if (_canAddToRanged(self, newScore)) {
			self.ranked.add(addr);
			self.rankedTree.insert(uint160(addr), _lessThan, _getSlot(self));
			self.unRanked.remove(addr);

			while (self.ranked.length() > TOP) {
				uint minUserKey = self.rankedTree.first();
				self.rankedTree.remove(minUserKey);
				self.ranked.remove(address(uint160(minUserKey)));
				self.unRanked.add(address(uint160(minUserKey)));
			}
		}
	}

	function _canAddToRanged(Data storage self, uint256 score) private view returns (bool) {
		return self.ranked.length() < TOP || self.users[address(uint160(self.rankedTree.first()))].score < score;
	}

	function _lessThan(uint key0, uint key1, uint256 dataSlot) private view returns (bool) {
		Data storage data = _getData(dataSlot);

		return data.users[address(uint160(key0))].score < data.users[address(uint160(key1))].score;
	}

	function _getSlot(Data storage d) private pure returns (uint256 slot) {
		assembly {
			slot := d.slot
		}
	}

	function _getData(uint256 slot) private pure returns (Data storage d) {
		assembly {
			d.slot := slot
		}
	}

	function unRankedAt(Data storage self, uint256 index) internal view returns (address) {
		return self.unRanked.at(index);
	}

	function rankedAt(Data storage self, uint256 index) internal view returns (address) {
		return self.ranked.at(index);
	}

	function rankedContains(Data storage self, address addr) internal view returns (bool) {
		return self.ranked.contains(addr);
	}

	function rankedCount(Data storage self) internal view returns (uint256) {
		return self.ranked.length();
	}

	function unRankedCount(Data storage self) internal view returns (uint256) {
		return self.unRanked.length();
	}
}
