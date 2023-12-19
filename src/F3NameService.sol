// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin/token/ERC20/IERC20.sol";

contract F3NameService {
	IERC20 public f3Token;

	uint256 public constant UPDATE_NICKNAME_FEE = 1000 ether;

	mapping(address => bytes32) public addressToName;
	mapping(bytes32 => address) public nameToAddress;

	event NicknameUpdated(address indexed account, bytes32 name);

	error NameAlreadyRegistered();

	constructor(address f3Token_) {
		f3Token = IERC20(f3Token_);
	}

	function setNickname(bytes32 name_) external {
		if (nameToAddress[name_] != address(0)) {
			revert NameAlreadyRegistered();
		}

		if (addressToName[msg.sender] != bytes32(0)) {
			f3Token.transferFrom(msg.sender, address(this), UPDATE_NICKNAME_FEE);
		}

		addressToName[msg.sender] = name_;
		nameToAddress[name_] = msg.sender;

		emit NicknameUpdated(msg.sender, name_);
	}
}
