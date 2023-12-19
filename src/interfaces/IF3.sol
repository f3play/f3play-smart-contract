pragma solidity ^0.8.19;
import "openzeppelin/token/ERC20/IERC20.sol";

interface IF3 is IERC20 {
	function mint(address to_, uint256 amount_) external;
}
