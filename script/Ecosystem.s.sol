// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Marketplace.sol";
import "../src/NFT/F3NFT.sol";
import "../src/F3Box.sol";
import "../src/peripherals/F3MultiView.sol";
import "../src/F3Token.sol";
import "../src/BUSDMock.sol";
import "../src/PoolReward.sol";
import "../src/tournament/TournamentRBT.sol";
import "../src/lottery/LotteryToken.sol";
import "../src/lottery/Lottery.sol";
import "forge-std/console.sol";
import "../src/Referral.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address busdAddress = vm.envAddress("BUSD_ADDRESS");
        BUSDMock busd = BUSDMock(busdAddress);
        if (busdAddress == address(0)) {
            busd = new BUSDMock();
        }
        console.log("BUSD_ADDRESS=", address(busd));

        address f3TokenAddress = vm.envAddress("F3_TOKEN_ADDRESS");
        F3 f3Token = F3(f3TokenAddress);
        if (f3TokenAddress == address(0)) {
            f3Token = new F3();
        }
        console.log("F3_TOKEN_ADDRESS=", address(f3Token));

        address f3NFTAddress = vm.envAddress("F3_NFT_ADDRESS");
        F3NFT nft = F3NFT(f3NFTAddress);
        if (f3NFTAddress == address(0)) {
            nft = new F3NFT(address(f3Token));
        }
        console.log("F3_NFT_ADDRESS=", address(nft));

        address payable poolRewardAddress = payable(vm.envAddress("POOL_REWARD_ADDRESS"));
        PoolReward poolReward = PoolReward(poolRewardAddress);
        if (poolRewardAddress == address(0)) {
            poolReward = new PoolReward(address(busd));
        }
        console.log("POOL_REWARD_ADDRESS=", address(poolReward));

        address randomAddress = vm.envAddress("RANDOM_ADDRESS");
        console.log("RANDOM_ADDRESS=", randomAddress);

        address refAddress = vm.envAddress("REF_ADDRESS");
        Referral ref = Referral(refAddress);
        if (refAddress == address(0)) {
            ref = new Referral();
        }
        console.log("REF_ADDRESS=", address(ref));

        address f3BoxAddress = vm.envAddress("F3_BOX_ADDRESS");
        F3Box box = F3Box(f3BoxAddress);
        if (f3BoxAddress == address(0)) {
            box = new F3Box(
                address(busd),
                address(nft),
                randomAddress,
                address(poolReward),
                address(f3Token),
                address(ref)
            );
            f3Token.grantRole(f3Token.MINTER_ROLE(), address(box));
        }

        console.log("F3_BOX_ADDRESS=", address(box));
        nft.grantRole(nft.MINTER_ROLE(), address(box));
        ref.grantRole(ref.UPDATE_ROLE(), address(box));

        vm.stopBroadcast();
    }
}

contract ExportWebConfig is Script {
    function setUp() public {}

    function run() public {
        address mkpAddress = vm.envAddress("MARKETPLACE_ADDRESS");
        console.log("NEXT_PUBLIC_MARKETPLACE_ADDRESS=", mkpAddress);

        address nftAddress = vm.envAddress("F3_NFT_ADDRESS");
        console.log("NEXT_PUBLIC_PANDA_NFT_ADDRESS=", nftAddress);

        address boxAddress = vm.envAddress("F3_BOX_ADDRESS");
        console.log("NEXT_PUBLIC_PANDA_BOX_ADDRESS=", boxAddress);

        address f3TokenAddress = vm.envAddress("F3_TOKEN_ADDRESS");
        console.log("NEXT_PUBLIC_PANDA_TOKEN_ADDRESS=", f3TokenAddress);

        address tournamentAddress = vm.envAddress("TOURNAMENT_ADDRESS");
        console.log("NEXT_PUBLIC_TOURNAMENT_ADDRESS=", tournamentAddress);

        address busdAddress = vm.envAddress("BUSD_ADDRESS");
        console.log("NEXT_PUBLIC_BUSD_TOKEN_ADDRESS=", busdAddress);

        address multiviewAddress = vm.envAddress("MULTI_VIEW_ADDRESS");
        console.log("NEXT_PUBLIC_MULTIVIEW_ADDRESS=", multiviewAddress);

        address lotteryAddress = vm.envAddress("LOTTERY_ADDRESS");
        console.log("NEXT_PUBLIC_LOTTERY_ADDRESS=", lotteryAddress);

        address lotteryTokenAddress = vm.envAddress("LOTTERY_TOKEN_ADDRESS");
        console.log("NEXT_PUBLIC_LOTTERY_TOKEN_ADDRESS=", lotteryTokenAddress);
    }
}
