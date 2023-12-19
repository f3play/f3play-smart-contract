// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin/security/Pausable.sol";
import "openzeppelin/access/AccessControl.sol";
import "openzeppelin/token/ERC721/extensions/ERC721Burnable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "../interfaces/IF3NFT.sol";

abstract contract BaseF3NFT is IF3NFT, ERC721Enumerable, Pausable, AccessControl, ERC721Burnable {
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant TRANSFER_CENTER_ROLE = keccak256("TRANSFER_CENTER_ROLE");

	mapping(uint256 tokenId => Attribute) internal _attributes;

	uint256 public tokenIdCounter;
	IERC20 public immutable f3Token;

	constructor(address f3Token_) ERC721("F3", "F3") {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(PAUSER_ROLE, msg.sender);
		_grantRole(MINTER_ROLE, msg.sender);
		f3Token = IERC20(f3Token_);
	}

	// ------- Admin Functions --------------------
	function pause() public onlyRole(PAUSER_ROLE) {
		_pause();
	}

	function unpause() public onlyRole(PAUSER_ROLE) {
		_unpause();
	}

	function safeMint(address to_, Attribute memory attribute_) public onlyRole(MINTER_ROLE) {
		tokenIdCounter++;
		_safeMint(to_, tokenIdCounter);
		_attributes[tokenIdCounter] = attribute_;
	}

	// internals
	function _beforeTokenTransfer(
		address from_,
		address to_,
		uint256 tokenId_,
		uint256 batchSize_
	) internal override(ERC721, ERC721Enumerable) whenNotPaused {
		super._beforeTokenTransfer(from_, to_, tokenId_, batchSize_);
		if (from_ == address(0) || to_ == address(this) || to_ == address(0)) {
			return;
		}

		if (!hasRole(TRANSFER_CENTER_ROLE, from_) && !hasRole(TRANSFER_CENTER_ROLE, to_)) {
			revert OnlyWhitelistCanTransfer();
		}
	}

	// View Functions

	function attributes(uint256 tokenId_) external view returns (Attribute memory) {
		return _attributes[tokenId_];
	}

	// The following functions are overrides required by Solidity.
	function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165, ERC721Enumerable, AccessControl) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}
