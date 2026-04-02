// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/ERC1363Token.sol";
import "../src/UpgradeableNFT.sol";
import "../src/UpgradeableNFTMarketplaceV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/interfaces/IERC1363.sol";

contract ScenarioTestScript is Script {
    function run() external {
        address userA = vm.addr(1);
        address userB = vm.addr(2);
        address userC = vm.addr(3);

        console.log("User A address:", userA);
        console.log("User B address:", userB);
        console.log("User C address:", userC);

        (ERC1363Token myToken, UpgradeableNFT upgradeableNFT, UpgradeableNFTMarketplaceV2 upgradeableMarketplace) =
            _deployContracts(userA, userB);

        _mintAndApprove(upgradeableNFT, upgradeableMarketplace, userC);
        _listNft(upgradeableMarketplace, userC);
        _buyNft(myToken, upgradeableNFT, upgradeableMarketplace, userA, userC);
    }

    function _deployContracts(
        address userA,
        address userB
    ) internal returns (ERC1363Token myToken, UpgradeableNFT upgradeableNFT, UpgradeableNFTMarketplaceV2 upgradeableMarketplace) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("\n1. User A deploys ERC1363Token...");
        myToken = new ERC1363Token("Test Token", "TTK", 1000 ether);
        console.log("ERC1363Token deployed at:", address(myToken));

        myToken.mint(userA, 1000 ether);
        console.log("User A balance:", myToken.balanceOf(userA));

        console.log("\n2. User B deploys UpgradeableNFT...");
        UpgradeableNFT nftImplementation = new UpgradeableNFT();
        bytes memory nftInitData = abi.encodeWithSelector(UpgradeableNFT.initialize.selector, "Test NFT", "TNFT");
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImplementation), nftInitData);
        upgradeableNFT = UpgradeableNFT(address(nftProxy));
        console.log("NFT proxy deployed at:", address(nftProxy));

        upgradeableNFT.transferOwnership(userB);
        console.log("NFT contract owner:", upgradeableNFT.owner());

        console.log("\n3. User B deploys UpgradeableNFTMarketplace...");
        UpgradeableNFTMarketplaceV2 marketplaceImplementation = new UpgradeableNFTMarketplaceV2();
        bytes memory marketplaceInitData = abi.encodeWithSelector(
            UpgradeableNFTMarketplaceV2.initialize.selector,
            address(upgradeableNFT),
            address(myToken)
        );
        ERC1967Proxy marketplaceProxy = new ERC1967Proxy(address(marketplaceImplementation), marketplaceInitData);
        upgradeableMarketplace = UpgradeableNFTMarketplaceV2(address(marketplaceProxy));
        console.log("Marketplace proxy deployed at:", address(marketplaceProxy));

        upgradeableMarketplace.transferOwnership(userB);
        console.log("Marketplace contract owner:", upgradeableMarketplace.owner());

        vm.stopBroadcast();
    }

    function _mintAndApprove(
        UpgradeableNFT upgradeableNFT,
        UpgradeableNFTMarketplaceV2 upgradeableMarketplace,
        address userC
    ) internal {
        console.log("\n4. User C mints NFT...");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_2"));
        upgradeableNFT.safeMint(userC, "https://example.com/nft/1");
        console.log("NFT minted to User C");
        console.log("NFT owner:", upgradeableNFT.ownerOf(0));
        vm.stopBroadcast();

        console.log("\n5. User C approves NFT to marketplace...");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_3"));
        upgradeableNFT.setApprovalForAll(address(upgradeableMarketplace), true);
        console.log("NFT approved for marketplace");
        console.log("Is approved for all:", upgradeableNFT.isApprovedForAll(userC, address(upgradeableMarketplace)));
        vm.stopBroadcast();
    }

    function _listNft(UpgradeableNFTMarketplaceV2 upgradeableMarketplace, address userC) internal {
        console.log("\n6. User C lists NFT...");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_3"));
        upgradeableMarketplace.listNFT(0, 100 ether);
        console.log("NFT listed for 100 tokens");

        (address seller, uint256 price, bool active) = upgradeableMarketplace.getListing(0);
        console.log("Listing seller:", seller);
        console.log("Listing price:", price);
        console.log("Listing active:", active);
        vm.stopBroadcast();

        userC;
    }

    function _buyNft(
        ERC1363Token myToken,
        UpgradeableNFT upgradeableNFT,
        UpgradeableNFTMarketplaceV2 upgradeableMarketplace,
        address userA,
        address userC
    ) internal {
        console.log("\n7. User A buys NFT...");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_1"));
        myToken.approve(address(upgradeableMarketplace), 100 ether);
        console.log("Token approved for marketplace");

        bytes memory data = abi.encode(0);
        IERC1363(address(myToken)).transferAndCall(address(upgradeableMarketplace), 100 ether, data);
        console.log("NFT purchased");

        console.log("New NFT owner:", upgradeableNFT.ownerOf(0));
        console.log("User A token balance:", myToken.balanceOf(userA));
        console.log("User C token balance:", myToken.balanceOf(userC));
        vm.stopBroadcast();

        console.log("\nScenario test completed successfully!");
    }
}
