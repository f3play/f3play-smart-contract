pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Marketplace.sol";
import "../src/NFT/F3NFT.sol";
import "../src/MockRandom.sol";
import "../src/F3Box.sol";
import "../src/peripherals/F3MultiView.sol";
import "../src/F3Token.sol";
import "../src/BUSDMock.sol";
import "../src/PoolReward.sol";
import "../src/tournament/TournamentRBT.sol";
import "../src/lottery/LotteryToken.sol";
import "../src/lottery/Lottery.sol";
import "forge-std/console.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address f3TokenAddress = vm.envAddress("F3_TOKEN_ADDRESS");
        F3 f3Token = F3(f3TokenAddress);
        console.log("F3Token:", address(f3Token));

        address randomAddress = vm.envAddress("RANDOM_ADDRESS");
        ISecureRandom random = ISecureRandom(randomAddress);
        console.log("SecureRandom:", address(random));

        address f3BoxAddress = vm.envAddress("F3_BOX_ADDRESS");
        F3Box box = F3Box(f3BoxAddress);
        console.log("F3Box:", address(box));

        address lotteryTokenAddress = vm.envAddress("LOTTERY_TOKEN_ADDRESS");
        LotteryToken lotteryToken = LotteryToken(lotteryTokenAddress);
        if (lotteryTokenAddress == address(0)) {
            lotteryToken = new LotteryToken();
        }
        console.log("LOTTERY_TOKEN_ADDRESS=", address(lotteryToken));

        address lotteryAddress = vm.envAddress("LOTTERY_ADDRESS");
        Lottery lottery = Lottery(lotteryAddress);
        if (lotteryAddress == address(0)) {
            lottery = new Lottery(
                address(lotteryToken),
                f3TokenAddress,
                f3BoxAddress,
                randomAddress
            );
        }
        console.log("LOTTERY_ADDRESS=", address(lottery));
        box.grantRole(box.MINTER_ROLE(), address(lottery));
        f3Token.grantRole(f3Token.MINTER_ROLE(), address(lottery));
        lotteryToken.grantRole(lotteryToken.USER_ROLE(), address(lottery));

        vm.stopBroadcast();
    }
}
