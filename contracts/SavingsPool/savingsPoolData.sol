/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Options Protocol
 */
pragma solidity ^0.7.0;
import "../interface/ISystemCoin.sol";
import "../interestEngine/interestEngine.sol";
import "../modules/ReentrancyGuard.sol";
import "../modules/Halt.sol";
abstract contract savingsPoolData is Halt,interestEngine,ReentrancyGuard {
    uint256 constant internal currentVersion = 1;
    ISystemCoin public systemCoin;
    event Save(address indexed sender, address indexed account, uint256 amount);
    event Withdraw(address indexed sender, address indexed account, uint256 amount);
}