// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
import "../modules/proxyOwner.sol";
import "../interface/ISystemCoin.sol";
import "../interface/IDefrostFactory.sol";

abstract contract defrostHelperData is proxyOwner {
    ISystemCoin public systemCoin;
    IDefrostFactory public defrostFactory;
}