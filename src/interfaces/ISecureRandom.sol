pragma solidity ^0.8.9;

interface ISecureRandom {
	function random(uint256 min, uint256 max, uint256 salt) external returns (uint256);

	function seed() external returns (uint256);
}
