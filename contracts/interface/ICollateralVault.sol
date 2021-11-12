// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface ICollateralVault {
    function getOracleAddress() external view returns (address);
    function collateralToken() external view returns (address);
}
