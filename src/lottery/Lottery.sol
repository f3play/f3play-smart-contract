// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/access/AccessControl.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "../interfaces/IF3Box.sol";
import "../interfaces/IF3.sol";
import "../interfaces/ISecureRandom.sol";
import "../interfaces/ILottery.sol";
import "../utils/PreventContractCall.sol";
import "../F3Token.sol";
import "openzeppelin/security/Pausable.sol";

contract Lottery is ILottery, AccessControl, PreventContractCall, Pausable {
	IERC20 public immutable lotteryToken;
	IF3 public immutable f3Token;
	IF3Box public immutable f3Box;
	ISecureRandom private _secureRandom;

	event LuckyReward(address indexed owner, uint256 tokenAmount, uint256 boxAmount);

	mapping(uint256 => LotteryRewardHistory) private _lotteryRewardHistory;
	uint256 public lotteryRewardHistoryCounter;

	constructor(address lotteryToken_, address f3Token_, address f3Box_, address secureRandom_) {
		require(lotteryToken_ != address(0), "Lottery: lotteryToken_");
		require(f3Token_ != address(0), "Lottery: f3Token_");
		require(f3Box_ != address(0), "Lottery: f3Box_");
		require(secureRandom_ != address(0), "Lottery: secureRandom_");

		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

		lotteryToken = IERC20(lotteryToken_);
		f3Token = IF3(f3Token_);
		f3Box = IF3Box(f3Box_);
		_secureRandom = ISecureRandom(secureRandom_);
	}

	function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_pause();
	}

	function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_unpause();
	}

	function setSecureRandom(address secureRandom_) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(secureRandom_ != address(0), "Lottery: secureRandom_");
		_secureRandom = ISecureRandom(secureRandom_);
	}

	function lucky(uint256 amount_) external onlyEOA whenNotPaused {
		lotteryToken.transferFrom(msg.sender, address(this), amount_ * 1 ether);

		uint256 seed = _secureRandom.seed();

		uint256 rewardAmount = 0;
		uint256 boxReward = 0;
		for (uint256 i; i < amount_; i++) {
			uint256 random = _secureRandom.random(1, 100, seed);

			if (random > 6) {
				continue;
			}

			if (random > 1) {
				rewardAmount += 200 ether;
			} else {
				boxReward += 1;
			}
		}

		if (rewardAmount > 0) {
			f3Token.mint(msg.sender, rewardAmount);
		}

		if (boxReward > 0) {
			f3Box.mint(msg.sender, boxReward);
		}

		if (rewardAmount > 0 || boxReward > 0) {
			_lotteryRewardHistory[lotteryRewardHistoryCounter] = LotteryRewardHistory(msg.sender, rewardAmount, boxReward, block.timestamp);
			lotteryRewardHistoryCounter += 1;
			emit LuckyReward(msg.sender, rewardAmount, boxReward);
		}
	}

	function lotteryRewardHistory(uint256 index_) external view returns (LotteryRewardHistory memory) {
		return _lotteryRewardHistory[index_];
	}
}
