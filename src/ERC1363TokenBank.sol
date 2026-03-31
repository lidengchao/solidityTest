// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC1363.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";

contract ERC1363TokenBank is IERC1363Receiver {
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

    function onTransferReceived(
        address,
        address from,
        uint256 value,
        bytes calldata
    ) external returns (bytes4) {
        require(msg.sender == address(token), "Only token can call this function");
        require(value > 0, "Deposit amount must be greater than zero");

        userDeposits[from] += value;

        emit Deposit(from, value);

        return this.onTransferReceived.selector;
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
