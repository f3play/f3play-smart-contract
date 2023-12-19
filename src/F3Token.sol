// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/AccessControl.sol";

import "./interfaces/IF3.sol";

contract F3 is IF3, ERC20, AccessControl {
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

	uint256 public constant HARDCAP = 4_206_900_000 ether;

	constructor() ERC20("F3 Token", "F3") {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_mint(msg.sender, HARDCAP / 10);
	}

	function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
		require(totalSupply() + amount <= HARDCAP, "F3: HARDCAP");
		_mint(to, amount);
	}
}
