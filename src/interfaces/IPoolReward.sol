pragma solidity ^0.8.19;

interface IPoolReward {
	event Claimed(address indexed pool, address indexed receiver, uint256 amount);
	event MergedTempPool(address indexed pool, uint256 amount);
	event MemberAdded(address indexed member, uint256 percentageReward);

	// define errors
	error PoolHasBeenAdded(address member);
	error MemberBalanceExceeded();
	error PoolNotExists(address pool);
    error ExpiredMember(address member);

	struct PoolMemberInfo {
		uint256 percentageReward;
		uint256 balance;
		uint256 claimed;
		uint256 addedAt;
	}

	function poolInfo(address pool) external view returns (PoolMemberInfo memory);

	function mergeTempToPool(address pool) external;

	function claim(uint256 amount, address receiver) external;

	function updateReward() external;

	function isNativeCurrencry() external view returns(bool);
}
