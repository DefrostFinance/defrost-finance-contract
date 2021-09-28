// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
interface IDefrostFactory{
    function getVault(bytes32 vaultID)external view returns (address);
    function reservePool()external view returns (address);
    function systemCoin()external view returns (address);
    function dsOracle()external view returns (address);
    function systemCoinMinePool()external view returns (address); 
    function liquidationReward()external view returns (uint256);
    function liquidationPunish()external view returns (uint256); 
    function getAllVaults()external view returns (address payable[] memory);
}