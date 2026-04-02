// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MultiSigWallet {
    // 定义变量
    address[] public owners;
    mapping (address => uint) isOwner;
    uint256 public required;
    Transaction[] public transactions;
    mapping (uint => mapping(address => bool)) public isConfirmed; // 记录交易的确认状态

    // 定义事件
    event Deposit(address indexed sender, uint256 amount); // 存款事件
    event Submit(uint256 indexed txId); // 提交交易事件
    event Confirm(address indexed owner, uint256 indexed txId); // 确认交易事件
    event Revoke(address indexed owner, uint256 indexed txId); // 撤销确认事件
    event Execute(uint256 indexed txId); // 执行交易事件

    // 交易结构体
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    // 修饰符：仅多签持有人
    modifier onlyOwner() {
        require(isOwner[msg.sender] > 0, "Not owner");
        _;
    }

    // 修饰符：交易必须存在
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Transaction does not exist");
        _;
    }

    // 修饰符：交易未执行
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }

    // 修饰符：交易未确认
    modifier notConfirmed(uint256 _txId) {
        require(!isConfirmed[_txId][msg.sender], "Transaction already confirmed");
        _;
    }

    // 构造函数
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required number of confirmations");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(isOwner[owner] == 0, "Owner not unique");

            isOwner[owner] = 1;
            owners.push(owner);
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev 提交交易提案
     * @param _to 目标地址
     * @param _value 转账金额
     * @param _data 调用数据
     */
    function submit(address _to, uint256 _value, bytes memory _data) external onlyOwner {
        uint256 txId = transactions.length;

        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0
        }));

        emit Submit(txId);
    }

    /**
     * @dev 确认交易
     * @param _txId 交易ID
     */
    function confirm(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notConfirmed(_txId) {
        Transaction storage transaction = transactions[_txId];
        transaction.confirmations += 1;
        isConfirmed[_txId][msg.sender] = true;

        emit Confirm(msg.sender, _txId);
    }

    /**
     * @dev 撤销确认
     * @param _txId 交易ID
     */
    function revoke(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(isConfirmed[_txId][msg.sender], "Transaction not confirmed");

        Transaction storage transaction = transactions[_txId];
        transaction.confirmations -= 1;
        isConfirmed[_txId][msg.sender] = false;

        emit Revoke(msg.sender, _txId);
    }

    /**
     * @dev 执行交易
     * @param _txId 交易ID
     */
    function execute(uint256 _txId) external txExists(_txId) notExecuted(_txId) {
        Transaction storage transaction = transactions[_txId];
        require(transaction.confirmations >= required, "Not enough confirmations");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");

        emit Execute(_txId);
    }

    /**
     * @dev 获取多签持有人列表
     * @return 多签持有人列表
     */
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /**
     * @dev 获取交易数量
     * @return 交易数量
     */
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    /**
     * @dev 获取交易详情
     * @param _txId 交易ID
     * @return to 目标地址
     * @return value 转账金额
     * @return data 调用数据
     * @return executed 是否已执行
     * @return confirmations 确认数量
     */
    function getTransaction(uint256 _txId) external view returns (address to, uint256 value, bytes memory data, bool executed, uint256 confirmations) {
        Transaction storage transaction = transactions[_txId];
        return (transaction.to, transaction.value, transaction.data, transaction.executed, transaction.confirmations);
    }

}

