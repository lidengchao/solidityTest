// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MyToken.sol";
import "../src/UpgradeableNFT.sol";
import "../src/UpgradeableNFTMarketplaceV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/interfaces/IERC1363.sol";

contract ScenarioTestScript is Script {
    function run() external {
        // 加载私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 模拟不同用户的地址
        address userA = vm.addr(1); // 部署MyToken并购买NFT
        address userB = vm.addr(2); // 部署NFT和市场合约
        address userC = vm.addr(3); // 铸造NFT
        
        console.log("User A address:", userA);
        console.log("User B address:", userB);
        console.log("User C address:", userC);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // ==================== 步骤1: A部署MyToken ====================
        console.log("\n1. User A deploys MyToken...");
        MyToken myToken = new MyToken();
        console.log("MyToken deployed at:", address(myToken));
        
        // 给User A mint一些token
        myToken.mint(userA, 1000 ether);
        console.log("User A balance:", myToken.balanceOf(userA));
        
        // ==================== 步骤2: B部署UpgradeableNFT ====================
        console.log("\n2. User B deploys UpgradeableNFT...");
        UpgradeableNFT nftImplementation = new UpgradeableNFT();
        console.log("NFT implementation deployed at:", address(nftImplementation));
        
        // 部署NFT代理合约
        bytes memory nftInitData = abi.encodeWithSelector(
            UpgradeableNFT.initialize.selector,
            "Test NFT",
            "TNFT"
        );
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImplementation), nftInitData);
        UpgradeableNFT upgradeableNFT = UpgradeableNFT(address(nftProxy));
        console.log("NFT proxy deployed at:", address(nftProxy));
        
        // 转移NFT合约所有权给User B
        upgradeableNFT.transferOwnership(userB);
        console.log("NFT contract owner:", upgradeableNFT.owner());
        
        // ==================== 步骤3: B部署UpgradeableNFTMarketplace ====================
        console.log("\n3. User B deploys UpgradeableNFTMarketplace...");
        UpgradeableNFTMarketplaceV2 marketplaceImplementation = new UpgradeableNFTMarketplaceV2();
        console.log("Marketplace implementation deployed at:", address(marketplaceImplementation));
        
        // 部署市场代理合约
        bytes memory marketplaceInitData = abi.encodeWithSelector(
            UpgradeableNFTMarketplaceV2.initialize.selector,
            address(upgradeableNFT),
            address(myToken)
        );
        ERC1967Proxy marketplaceProxy = new ERC1967Proxy(address(marketplaceImplementation), marketplaceInitData);
        UpgradeableNFTMarketplaceV2 upgradeableMarketplace = UpgradeableNFTMarketplaceV2(address(marketplaceProxy));
        console.log("Marketplace proxy deployed at:", address(marketplaceProxy));
        
        // 转移市场合约所有权给User B
        upgradeableMarketplace.transferOwnership(userB);
        console.log("Marketplace contract owner:", upgradeableMarketplace.owner());
        
        vm.stopBroadcast();
        
        // ==================== 步骤4: C铸造NFT ====================
        console.log("\n4. User C mints NFT...");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_2")); // 使用User B的私钥
        
        // User B作为NFT合约所有者，铸造NFT给User C
        upgradeableNFT.safeMint(userC, "https://example.com/nft/1");
        console.log("NFT minted to User C");
        console.log("NFT owner:", upgradeableNFT.ownerOf(0));
        
        vm.stopBroadcast();
        
        // ==================== 步骤5: C授权NFT给市场 ====================
        console.log("\n5. User C approves NFT to marketplace...");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_3")); // 使用User C的私钥
        
        // User C授权NFT给市场合约
        upgradeableNFT.setApprovalForAll(address(upgradeableMarketplace), true);
        console.log("NFT approved for marketplace");
        console.log("Is approved for all:", upgradeableNFT.isApprovedForAll(userC, address(upgradeableMarketplace)));
        
        vm.stopBroadcast();
        
        // ==================== 步骤6: C上架NFT ====================
        console.log("\n6. User C lists NFT...");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_3")); // 使用User C的私钥
        
        // User C上架NFT，价格为100 token
        upgradeableMarketplace.listNFT(0, 100 ether);
        console.log("NFT listed for 100 tokens");
        
        // 检查上架信息
        (address seller, uint256 price, bool active) = upgradeableMarketplace.getListing(0);
        console.log("Listing info - Seller:", seller, "Price:", price, "Active:", active);
        
        vm.stopBroadcast();
        
        // ==================== 步骤7: A购买NFT ====================
        console.log("\n7. User A buys NFT...");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_1")); // 使用User A的私钥
        
        // User A授权token给市场合约
        myToken.approve(address(upgradeableMarketplace), 100 ether);
        console.log("Token approved for marketplace");
        
        // User A使用transferAndCall购买NFT
        bytes memory data = abi.encode(0); // tokenId = 0
        IERC1363(address(myToken)).transferAndCall(
            address(upgradeableMarketplace),
            100 ether,
            data
        );
        console.log("NFT purchased");
        
        // 检查交易结果
        console.log("New NFT owner:", upgradeableNFT.ownerOf(0));
        console.log("User A token balance:", myToken.balanceOf(userA));
        console.log("User C token balance:", myToken.balanceOf(userC));
        
        vm.stopBroadcast();
        
        console.log("\nScenario test completed successfully!");
    }
}
