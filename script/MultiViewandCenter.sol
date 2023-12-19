// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/peripherals/F3MultiView.sol";
import "forge-std/console.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address multiViewAddress = vm.envAddress("MULTI_VIEW_ADDRESS");
        F3MultiView multiView = F3MultiView(multiViewAddress);
        if (multiViewAddress == address(0)) {
            multiView = new F3MultiView();
        }
        console.log("Multiview:", address(multiView));

        vm.stopBroadcast();
    }
}
