/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Options Protocol
 */

pragma solidity ^0.7.0;
import "./Coin.sol";
import "../interface/ICoinMinePool.sol";

contract mineCoin is Coin {
        constructor(
        string memory name_,
        string memory symbol_,
        uint256 chainId_
      )  Coin(name_,symbol_,chainId_) {

      }
    ICoinMinePool public minePool;
    function setMinePool(address _minePool) external isAuthorized{
        minePool = ICoinMinePool(_minePool);
    }
        /*
        /**
     * @dev Move user's PPT to 'recipient' balance, a interface in ERC20. 
     * @param recipient recipient's account.
     * @param amount amount of PPT.
     */ 
     /*
    function transfer(address recipient, uint256 amount)public override returns (bool){
        if (address(minePool) != address(0)){
            minePool.transferMinerCoin(msg.sender,recipient);
        }
        bool success = super.transfer(recipient,amount);
        if (!success){
            return false;
        }

        return true;
    }
    */
    /*
        /**
     * @dev Move sender's PPT to 'recipient' balance, a interface in ERC20. 
     * @param sender sender's account.
     * @param recipient recipient's account.
     * @param amount amount of PPT.
     */ 
     /*
    function transferFrom(address sender, address recipient, uint256 amount)public override returns (bool){
        if (address(minePool) != address(0)){
            minePool.transferMinerCoin(sender,recipient);
        }
        bool success = super.transferFrom(sender,recipient,amount);
        if (!success){
            return false;
        }
        return true;            
    }
    */
        /**
     * @dev burn user's PPT when user redeem PPTCoin. 
     * @param account user's account.
     * @param amount amount of PPT.
     */ 
    function burn(address account, uint256 amount) public override {
        require(int256(amount) >= 0, "systemCoin : burn overflow");
        if (address(minePool) != address(0)){
            minePool.changeUserbalance(account,-int256(amount));
        }
        super.burn(account,amount);
    }
    /**
     * @dev mint user's PPT when user add collateral. 
     * @param account user's account.
     * @param amount amount of PPT.
     */ 
    function mint(address account, uint256 amount) public override {
        require(int256(amount) >= 0, "systemCoin : mint overflow");
        if (address(minePool) != address(0)){
            minePool.changeUserbalance(account,int256(amount));
        }
        super.mint(account,amount);
    }
}