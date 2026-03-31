// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenBank {
    address public admin;
    IERC20 public token;

    mapping(address => uint256) public userDeposits;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdraw(address indexed admin, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor(address _token) {
        admin = msg.sender;
        token = IERC20(_token);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than zero");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

        userDeposits[msg.sender] += amount;

        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyAdmin {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance in the bank");

        bool success = token.transfer(admin, amount);
        require(success, "Token transfer failed");

        emit Withdraw(admin, amount);
    }

    function getUserDeposit(address user) public view returns (uint256) {
        return userDeposits[user];
    }

    function getTotalDeposit() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
