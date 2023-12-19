pragma solidity ^0.8.19;

interface IPoolMember {
	function isExpired() external view returns (bool);
}
