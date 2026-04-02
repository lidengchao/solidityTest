// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TransparentUpgradeableNFTMarketplaceV2.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract UpgradeTransparentProxyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        address proxyAdminAddress = vm.envAddress("PROXY_ADMIN_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Upgrading TransparentUpgradeableNFTMarketplace...");
        console.log("Current proxy address:", proxyAddress);
        console.log("ProxyAdmin address:", proxyAdminAddress);

        TransparentUpgradeableNFTMarketplaceV2 newImplementation = new TransparentUpgradeableNFTMarketplaceV2();
        console.log("New implementation deployed at:", address(newImplementation));

        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(payable(proxyAddress)),
            address(newImplementation),
            bytes("")
        );
        console.log("Upgrade completed!");

        vm.stopBroadcast();
    }
}
