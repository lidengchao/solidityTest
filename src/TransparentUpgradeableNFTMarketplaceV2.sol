// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title TransparentUpgradeableNFTMarketplaceV2
 * @dev 可升级的NFT市场合约第二版本，使用透明代理模式
 * 新增功能：
 * 1. 支持离线签名上架NFT
 * 2. 用户只需一次setApproveAll给市场合约，后续可使用签名上架
 */
contract TransparentUpgradeableNFTMarketplaceV2 is Initializable, IERC1363Receiver, OwnableUpgradeable {
    using MessageHashUtils for bytes32;

    // NFT上架信息
    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    // NFT合约地址
    IERC721 public nftContract;
    // ERC1363Token合约地址
    IERC20 public tokenContract;

    // tokenId => Listing
    mapping(uint256 => Listing) public listings;

    // 重入攻击防护：使用简单的布尔锁（Gas优化）
    bool private locked;

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId, address indexed seller);

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev 初始化函数，替代constructor
     * @param _nftContract NFT合约地址
     * @param _tokenContract ERC1363Token合约地址
     */
    function initialize(address _nftContract, address _tokenContract) public initializer {
        __Ownable_init(_msgSender());

        nftContract = IERC721(_nftContract);
        tokenContract = IERC20(_tokenContract);
        locked = false;
    }

    /**
     * @dev 上架NFT，卖家必须先授权市场合约
     * @param tokenId NFT的tokenId
     * @param price NFT的售价（以token为单位）
     */
    function listNFT(uint256 tokenId, uint256 price) external nonReentrant {
        require(price > 0, "Price must be greater than zero");
        require(nftContract.ownerOf(tokenId) == msg.sender, "Not the owner of the NFT");
        require(nftContract.getApproved(tokenId) == address(this) || nftContract.isApprovedForAll(msg.sender, address(this)), "NFT not approved");

        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            active: true
        });

        emit NFTListed(tokenId, msg.sender, price);
    }

    /**
     * @dev 新增：使用离线签名上架NFT
     * @param tokenId NFT的tokenId
     * @param price NFT的售价（以token为单位）
     * @param v ECDSA签名的v值
     * @param r ECDSA签名的r值
     * @param s ECDSA签名的s值
     */
    function listNFTWithSignature(uint256 tokenId, uint256 price, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        require(price > 0, "Price must be greater than zero");
        
        // 构建签名消息
        bytes32 messageHash = keccak256(abi.encodePacked(tokenId, price, address(this)));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        // 恢复签名者地址
        address seller = ECDSA.recover(ethSignedMessageHash, v, r, s);
        
        // 验证签名者是NFT的所有者
        require(nftContract.ownerOf(tokenId) == seller, "Signature invalid or not the owner");
        
        // 验证NFT已授权给市场合约
        require(nftContract.isApprovedForAll(seller, address(this)), "NFT not approved for all");

        listings[tokenId] = Listing({
            seller: seller,
            price: price,
            active: true
        });

        emit NFTListed(tokenId, seller, price);
    }

    /**
     * @dev 取消上架NFT
     * @param tokenId NFT的tokenId
     */
    function unlistNFT(uint256 tokenId) external nonReentrant {
        Listing storage listing = listings[tokenId];
        require(listing.active, "NFT not listed");
        require(listing.seller == msg.sender, "Not the seller");

        listing.active = false;

        emit NFTUnlisted(tokenId, msg.sender);
    }

    /**
     * @dev ERC1363回调函数，当使用transferAndCall时触发
     * 在此函数中完成NFT购买逻辑
     * Gas优化：先检查条件，再执行状态变更，最后执行外部调用（Checks-Effects-Interactions模式）
     */
    function onTransferReceived(
        address,
        address from,
        uint256 value,
        bytes calldata data
    ) external nonReentrant returns (bytes4) {
        require(msg.sender == address(tokenContract), "Only token can call this function");

        // 解析data获取tokenId
        uint256 tokenId = abi.decode(data, (uint256));

        // Checks：验证条件
        Listing storage listing = listings[tokenId];
        require(listing.active, "NFT not listed");
        require(value == listing.price, "Incorrect payment amount");
        require(from != listing.seller, "Seller cannot buy their own NFT");

        // Effects：先更新状态（防止重入）
        listing.active = false;

        // Interactions：执行外部调用
        // 1. 转账token给卖家
        bool tokenSuccess = tokenContract.transfer(listing.seller, value);
        require(tokenSuccess, "Token transfer failed");

        // 2. 转账NFT给买家
        nftContract.safeTransferFrom(listing.seller, from, tokenId);

        emit NFTSold(tokenId, listing.seller, from, value);

        return this.onTransferReceived.selector;
    }

    /**
     * @dev 传统购买方式（不使用ERC1363），作为备用选项
     * @param tokenId NFT的tokenId
     */
    function buyNFT(uint256 tokenId) external nonReentrant {
        Listing storage listing = listings[tokenId];
        require(listing.active, "NFT not listed");
        require(msg.sender != listing.seller, "Seller cannot buy their own NFT");

        // Checks-Effects-Interactions模式
        listing.active = false;

        // 转账token给卖家
        bool tokenSuccess = tokenContract.transferFrom(msg.sender, listing.seller, listing.price);
        require(tokenSuccess, "Token transfer failed");

        // 转账NFT给买家
        nftContract.safeTransferFrom(listing.seller, msg.sender, tokenId);

        emit NFTSold(tokenId, listing.seller, msg.sender, listing.price);
    }

    /**
     * @dev 获取NFT的上架信息
     * @param tokenId NFT的tokenId
     * @return seller 卖家地址
     * @return price 售价
     * @return active 是否在售
     */
    function getListing(uint256 tokenId) external view returns (address seller, uint256 price, bool active) {
        Listing storage listing = listings[tokenId];
        return (listing.seller, listing.price, listing.active);
    }
}
