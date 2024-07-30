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
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
// import SaveMath

contract CrashGame is Ownable {
    using SafeMath for uint256;

    ///////////////////////
    // Errors            //
    ///////////////////////
    error CrashGame__InvalidBetAmount();
    error CrashGame__InsufficientBalance();
    error CrashGame__CashoutFailed();

    ///////////////////////
    // Type declarations //
    ///////////////////////
    struct Player {
        uint256 betAmount;
        uint256 walletBalance;
        bool hasBet;
    }

    ///////////////////////
    // State variables   //
    ///////////////////////
    mapping(address => Player) public players;
    uint256 public crashPoint;
    uint256 public gameStartTime;
    uint256 private constant MAX_BET = 1000000;
    uint256 private constant MIN_BET = 1;

    ///////////////////////
    // Events            //
    ///////////////////////
    event BetPlaced(address indexed player, uint256 amount);
    event GameStateUpdated(uint256 crashPoint, uint256 currentMultiplier);
    event CashoutSuccess(address indexed player, uint256 payout, uint256 multiplier);
    event GameStarted();
    event GameResult(uint256 crashPoint);

    ///////////////////////
    // Constructor       //
    ///////////////////////
    constructor() Ownable(msg.sender) {
    }

    ///////////////////////
    // External functions//
    ///////////////////////
    function placeBet(uint256 bet) external {
        if (bet < MIN_BET || bet > MAX_BET) {
            revert CrashGame__InvalidBetAmount();
        }
        Player storage player = players[msg.sender];
        if (player.walletBalance < bet) {
            revert CrashGame__InsufficientBalance();
        }

        player.betAmount = bet;
        player.walletBalance = player.walletBalance.sub(bet);
        player.hasBet = true;

        emit BetPlaced(msg.sender, bet);
    }

    function cashout() external {
        Player storage player = players[msg.sender];
        if (!player.hasBet) {
            revert CrashGame__CashoutFailed();
        }

        uint256 multiplier = calculateMultiplier();
        if (multiplier < crashPoint) {
            uint256 payout = player.betAmount.mul(multiplier);
            player.walletBalance = player.walletBalance.add(payout);
            player.hasBet = false;

            emit CashoutSuccess(msg.sender, payout, multiplier);
        }
    }

    ///////////////////////
    // Public functions  //
    ///////////////////////
    function startGame() public onlyOwner {
        crashPoint = calculateCrashPoint();
        gameStartTime = block.timestamp;

        emit GameStarted();

        // This simulates the game logic running on a server, but we use a simple loop for demonstration
        while (true) {
            uint256 currentMultiplier = calculateMultiplier();
            if (currentMultiplier >= crashPoint) {
                emit GameResult(crashPoint);
                resetGame();
                break;
            }
            emit GameStateUpdated(crashPoint, currentMultiplier);
        }
    }

    ///////////////////////////////
    // View and Pure functions   //
    ///////////////////////////////
    function getBalance() external view returns (uint256) {
        return players[msg.sender].walletBalance;
    }

    ///////////////////////
    // Internal functions//
    ///////////////////////
    function calculateMultiplier() internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp.sub(gameStartTime);
        return SafeMath.min(exp(timeElapsed.mul(60).div(1000)), crashPoint);
    }

    function calculateCrashPoint() internal view returns (uint256) {
        uint256 e = 2 ** 32;
        uint256 h = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % e;
        return SafeMath.div(SafeMath.mul(100 * e, e - h), e - h) / 100;
    }

    function resetGame() internal {
        for (address playerAddr : players) {
            players[playerAddr].hasBet = false;
            players[playerAddr].betAmount = 0;
        }
        crashPoint = 1.0;
    }

    function exp(uint256 x) internal pure returns (uint256) {
        return 271828 * x;
    }
}
