// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Bank {
    address public admin;
    mapping(address => uint256) public deposits;
    address[3] public topdepositors;
    uint256[3] public topAmounts;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(uint256 amount);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    // simple reentrancy guard
    bool private locked;
    modifier noReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
   
    function adminTransfer(address newAdmin) external onlyAdmin {
       require(newAdmin != address(0), "New admin cannot be the zero address");
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }
    
    /*
    /// NOTE: the following constructor signature was added to allow specifying
    /// an explicit initial admin (for example to align with a third-party
    /// Ownable contract). It's retained here as commented code so you can
    /// re-enable it if you want to deploy `Bank` with a non-deployer admin.

    /// @param initialAdmin the address to set as the initial admin
    constructor(address initialAdmin) {
        require(initialAdmin != address(0), "initial admin is zero");
        admin = initialAdmin;
    }
    */

    // Restored default constructor: admin is the deployer (original behavior).
    constructor() {
        admin = msg.sender;
    }

    //存款
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        deposits[msg.sender] += msg.value;
        //更新前三名
        updateTopDepositors(msg.sender, deposits[msg.sender]);
         emit Deposit(msg.sender, msg.value);

    }
    //对前三名进行排序
    function updateTopDepositors(address user, uint256 amount) internal {
        //是否进前三
        if(amount>topAmounts[2]){
            //第一名
            if(amount>topAmounts[0]){
                //把第二名挪到第三名
                topdepositors[2] = topdepositors[1];
                topAmounts[2] = topAmounts[1];
                //第一名挪到第二名
                topdepositors[1] = topdepositors[0];
                topAmounts[1] = topAmounts[0];
                //重新赋值第一名
                topdepositors[0] = user;
                topAmounts[0] = amount;
            //第二名
            } else if(amount>topAmounts[1]){
                //把第二名挪到第三名
                topdepositors[2] = topdepositors[1];
                topAmounts[2] = topAmounts[1];
                //重新赋值第二名
                topdepositors[1] = user;
                topAmounts[1] = amount;
        
           }else {
                 //重新赋值第三名
                 topdepositors[2] = user;
                 topAmounts[2] = amount;
                }
        }
       
    }

    //取款
    function withdraw(uint256 amount) external onlyAdmin noReentrant {
        require(amount > 0, "Withdrawal amount must be greater than zero");

        uint256 balance = address(this).balance;
        require(balance >= amount, "Insufficient balance in the bank");

        (bool success, ) = payable(admin).call{value: amount}(""); //转账
        require(success, "Transfer failed");

        emit Withdrawal(amount);
    }

        function getDeposit(address user) public view returns (uint256) {
        return deposits[user];
    }

    function getTotalDeposit() public view returns (uint256) {
        return address(this).balance;
    }

    function getTopDepositors() public view returns (address[3] memory, uint256[3] memory) {
        return (topdepositors, topAmounts);
    }
}
