// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
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

    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes
    uint256 public constant VOTING_DELAY = 1; // how many blocks till a vote is active
    uint256 public constant VOTING_PERIOD = 50400; // this is how long voting lasts

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

    function testGovernanceUpdatesBox() public {
        // shows the exact process from code standpoint of how DAOs work

        // we are going to propose that box updates the store value to 888 --> cross check with Governor.sol in MyGovernor.sol
        uint256 valueToStore = 888;
        string memory description = "store 1 in Box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);

        values.push(0); // we are not sending any value to the box contract
        calldatas.push(encodedFunctionCall); // we are pushing the encoded function call to the box contract
        targets.push(address(box)); // we are pushing the address of the box contract

        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // View the state of the proposal
        console.log("Proposal State: ", uint256(governor.state(proposalId))); // should return Pending

        // Update our Blockchain to pass that
        vm.warp(block.timestamp + VOTING_DELAY + 1); // we are going to warp the blockchain to the future by 1 block
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("Proposal State: ", uint256(governor.state(proposalId))); // should return Active

        // 2. Vote on the proposal
        string memory reason = "because I just want to vote!";
        uint8 voteWay = 1; // 0 = Against, 1 = For, 2 = Abstain
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1); // after voting period has passed
        vm.roll(block.number + VOTING_PERIOD + 1);

        // 3. Queue the TX
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1); // after queuing to wait for a minimum delay first
        vm.roll(block.number + MIN_DELAY + 1);

        // 4. Execute the TX
        governor.execute(targets, values, calldatas, descriptionHash);

        assert(box.getNumber() == valueToStore);
        console.log("Box Value: ", box.getNumber());
    }
}
