// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {Box} from "../src/Box.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {GovToken} from "../src/GovToken.sol";

contract MyGovernorTest is Test {
    MyGovernor governor;
    Box box;
    TimeLock timeLock;
    GovToken govToken;

    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    address[] proposers;
    address[] executors;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes

    function setUp() public {
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);

        // For MyGovernor.sol, we will need GovToken and TimeLock
        vm.startPrank(USER);
        govToken.delegate(USER); // now we have our governance token
        timeLock = new TimeLock(MIN_DELAY, proposers, executors); // deploy our timelock contract
        governor = new MyGovernor(govToken, timeLock); // deploy our governor contract

        // TimeLock has some default roles, and we need to grant Governor whole bunch of roles and remove ourself as the Admin of the timelock
        bytes32 proposerRole = timeLock.PROPOSER_ROLE(); // governor hash
        bytes32 executorRole = timeLock.EXECUTOR_ROLE(); // executor hash
        bytes32 adminRole = timeLock.TIMELOCK_ADMIN_ROLE(); // admin hash

        timeLock.grantRole(proposerRole, address(governor)); // only the governor can propose stuff to the timelock
        timeLock.grantRole(executorRole, address(0)); // anybody can execute the proposal
        timeLock.revokeRole(adminRole, USER); // remove ourself as the admin of the timelock
        vm.stopPrank();

        box = new Box();
        // Transfer Ownership of the Box to the Timelock
        // TimeLock is owned by the DAO
        box.transferOwnership(address(timeLock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }
}
