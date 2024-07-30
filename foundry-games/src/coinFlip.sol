// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function
// fallback function
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CoinFlip
 */
contract CoinFlip is Ownable {
    ///////////////////////
    // Errors            //
    ///////////////////////
    error CoinFlip__InvalidBetAmount();
    error CoinFlip__InsufficientBalance();
    error CoinFlip__TransferFailed();

    ///////////////////////
    // State variables   //
    ///////////////////////
    mapping(address => uint256) public balances;

    ///////////////////////
    // Events            //
    ///////////////////////
    event BetPlaced(address indexed player, uint256 amount, bool choice);
    event GameResult(address indexed player, uint256 amount, bool won);

    ///////////////////////
    // Constructor       //
    ///////////////////////
    constructor() Ownable(msg.sender) {
    }

    ///////////////////////
    // External functions//
    ///////////////////////
    function placeBet(bool choice) external payable {
        if (msg.value == 0) {
            revert CoinFlip__InvalidBetAmount();
        }

        balances[msg.sender] += msg.value;
        emit BetPlaced(msg.sender, msg.value, choice);

        bool result = (block.timestamp % 2 == 0);
        if (result == choice) {
            balances[msg.sender] += msg.value;
            emit GameResult(msg.sender, msg.value, true);
        } else {
            balances[msg.sender] -= msg.value;
            emit GameResult(msg.sender, msg.value, false);
        }
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        if (amount == 0) {
            revert CoinFlip__InsufficientBalance();
        }
        
        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            balances[msg.sender] = amount;
            revert CoinFlip__TransferFailed();
        }
    }

    ///////////////////////////////
    // View and Pure functions   //
    ///////////////////////////////
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
}
