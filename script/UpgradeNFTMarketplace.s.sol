// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/UpgradeableNFTMarketplaceV2.sol";

contract UpgradeNFTMarketplaceScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        UpgradeableNFTMarketplaceV2 newImplementation = new UpgradeableNFTMarketplaceV2();
        console.log("New implementation deployed at:", address(newImplementation));

        UpgradeableNFTMarketplaceV2(payable(proxyAddress)).upgradeToAndCall(address(newImplementation), bytes(""));
        console.log("Proxy upgraded to new implementation");

        vm.stopBroadcast();
    }
}
