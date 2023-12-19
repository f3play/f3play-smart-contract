pragma solidity ^0.8.19;
import "openzeppelin/token/ERC721/IERC721.sol";
import "./IF3NFT.sol";

interface IF3Box {
	struct OpenBoxHistory {
		address owner;
		uint256[] nfts;
		uint256 tokenAmount;
		uint256 openedAt;
	}

	function openBoxHistoryCounter(address) external view returns (uint256);

	function openBoxHistories(address, uint256) external view returns (OpenBoxHistory memory);

	function mint(address to_, uint256 amount) external;
}
