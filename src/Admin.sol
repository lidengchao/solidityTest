// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Ibank {
    function Withdraw(uint256 amount) external;
}

contract Admin {
    address public owner;
    address public ibank;
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function setIbankAddress(address _Ibank) external onlyOwner {
        ibank = _Ibank;
    }

    function withdrawFromBigBank(uint256 amount) external onlyOwner {
        require(address(ibank) != address(0), "BigBank not set");
        Ibank(ibank).Withdraw(amount);
    }

    receive() external payable {}

}