// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./Bank.sol";

contract Bigbank is Bank {
    /*
    // Constructor variant to set owner/admin to a specified address `init`.
    // Use this if you want the owner/admin to be a third-party contract/address
    // at deployment time: deploy Bigbank with `init = <ownable_or_admin_address>`.
    constructor(address init) Ownable(init) Bank(init) {
        require(init != address(0), "zero address");
    }
    */

    // Restored default constructor: Ownable and Bank use deployer as owner/admin.
    constructor() {}
    uint public constant MIN_DEPOSIT = 0.01 ether;

    modifier minDeposit() {
        require(msg.value >= MIN_DEPOSIT, "Deposit amount is less than minimum");
        _;
    }

    // accept direct ETH transfers and forward to deposit() so msg.sender/msg.value are preserved
    receive() external payable minDeposit {
        deposit();
    }

    fallback() external payable minDeposit {
        deposit();
    }

    /// @notice Withdraw `amount` wei from the BigBank to the admin address (Bank.admin).
    /// @dev Only callable by the `admin` (as used by `Bank`) and protected by `noReentrant`.
    function withdrawqukuan(uint256 amount) external onlyAdmin noReentrant {
        // forward to parent Bank.Withdraw which sends funds to `admin`
        super.withdraw(amount);
    }
}
