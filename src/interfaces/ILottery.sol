pragma solidity ^0.8.19;

interface ILottery {
	struct LotteryRewardHistory {
		address owner;
		uint256 tokenAmount;
		uint256 boxAmount;
		uint256 openedAt;
	}

	function lotteryRewardHistoryCounter() external view returns (uint256);

	function lotteryRewardHistory(uint256) external view returns (LotteryRewardHistory memory);
}
