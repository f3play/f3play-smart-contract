// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/security/Pausable.sol";
import "openzeppelin/access/Ownable.sol";

contract BUSDMock is ERC20, Ownable {
	constructor() ERC20("Tether", "USDT") {
		_mint(msg.sender, 100000000000000 * 10 ** decimals());
	}

	function mint(address to, uint256 amount) public onlyOwner {
		_mint(to, amount);
	}
}
