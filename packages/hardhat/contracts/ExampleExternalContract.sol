// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract ExampleExternalContract {
    bool public completed;

    function complete() public payable {
        completed = true;
    }

    function getStatus() public view returns (bool) {
        return completed;
    }
}
