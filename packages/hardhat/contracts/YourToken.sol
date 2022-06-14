// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// learn more: https://docs.openzeppelin.com/contracts/3.x/erc20

contract YourToken is ERC20 {
    address public deployer;

    constructor() public ERC20("YourToken", "YT") {
        deployer = msg.sender;
        _mint(msg.sender, 1000 * 10**18);
    }
}
