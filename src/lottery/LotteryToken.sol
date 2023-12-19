// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/AccessControl.sol";

contract LotteryToken is ERC20, AccessControl {
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant USER_ROLE = keccak256("USER_ROLE");

	constructor() ERC20("F3 Lottery", "F3LT") {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
		_mint(to, amount);
	}

	function _spendAllowance(address owner, address spender, uint256 amount) internal virtual override {
		if (hasRole(USER_ROLE, spender)) {
			return;
		}
		super._spendAllowance(owner, spender, amount);
	}
}
