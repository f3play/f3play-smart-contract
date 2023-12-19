// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract PreventContractCall {
	error ContractNotAllowed();

	modifier onlyEOA() {
		if (tx.origin != msg.sender) {
			revert ContractNotAllowed();
		}
		_;
	}
}
