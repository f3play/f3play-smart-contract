// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

import "../src/Marketplace.sol";
import "../src/MarketplaceSimple.sol";
import "../src/NFT/F3NFT.sol";
import "../src/F3Token.sol";
import "../src/F3Box.sol";
import "../src/MockRandom.sol";
import "src/PoolReward.sol";
import "src/Referral.sol";

contract MarketplaceTest is Test {
	Marketplace mkp;
	F3NFT nft;
	F3 token;
	MockRandom rnd;
	F3Box box;
	PoolReward poolReward;
	address me;
	address feeRecipient;
	uint256 feePerThousand = 60;
	Referral _referral;

	function setUp() public {
		me = vm.addr(1);
		feeRecipient = vm.addr(100);

		token = new F3();
		token.grantRole(token.MINTER_ROLE(), me);
		vm.startPrank(me, me);
		token.mint(me, 1000 ether);
		vm.stopPrank();
		nft = new F3NFT(address(token));

		rnd = new MockRandom();

		poolReward = new PoolReward(address(token));

		_referral = new Referral();

		box = new F3Box(address(token), address(nft), address(rnd), address(poolReward), address(token), address(_referral));

		token.grantRole(token.MINTER_ROLE(), address(token));
		nft.grantRole(nft.MINTER_ROLE(), address(box));
		_referral.grantRole(_referral.UPDATE_ROLE(), address(box));

		mkp = new Marketplace(address(nft), address(token), feePerThousand, feeRecipient);

		nft.grantRole(nft.TRANSFER_CENTER_ROLE(), address(mkp));
	}

	function testConstructor() public {
		assertEq(address(mkp.collection()), address(nft));
		assertEq(address(mkp.currency()), address(token));
	}

	function prepareInv() internal {
		vm.startPrank(me, me);
		token.approve(address(box), 10 * box.BOX_PRICE());
		box.buyBox(10, address(0));
		box.openBox(10);
		nft.setApprovalForAll(address(mkp), true);
		vm.stopPrank();
	}

	function testList() public {
		prepareInv();

		vm.startPrank(me, me);

		uint256 itemId = 1;
		uint256 bal = nft.balanceOf(me);
		assertEq(nft.ownerOf(itemId), me);
		assertEq(nft.ownerOf(itemId + 1), me);

		// list
		uint256[] memory ids = new uint256[](2);
		ids[0] = itemId;
		ids[1] = itemId + 1;
		mkp.list(ids, 100 ether);
		assertEq(nft.balanceOf(me), bal - 2);
		assertEq(nft.ownerOf(itemId), address(mkp));

		(bool isListed, Marketplace.Listing memory listing) = mkp.listingByNftId(itemId + 1);
		assertTrue(isListed);
		assertEq(listing.nftIds, ids);
		assertEq(listing.price, 100 ether);
		assertEq(listing.seller, me);

		(isListed, listing) = mkp.listingByNftId(itemId + 2);
		assertFalse(isListed);
		assertEq(listing.nftIds.length, 0);

		ids = new uint256[](5);
		vm.expectRevert(abi.encodeWithSelector(MarketplaceSimple.ErrInvalidItemLength.selector, 5));
		mkp.list(ids, 100 ether);

		vm.stopPrank();
	}

	function testUnlist() public {
		prepareInv();

		vm.startPrank(me, me);

		uint256 itemId = 1;
		uint256 bal = nft.balanceOf(me);

		// list
		uint256[] memory ids = new uint256[](1);
		ids[0] = itemId;
		mkp.list(ids, 100 ether);
		assertEq(nft.balanceOf(me), bal - 1);
		assertEq(nft.ownerOf(itemId), address(mkp));

		// unlist
		mkp.unlist(itemId);
		assertEq(nft.balanceOf(me), bal);
		assertEq(nft.ownerOf(itemId), me);

		// list
		ids = new uint256[](1);
		ids[0] = itemId;
		mkp.list(ids, 100 ether);
		assertEq(nft.balanceOf(me), bal - 1);
		assertEq(nft.ownerOf(itemId), address(mkp));

		vm.stopPrank();
	}

	function testBuy() public {
		prepareInv();

		uint256 itemId = 1;
		address buyer = vm.addr(2);
		uint256 myTokenBal = token.balanceOf(me);
		uint256 myNFTBal = nft.balanceOf(me);
		uint256 price = 25 ether;
		uint256 fee = (price * feePerThousand) / 1000;
		vm.startPrank(me, me);
		token.mint(buyer, 200 ether);
		vm.stopPrank();

		vm.startPrank(me, me);
		uint256[] memory ids = new uint256[](1);
		ids[0] = itemId;
		uint256 listingId = mkp.list(ids, price);
		assertEq(listingId, 1);
		vm.stopPrank();

		vm.startPrank(buyer, buyer);
		token.approve(address(mkp), price);
		mkp.buy(listingId);
		vm.stopPrank();

		assertEq(nft.balanceOf(me), myNFTBal - 1);
		assertEq(nft.balanceOf(buyer), 1);
		assertEq(nft.ownerOf(itemId), buyer);
		assertEq(token.balanceOf(me), myTokenBal + price - fee);
		assertEq(token.balanceOf(buyer), 200 ether - price);
		assertEq(token.balanceOf(feeRecipient), fee);

		vm.startPrank(buyer, buyer);
		nft.setApprovalForAll(address(mkp), true);
		ids = new uint256[](1);
		ids[0] = itemId;
		uint256 newListingId = mkp.list(ids, price);
		vm.stopPrank();

		vm.startPrank(me, me);
		token.approve(address(mkp), price);
		mkp.buy(newListingId);
		vm.stopPrank();
	}

	function testListings() public {
		prepareInv();

		vm.startPrank(me, me);

		uint256 bal = nft.balanceOf(me);

		for (uint256 itemId = 1; itemId <= 10; itemId++) {
			// list
			uint256[] memory ids = new uint256[](1);
			ids[0] = itemId;
			uint256 id = mkp.list(ids, 100 ether);
			assertEq(id, itemId);
			assertEq(nft.balanceOf(me), bal - itemId);
			assertEq(nft.ownerOf(itemId), address(mkp));
		}

		(uint256 total, Marketplace.Listing[] memory listings) = mkp.recentListings(0, 5, 0, 0);
		assertEq(total, 10);
		assertEq(listings.length, 5);
		for (uint256 i = 0; i < listings.length; i++) {
			assertEq(listings[i].nftIds[0], 10 - i);
			assertEq(listings[i].price, 100 ether);
			assertEq(listings[i].seller, me);
		}

		(total, listings) = mkp.recentListingsBySeller(0, 5, me);
		assertEq(total, 10);
		assertEq(listings.length, 5);

		(total, ) = mkp.recentListings(0, 5, 3, 0);
		(total, ) = mkp.recentListings(0, 5, 0, 1);

		vm.stopPrank();
	}
}
