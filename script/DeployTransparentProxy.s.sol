// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TransparentUpgradeableNFT.sol";
import "../src/TransparentUpgradeableNFTMarketplace.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployTransparentProxyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.addr(deployerPrivateKey);
        address tokenContractAddress = vm.envAddress("TOKEN_CONTRACT_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying TransparentUpgradeableNFT...");
        TransparentUpgradeableNFT nftImplementation = new TransparentUpgradeableNFT();
        console.log("NFT implementation deployed at:", address(nftImplementation));

        bytes memory nftInitData = abi.encodeWithSelector(
            TransparentUpgradeableNFT.initialize.selector,
            "Transparent NFT",
            "TNFT"
        );

        TransparentUpgradeableProxy nftProxy = new TransparentUpgradeableProxy(
            address(nftImplementation),
            initialOwner,
            nftInitData
        );
        console.log("NFT proxy deployed at:", address(nftProxy));

        console.log("\nDeploying TransparentUpgradeableNFTMarketplace...");
        TransparentUpgradeableNFTMarketplace marketplaceImplementation = new TransparentUpgradeableNFTMarketplace();
        console.log("Marketplace implementation deployed at:", address(marketplaceImplementation));

        bytes memory marketplaceInitData = abi.encodeWithSelector(
            TransparentUpgradeableNFTMarketplace.initialize.selector,
            address(nftProxy),
            tokenContractAddress
        );

        TransparentUpgradeableProxy marketplaceProxy = new TransparentUpgradeableProxy(
            address(marketplaceImplementation),
            initialOwner,
            marketplaceInitData
        );
        console.log("Marketplace proxy deployed at:", address(marketplaceProxy));

        vm.stopBroadcast();
        console.log("\nDeployment completed!");
    }
}
