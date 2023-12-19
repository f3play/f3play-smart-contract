pragma solidity ^0.8.19;

import "./interfaces/IPoolMember.sol";
import "./interfaces/IPoolReward.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/access/Ownable.sol";

contract PoolReward is IPoolReward, Ownable {
	uint256 private _balance;
	mapping(address => PoolMemberInfo) private _memberInfos;
	address[] private _memberAddresses;
	IERC20 public immutable token;

	uint256 private constant _PERCENTAGE_PRECISION = 10000;

	constructor(address erc20Address_) {
		token = IERC20(erc20Address_);
	}

	function addMember(address member_, uint256 percentageReward_) external onlyOwner {
		if (_memberInfos[member_].addedAt > 0) {
			revert PoolHasBeenAdded(member_);
		}
        

        if (IPoolMember(member_).isExpired()) {
            revert ExpiredMember(member_);
        }
		_memberInfos[member_] = PoolMemberInfo({ percentageReward: percentageReward_, balance: 0, claimed: 0, addedAt: block.timestamp });
		_memberAddresses.push(member_);
		emit MemberAdded(member_, percentageReward_);
	}

	function updateReward() external {
		// anyone can call this function to sync _balance and token balance

		// 1. Get current token balance
		uint256 balance;
		if (isNativeCurrencry()) {
			balance = address(this).balance;
		} else {
			balance = token.balanceOf(address(this));
		}

		// 2. Get Unsynced balance
		uint256 addedBalance = balance - _balance;

		// 3. Distribute added balance
		_distribute(addedBalance);

		// 4. Update _balance
		_balance = balance;
	}

	function claim(uint256 amount_, address receiver_) external {
		// msg.sender can use itself balance to claim

		// 1. Check if balance of msg.sender is enough
		PoolMemberInfo storage memberInfo = _memberInfos[msg.sender];
		if (amount_ + memberInfo.claimed > memberInfo.balance) {
			revert MemberBalanceExceeded();
		}

		// 2. Update claimed amount of msg.sender
		memberInfo.claimed += amount_;

		// 3. Update Current balance of poolreward
		_balance -= amount_;

		// 4. Transfer token to receiver
		if (isNativeCurrencry()) {
			payable(receiver_).transfer(amount_);
		} else {
			token.transfer(receiver_, amount_);
		}
		

		emit Claimed(msg.sender, receiver_, amount_);
	}

	function _distribute(uint256 amount) internal {
		// distribute amount to all members
		uint256 remainedAmount = amount;

		for (uint256 i = 0; i < _memberAddresses.length; i++) {
			address member = _memberAddresses[i];
			PoolMemberInfo storage memberInfo = _memberInfos[member];
			if (IPoolMember(member).isExpired()) {
				continue;
			}
			uint256 reward = (amount * memberInfo.percentageReward) / _PERCENTAGE_PRECISION;
			memberInfo.balance += reward;
			remainedAmount -= reward;
		}

		// member at address 0 is temp pool
		if (remainedAmount > 0) {
			_memberInfos[address(0)].balance += remainedAmount;
		}
	}

	function mergeTempToPool(address pool) external onlyOwner {
		if (_memberInfos[pool].addedAt == 0) {
			revert PoolNotExists(pool);
		}

		PoolMemberInfo storage mPoolInfo = _memberInfos[pool];
		PoolMemberInfo storage tempInfo = _memberInfos[address(0)];

		mPoolInfo.balance += tempInfo.balance;

        emit MergedTempPool(pool, tempInfo.balance);

		tempInfo.balance = 0;
	}

	function emergencyWithdraw() external onlyOwner {
		if (isNativeCurrencry()) {
			payable(msg.sender).transfer(address(this).balance);
			return;
		}

		token.transfer(msg.sender, token.balanceOf(address(this)));
	}

	function poolInfo(address pool) external view override returns (PoolMemberInfo memory) {
		return _memberInfos[pool];
	}

	function isNativeCurrencry() public view returns (bool) {
		return address(token) == address(0);
	}

	receive() external payable {
		require(isNativeCurrencry(), "PoolReward: not native currency");
	}
}
