/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "../modules/SafeMath.sol";
import "./savingsPoolData.sol";
/**
 * @title systemCoin deposit pool.
 * @dev Deposit systemCoin earn interest systemcoin.
 *
 */
contract savingsPool is savingsPoolData {
    using SafeMath for uint256;
    /**
     * @dev default function for foundation input miner coins.
     */
    constructor (address multiSignature,address origin0,address origin1) proxyOwner(multiSignature,origin0,origin1) {
    }
    function initContract(address _systemCoin,int256 _interestRate,uint256 _interestInterval,
        uint256 _assetCeiling,uint256 _assetFloor)external originOnce{
        systemCoin = ISystemCoin(_systemCoin);
        assetCeiling = _assetCeiling;
        assetFloor = _assetFloor;
        _setInterestInfo(_interestRate,_interestInterval,12e26,rayDecimals);
        emit InitContract(msg.sender,_systemCoin,_interestRate,_interestInterval,_assetCeiling,_assetFloor);

    }
    receive()external payable{
        require(false);
    }
    function setPoolLimitation(uint256 _assetCeiling,uint256 _assetFloor)external onlyOrigin{
        assetCeiling = _assetCeiling;
        assetFloor = _assetFloor;
    }
    function setInterestInfo(int256 _interestRate,uint256 _interestInterval)external onlyOrigin{
        _setInterestInfo(_interestRate,_interestInterval,12e26,rayDecimals);
    }
    function saveSystemCoin(address account, uint256 amount) notHalted nonReentrant settleAccount(msg.sender) external{
        require(systemCoin.transferFrom(msg.sender, address(this), amount),"systemCoin : transferFrom failed!");
        addAsset(account,amount);
        emit Save(msg.sender,account,amount);
    }
    function withdrawSystemCoin(address account, uint256 amount) notHalted nonReentrant settleAccount(msg.sender) external{
        if(amount == uint256(-1)){
            amount = assetInfoMap[account].assetAndInterest;
        }
        subAsset(msg.sender,amount);
        require(systemCoin.transfer(account, amount),"systemCoin : transfer failed!");
        emit Withdraw(msg.sender,account,amount);
    }
}