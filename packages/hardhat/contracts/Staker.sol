// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./ExampleExternalContract.sol";
import "hardhat/console.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 30 seconds;
    bool public openForWithdrawal = false;

    event Stake(address indexed sender, uint256 amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    function stake() public payable {
        require(timeLeft() > 0, "Past deadline");
        require(msg.value > 0, "Amount must be non-zero");

        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }

    modifier notCompleted() {
        bool completed = exampleExternalContract.getStatus();
        require(!completed, "Already completed");
        _;
    }

    function execute() public notCompleted {
        require(timeLeft() == 0, "Deadline not yet reached");
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdrawal = true;
        }
    }

    function withdraw() public notCompleted {
        uint256 balance = balances[msg.sender];
        require(openForWithdrawal, "Deadline not yet reached");
        require(balance > 0, "No funds to withdraw");
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to withdraw funds");
        balances[msg.sender] = 0;
    }
}
