// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface ISuperToken{
    function stakeToken() external view returns (address);
    function stakeBalance()external view returns (uint256);
}
