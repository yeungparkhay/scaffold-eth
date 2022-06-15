pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {
    using SafeMath for uint256;
    IERC20 token;

    constructor(address token_addr) {
        token = IERC20(token_addr);
    }

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX:init - already has liquidity");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens));
        return totalLiquidity;
    }

    function deposit() public payable returns (uint256) {
        // Receives ETH and transfers tokens from caller into the contract at right ratio
        uint256 eth_reserve = address(this).balance.sub(msg.value);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_deposit = msg.value;
        uint256 token_deposit = eth_deposit.mul(token_reserve) / eth_reserve;
        require(token.transferFrom(msg.sender, address(this), token_deposit));
        console.log("token_deposit:", token_deposit);

        uint256 liquidity_minted = eth_deposit.mul(totalLiquidity) /
            eth_reserve;
        console.log("liquidity_minted:", liquidity_minted);
        liquidity[msg.sender] = liquidity[msg.sender].add(liquidity_minted);
        totalLiquidity = totalLiquidity.add(liquidity_minted);

        return liquidity_minted;
    }

    function withdraw(uint256 amount_liquidity)
        public
        returns (uint256, uint256)
    {
        require(
            amount_liquidity <= liquidity[msg.sender],
            "Amount exceeds contributed liquidity"
        );

        uint256 eth_reserve = address(this).balance; // 11
        uint256 token_reserve = token.balanceOf(address(this)); // 9.09
        uint256 eth_amount = amount_liquidity.mul(eth_reserve) / totalLiquidity;
        uint256 token_amount = amount_liquidity.mul(token_reserve) /
            totalLiquidity;

        (bool success, ) = payable(msg.sender).call{value: eth_amount}("");
        require(success);
        require(token.transfer(msg.sender, token_amount));

        liquidity[msg.sender] = liquidity[msg.sender].sub(amount_liquidity);
        totalLiquidity = totalLiquidity.sub(amount_liquidity);

        return (eth_amount, token_amount);
    }

    function price(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public pure returns (uint256) {
        uint256 input_amount_with_fee = input_amount.mul(997);
        uint256 numerator = input_amount_with_fee.mul(output_reserve);
        uint256 denominator = input_reserve.mul(1000).add(
            input_amount_with_fee
        );
        return numerator / denominator;
    }

    function ethToToken() public payable returns (uint256) {
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_bought = price(
            msg.value,
            address(this).balance.sub(msg.value),
            token_reserve
        );
        require(token.transfer(msg.sender, tokens_bought));
        return tokens_bought;
    }

    function tokenToEth(uint256 tokens) public returns (uint256) {
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_bought = price(
            tokens,
            token_reserve,
            address(this).balance
        );
        (bool success, ) = payable(msg.sender).call{value: eth_bought}("");
        require(success);
        require(token.transferFrom(msg.sender, address(this), tokens));
        return eth_bought;
    }
}
