// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TransparentUpgradeableNFTMarketplaceV2.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract UpgradeTransparentProxyScript is Script {
    function run() external {
        // 加载部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 现有代理合约和ProxyAdmin地址（需要替换为实际部署的地址）
        address proxyAddress = 0xYourProxyAddressHere;
        address proxyAdminAddress = 0xYourProxyAdminAddressHere;

        console.log("Upgrading TransparentUpgradeableNFTMarketplace...");
        console.log("Current proxy address:", proxyAddress);
        console.log("ProxyAdmin address:", proxyAdminAddress);

        // 部署新的实现合约
        TransparentUpgradeableNFTMarketplaceV2 newImplementation = new TransparentUpgradeableNFTMarketplaceV2();
        console.log("New implementation deployed at:", address(newImplementation));

        // 获取ProxyAdmin实例
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);

        // 执行升级
        proxyAdmin.upgrade(
            TransparentUpgradeableProxy(payable(proxyAddress)),
            address(newImplementation)
        );
        console.log("Upgrade completed!");

        // 如果需要调用初始化函数，使用 upgradeAndCall
        // bytes memory initData = abi.encodeWithSelector(
        //     TransparentUpgradeableNFTMarketplaceV2.someInitializationFunction.selector,
        //     param1,
        //     param2
        // );
        // proxyAdmin.upgradeAndCall(
        //     TransparentUpgradeableProxy(payable(proxyAddress)),
        //     address(newImplementation),
        //     initData
        // );

        vm.stopBroadcast();
    }
}
