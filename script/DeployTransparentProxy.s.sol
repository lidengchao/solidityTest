// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TransparentUpgradeableNFT.sol";
import "../src/TransparentUpgradeableNFTMarketplace.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployTransparentProxyScript is Script {
    function run() external {
        // 加载部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // ==================== 部署 NFT 合约 ====================
        console.log("Deploying TransparentUpgradeableNFT...");
        
        // 部署 ProxyAdmin
        ProxyAdmin nftProxyAdmin = new ProxyAdmin();
        console.log("NFT ProxyAdmin deployed at:", address(nftProxyAdmin));
        
        // 部署 NFT 实现合约
        TransparentUpgradeableNFT nftImplementation = new TransparentUpgradeableNFT();
        console.log("NFT implementation deployed at:", address(nftImplementation));
        
        // 准备初始化数据
        bytes memory nftInitData = abi.encodeWithSelector(
            TransparentUpgradeableNFT.initialize.selector,
            "Transparent NFT",
            "TNFT"
        );
        
        // 部署透明代理合约
        TransparentUpgradeableProxy nftProxy = new TransparentUpgradeableProxy(
            address(nftImplementation),
            address(nftProxyAdmin),
            nftInitData
        );
        console.log("NFT proxy deployed at:", address(nftProxy));

        // ==================== 部署市场合约 ====================
        console.log("\nDeploying TransparentUpgradeableNFTMarketplace...");
        
        // 部署 ProxyAdmin（可以复用之前的，也可以新建）
        ProxyAdmin marketplaceProxyAdmin = new ProxyAdmin();
        console.log("Marketplace ProxyAdmin deployed at:", address(marketplaceProxyAdmin));
        
        // 部署市场实现合约
        TransparentUpgradeableNFTMarketplace marketplaceImplementation = new TransparentUpgradeableNFTMarketplace();
        console.log("Marketplace implementation deployed at:", address(marketplaceImplementation));
        
        // 准备初始化数据（使用刚才部署的NFT合约和假设的Token合约地址）
        address tokenContractAddress = 0xYourTokenContractAddress; // 替换为实际的Token合约地址
        bytes memory marketplaceInitData = abi.encodeWithSelector(
            TransparentUpgradeableNFTMarketplace.initialize.selector,
            address(nftProxy),
            tokenContractAddress
        );
        
        // 部署透明代理合约
        TransparentUpgradeableProxy marketplaceProxy = new TransparentUpgradeableProxy(
            address(marketplaceImplementation),
            address(marketplaceProxyAdmin),
            marketplaceInitData
        );
        console.log("Marketplace proxy deployed at:", address(marketplaceProxy));

        vm.stopBroadcast();
        console.log("\nDeployment completed!");
    }
}
