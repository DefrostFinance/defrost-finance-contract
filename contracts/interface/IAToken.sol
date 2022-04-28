// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface IAToken{
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}