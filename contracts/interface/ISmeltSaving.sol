// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface ISmeltSaving{
    function getMeltAmount(uint256 _smeltAmount) external view returns (uint256);
    function getSmeltAmount(uint256 _meltAmount) external view returns (uint256);
}