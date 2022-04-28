// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface IAAVEPool{
    function supply(address asset,uint256 amount,address onBehalfOf,uint16 referralCode) external; 
}