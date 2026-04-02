// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/UpgradeableNFTMarketplaceV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeNFTMarketplaceScript is Script {
    function run() external {
        // 加载部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 现有代理合约地址（需要替换为实际部署的地址）
        address proxyAddress = 0xYourProxyAddressHere;

        // 部署新的实现合约
        UpgradeableNFTMarketplaceV2 newImplementation = new UpgradeableNFTMarketplaceV2();
        console.log("New implementation deployed at:", address(newImplementation));

        // 升级代理合约
        ERC1967Proxy proxy = ERC1967Proxy(payable(proxyAddress));
        proxy.upgradeTo(address(newImplementation));
        console.log("Proxy upgraded to new implementation");

        vm.stopBroadcast();
    }
}
