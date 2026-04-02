// 前端签名示例代码
// 使用ethers.js库进行签名

const { ethers } = require('ethers');

// 连接到钱包
const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();

// NFT市场合约地址
const marketplaceAddress = '0xYourMarketplaceAddress';

// 要上架的NFT信息
const tokenId = 1;
const price = ethers.utils.parseEther('10'); // 10个代币

// 构建签名消息
async function signListing(tokenId, price) {
    // 构建消息哈希
    const messageHash = ethers.utils.solidityKeccak256(
        ['uint256', 'uint256', 'address'],
        [tokenId, price, marketplaceAddress]
    );
    
    // 签名
    const signature = await signer.signMessage(ethers.utils.arrayify(messageHash));
    
    // 解析签名
    const { r, s, v } = ethers.utils.splitSignature(signature);
    
    return { r, s, v };
}

// 调用listNFTWithSignature函数
async function listNFTWithSignature(tokenId, price) {
    // 首先确保用户已经授权NFT给市场合约
    const nftContract = new ethers.Contract(
        '0xYourNFTContractAddress',
        [
            'function setApprovalForAll(address operator, bool approved) external'
        ],
        signer
    );
    
    // 一次性授权所有NFT给市场合约
    await nftContract.setApprovalForAll(marketplaceAddress, true);
    console.log('NFT approved for all');
    
    // 签名上架信息
    const { r, s, v } = await signListing(tokenId, price);
    
    // 调用市场合约的listNFTWithSignature函数
    const marketplaceContract = new ethers.Contract(
        marketplaceAddress,
        [
            'function listNFTWithSignature(uint256 tokenId, uint256 price, uint8 v, bytes32 r, bytes32 s) external'
        ],
        signer
    );
    
    const tx = await marketplaceContract.listNFTWithSignature(tokenId, price, v, r, s);
    await tx.wait();
    console.log('NFT listed with signature');
}

// 示例调用
listNFTWithSignature(tokenId, price)
    .then(() => console.log('Listing completed'))
    .catch(error => console.error('Error:', error));
