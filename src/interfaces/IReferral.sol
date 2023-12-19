pragma solidity ^0.8.19;

interface IReferral {
	event BalanceUpdated(address indexed user, address indexed ref, uint256 amount);
	event RefferalRegistered(address indexed user, address indexed ref);
	struct RefferralInfo {
		address[] referrals;
		uint256 rewardPercent;
	}

	struct RefHistory {
		address ref;
		uint256 balance;
		uint256 refAt;
	}

	function register(address user_, address referral) external;

	function rootOf(address user_) external view returns (address);

	function rewardPercentRootOfReferral(address user_) external view returns (uint256);

	function referralsInfo(address root_) external view returns (RefferralInfo memory);

	function updateBalance(address user_, address ref_, uint256 amount_) external;

	function refHistoryCounter(address _user) external view returns (uint256);

	function refHistory(address user_, uint256 index_) external view returns (RefHistory memory);
}
