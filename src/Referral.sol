// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/access/AccessControl.sol";
import "./interfaces/IReferral.sol";

contract Referral is IReferral, AccessControl {
	bytes32 public constant UPDATE_ROLE = keccak256("UPDATE_ROLE");

	mapping(address => address) private _rootOf;
	mapping(address => RefferralInfo) private _refInfo;
	mapping(address => uint256) public refBalances;
	mapping(address => mapping(uint256 => RefHistory)) private _refHistory;
	mapping(address => uint256) private _refHistoryCounter;

	constructor() {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function register(address user_, address referral_) external onlyRole(UPDATE_ROLE) {
		if (_rootOf[user_] != address(0) || referral_ == address(0) || referral_ == user_) {
			return;
		}

		_rootOf[user_] = referral_;
		_refInfo[referral_].referrals.push(user_);

		emit RefferalRegistered(user_, referral_);

		uint256 refTotals = _refInfo[referral_].referrals.length;

		if (refTotals > 50) {
			_refInfo[referral_].rewardPercent = 10;
		} else if (refTotals > 10) {
			_refInfo[referral_].rewardPercent = 5;
		} else {
			_refInfo[referral_].rewardPercent = 3;
		}
	}

	function updateBalance(address user_, address ref_, uint256 amount_) external onlyRole(UPDATE_ROLE) {
		refBalances[user_] += amount_;
		_refHistory[user_][_refHistoryCounter[user_]] = RefHistory(ref_, amount_, block.timestamp);
		_refHistoryCounter[user_]++;

		emit BalanceUpdated(user_, ref_, amount_);
	}

	function rootOf(address user_) external view returns (address) {
		return _rootOf[user_];
	}

	function rewardPercentRootOfReferral(address user_) external view returns (uint256) {
		address root = _rootOf[user_];
		return _refInfo[root].rewardPercent;
	}

	function referralsInfo(address root_) external view returns (RefferralInfo memory) {
		return _refInfo[root_];
	}

	function refHistoryCounter(address _user) external view returns (uint256) {
		return _refHistoryCounter[_user];
	}

	function refHistory(address _user, uint256 index_) external view returns (RefHistory memory) {
		return _refHistory[_user][index_];
	}
}
