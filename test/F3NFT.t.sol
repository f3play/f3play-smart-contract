pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/NFT/F3NFT.sol";
import "src/F3Token.sol";
import "src/F3Box.sol";
import "../src/MockRandom.sol";
import "src/Referral.sol";
import "src/PoolReward.sol";
import "openzeppelin/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

contract F3NFTTest is Test {
	F3 _f3;
	F3NFT _f3NFT;
	F3Box _f3Box;
	PoolReward _poolReward;
	Referral _referral;

	// define users
	address _me;
	MockRandom _f3Random;

	function setUp() public {
		_me = vm.addr(1);
		vm.startPrank(_me, _me);
		_f3 = new F3();
		_f3NFT = new F3NFT(address(_f3));

		_f3.grantRole(_f3.MINTER_ROLE(), _me);
		_f3.mint(_me, 1000 ether);
		_f3Random = new MockRandom();

		_poolReward = new PoolReward(address(_f3));
		_referral = new Referral();

		_f3Box = new F3Box(address(_f3), address(_f3NFT), address(_f3Random), address(_poolReward), address(_f3), address(_referral));

		_f3.grantRole(_f3.MINTER_ROLE(), address(_f3Box));
		_f3NFT.grantRole(_f3NFT.MINTER_ROLE(), address(_f3Box));
		_referral.grantRole(_referral.UPDATE_ROLE(), address(_f3Box));
	}

	function testbuy() public {
		vm.startPrank(_me, _me);
		_f3.approve(address(_f3Box), 9999 ether);
		_f3Box.buyBox(5, address(0));
		_f3Box.openBox(5);
		assertEq(_f3NFT.balanceOf(_me), 5);
		vm.stopPrank();
	}
}
