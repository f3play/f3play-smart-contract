pragma solidity ^0.8.19;
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";

interface IF3NFT is IERC721Enumerable {
	// events
	event ERC20TokenSet(address indexed erc20Token);

	// errors
	error NotOwner();
	error InvalidRarityForUpgrade();
	error InvalidElementMaterial();
	error InvalidRarityMaterial();
	error OnlyWhitelistCanTransfer();
	error CannotUseItselfToUpgrade();

	struct Attribute {
		uint8 element;
		uint8 rarity;
		uint16 baseRate;
		uint16 baseAttack;
		uint16 baseDefense;
		uint32 attack;
		uint32 defense;
		uint32 level;
		uint32 hashRate;
		uint256 bornAt;
	}

	function safeMint(address to_, Attribute calldata attribute_) external;

	function attributes(uint256) external view returns (IF3NFT.Attribute memory);

	function upgrade(uint256 tokenId_, uint256[] calldata materialNFTs_) external;

	function tokenIdCounter() external view returns (uint256);
}
