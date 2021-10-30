/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "../interface/ISystemCoin.sol";
import "../interestEngine/interestEngine.sol";
import "../modules/ReentrancyGuard.sol";
import "../modules/Halt.sol";
abstract contract savingsPoolData is Halt,interestEngine,ReentrancyGuard {
    uint256 constant internal currentVersion = 1;
    ISystemCoin public systemCoin;
    event InitContract(address indexed sender,address systemCoin,int256 interestRate,uint256 interestInterval,
        uint256 assetCeiling,uint256 assetFloor);
    event Save(address indexed sender, address indexed account, uint256 amount);
    event Withdraw(address indexed sender, address indexed account, uint256 amount);
}