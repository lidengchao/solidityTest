// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyERC721
 * @dev 一个标准的ERC721 NFT合约，继承自OpenZeppelin的ERC721、ERC721URIStorage和Ownable
 * 支持NFT的铸造、元数据URI存储和所有者权限管理
 */
contract MyERC721 is ERC721, ERC721URIStorage, Ownable {
    // 下一个要铸造的NFT的tokenId，从0开始递增
    uint256 private _nextTokenId;

    /**
     * @dev 构造函数，初始化ERC721 NFT合约
     * @param name_ NFT集合的名称
     * @param symbol_ NFT集合的符号
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {}

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
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev 检查合约是否支持指定的接口
     * @param interfaceId 接口ID
     * @return 是否支持该接口
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
