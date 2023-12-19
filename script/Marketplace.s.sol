// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/BUSDMock.sol";
import "../src/Marketplace.sol";
import "../src/NFT/F3NFT.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address token = vm.envAddress("BUSD_ADDRESS");
        address nft = vm.envAddress("F3_NFT_ADDRESS");
        uint256 feePerThousand = vm.envUint("MARKETPLACE_FEE_PER_THOUSAND");
        address feeRecipient = vm.envAddress("MARKETPLACE_FEE_RECIPIENT");

        console.log("BUSD_ADDRESS=", token);
        console.log("F3_NFT_ADDRESS=", nft);
        console.log("MARKETPLACE_FEE_PER_THOUSAND=", feePerThousand);
        console.log("MARKETPLACE_FEE_RECIPIENT=", feeRecipient);


        Marketplace mkp = new Marketplace(
            nft,
            token,
            feePerThousand,
            feeRecipient
        );
        console.log("MARKETPLACE_ADDRESS=", address(mkp));

        F3NFT(nft).grantRole(F3NFT(nft).TRANSFER_CENTER_ROLE(), address(mkp));

        vm.stopBroadcast();
    }
}

contract List is Script {
    uint256 deployerPrivateKey;
    address nftAddr;
    address mkpAddr;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        nftAddr = vm.envAddress("F3_NFT_ADDRESS");
        mkpAddr = vm.envAddress("MARKETPLACE_ADDRESS");
    }

    function run() public {
        address seller = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        F3NFT nft = F3NFT(nftAddr);
        if (!nft.isApprovedForAll(seller, mkpAddr)) {
            nft.setApprovalForAll(mkpAddr, true);
        }

        Marketplace mkp = Marketplace(mkpAddr);
        uint256[] memory ids = new uint256[](5);
        ids[0] = 59;
        ids[1] = 60;
        ids[2] = 81;
        ids[3] = 82;
        ids[4] = 83;
        mkp.list(ids, 69 ether);

        vm.stopBroadcast();
    }
}

contract Unlist is Script {
    uint256 deployerPrivateKey;
    address nftAddr;
    address mkpAddr;
    address busdAddr;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        nftAddr = vm.envAddress("F3_NFT_ADDRESS");
        busdAddr = vm.envAddress("BUSD_ADDRESS");
        mkpAddr = vm.envAddress("MARKETPLACE_ADDRESS");
    }

    function run() public {
        address seller = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        Marketplace mkp = Marketplace(mkpAddr);

        // mkp.unlist(59);
        // // mkp.unlist(60);
        // mkp.unlist(81);
        // mkp.unlist(82);

        F3NFT nft = F3NFT(nftAddr);
        if (nft.isApprovedForAll(seller, mkpAddr)) {
            nft.setApprovalForAll(mkpAddr, false);
        }

        BUSDMock busd = BUSDMock(busdAddr);
        busd.approve(mkpAddr, 0);

        vm.stopBroadcast();
    }
}
