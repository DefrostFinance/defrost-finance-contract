// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface IYak{
    function depositToken() external view returns (address);
    function getDepositTokensForShares(uint256 amount) external view returns (uint256);
}