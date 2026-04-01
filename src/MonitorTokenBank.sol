// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MonitorTokenBank
 * @dev 基于TokenBank的监控银行，当用户存款超过50 token时，自动退还1/4
 * 支持Chainlink Automation进行自动处理
 */
contract MonitorTokenBank {
    address public admin;
    IERC20 public token;

    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public needsRefund;

    uint256 public constant THRESHOLD = 50 * 10 ** 18;
    uint256 public constant REFUND_RATIO = 4;

    event Deposit(address indexed depositor, uint256 amount);
    event Refund(address indexed depositor, uint256 amount);
    event Withdraw(address indexed admin, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor(address _token) {
        admin = msg.sender;
        token = IERC20(_token);
    }

    /**
     * @dev 用户存款函数，需要先approve
     * @param amount 存款金额
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than zero");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

        userDeposits[msg.sender] += amount;

        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        emit Deposit(msg.sender, amount);

        if (userDeposits[msg.sender] > THRESHOLD) {
            needsRefund[msg.sender] = true;
        }
    }

    /**
     * @dev Chainlink Automation检查函数：是否需要执行自动退款
     * 可以被Chainlink Keepers调用
     * @param checkData 检查数据
     * @return upkeepNeeded 是否需要执行
     * @return performData 执行数据
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        address user = abi.decode(checkData, (address));
        upkeepNeeded = needsRefund[user] && userDeposits[user] > THRESHOLD;
        performData = checkData;
    }

    /**
     * @dev Chainlink Automation执行函数：执行自动退款
     * 可以被Chainlink Keepers调用
     * @param performData 执行数据
     */
    function performUpkeep(bytes calldata performData) external {
        address user = abi.decode(performData, (address));
        if (needsRefund[user] && userDeposits[user] > THRESHOLD) {
            uint256 refundAmount = userDeposits[user] / REFUND_RATIO;

            needsRefund[user] = false;
            userDeposits[user] -= refundAmount;

            bool success = token.transfer(user, refundAmount);
            require(success, "Refund transfer failed");

            emit Refund(user, refundAmount);
        }
    }

    /**
     * @dev 处理退款，退还用户存款的1/4
     * @param user 需要退款的用户地址
     */
    function processRefund(address user) external {
        require(needsRefund[user], "No refund needed");
        require(userDeposits[user] > THRESHOLD, "Deposit below threshold");

        uint256 refundAmount = userDeposits[user] / REFUND_RATIO;

        needsRefund[user] = false;
        userDeposits[user] -= refundAmount;

        bool success = token.transfer(user, refundAmount);
        require(success, "Refund transfer failed");

        emit Refund(user, refundAmount);
    }

    /**
     * @dev 管理员取款
     * @param amount 取款金额
     */
    function withdraw(uint256 amount) external onlyAdmin {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance in the bank");

        bool success = token.transfer(admin, amount);
        require(success, "Token transfer failed");

        emit Withdraw(admin, amount);
    }

    /**
     * @dev 获取用户存款
     * @param user 用户地址
     * @return 存款金额
     */
    function getUserDeposit(address user) public view returns (uint256) {
        return userDeposits[user];
    }

    /**
     * @dev 获取银行总存款
     * @return 总存款金额
     */
    function getTotalDeposit() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev 检查用户是否需要退款
     * @param user 用户地址
     * @return 是否需要退款
     */
    function checkNeedsRefund(address user) public view returns (bool) {
        return needsRefund[user] && userDeposits[user] > THRESHOLD;
    }
}
