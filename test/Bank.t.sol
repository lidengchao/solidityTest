// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address alice = address(0x1);
    address bob = address(0x2);

    // allow this test contract to receive ether from Bank.Withdraw
    receive() external payable {}

    function setUp() public {
        bank = new Bank();
        vm.deal(alice, 3 ether);
        vm.deal(bob, 3 ether);
    }

    function testDepositAndTop() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();
        assertEq(bank.getDeposit(alice), 1 ether);

        vm.prank(bob);
        bank.deposit{value: 2 ether}();
        assertEq(bank.getDeposit(bob), 2 ether);

        (address[3] memory tops, uint256[3] memory amounts) = bank.getTopDepositors();
        assertEq(tops[0], bob);
        assertEq(amounts[0], 2 ether);
        assertEq(tops[1], alice);
        assertEq(amounts[1], 1 ether);
    }

    function testWithdrawByAdmin() public {
        // this test contract is the admin (deployer of Bank)
        bank.deposit{value: 1 ether}();
        assertEq(bank.getTotalDeposit(), 1 ether);

        bank.Withdraw(1 ether);
        assertEq(bank.getTotalDeposit(), 0);
    }
}
