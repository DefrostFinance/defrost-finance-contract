// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface ICErc20{
    function exchangeRateStored() external view returns (uint);
    function underlying() external view returns (address);
}
interface ICEther{
    function exchangeRateStored() external view returns (uint);
}