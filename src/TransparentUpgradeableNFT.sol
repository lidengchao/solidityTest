// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title TransparentUpgradeableNFT
 * @dev 可升级的ERC721 NFT合约，使用透明代理模式
 * 支持NFT的铸造、元数据URI存储和所有者权限管理
 */
contract TransparentUpgradeableNFT is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    // 下一个要铸造的NFT的tokenId，从0开始递增
    uint256 private _nextTokenId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev 初始化函数，替代constructor
     * @param name_ NFT集合的名称
     * @param symbol_ NFT集合的符号
     */
    function initialize(
        string memory name_,
        string memory symbol_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __ERC721URIStorage_init();
        __Ownable_init(_msgSender());

        _nextTokenId = 0;
    }

    /**
     * @dev 安全铸造一个新的NFT，只有合约所有者可以调用
     * @param to 接收NFT的地址
     * @param uri NFT的元数据URI（通常指向IPFS或其他存储）
     */
    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev 获取指定tokenId的NFT元数据URI
     * @param tokenId NFT的tokenId
     * @return NFT的元数据URI字符串
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev 检查合约是否支持指定的接口
     * @param interfaceId 接口ID
     * @return 是否支持该接口
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
