// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superTokenV2.sol";
import "../interface/IJoeBar.sol";
import "../superVault/traderJoe/IMasterChefJoeV2.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superXJoeV2 is superTokenV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IMasterChefJoeV2 public constant masterChefJoe = IMasterChefJoeV2(0xd6a4F121CA35509aF06A0Be99093d08462f53052);
    uint256 public poolId;
    address public constant joeToken = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;

    IJoeBar public xJoe = IJoeBar(0x57319d41F71E81F3c65F2a47CA4e001EbAFd4F33);
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool)
            superTokenV2(multiSignature,origin0,origin1,_stakeToken,_dsOracle,_FeePool) {
        poolId = 24;

        IERC20(joeToken).safeApprove(address(xJoe),uint256(-1));
    }
    function deposit(address account,uint256 _amount)internal override {
                // Lock the stakeToken in the contract
        stakeToken.safeTransferFrom(account, address(this), _amount);
        masterChefJoe.deposit(poolId,_amount);
    }
    function withdraw(address account,uint256 _amount)internal override {
        masterChefJoe.withdraw(poolId,_amount);
        stakeToken.safeTransfer(account, _amount);
    }
    function stakeBalance()public override view returns (uint256){
        (uint amount,) = masterChefJoe.userInfo(poolId,address(this));
        return amount;
    }
    function compound() external{
        latestCompoundTime = block.timestamp;
        masterChefJoe.deposit(poolId,0);
        uint nLen = rewardInfos.length;
        for (uint i=0;i<nLen;i++){
            rewardInfo memory info = rewardInfos[i];
            if(info.bClosed){
                continue;
            }
            swapJoe(info.rewardToken,info.sellLimit);
        }
        uint256 balance = IERC20(joeToken).balanceOf(address(this));
        if (balance > 0){
            uint256 fee = balance.mul(feeRate)/10000;
            IERC20(joeToken).safeTransfer(FeePool,fee);
            balance = balance.sub(fee);
            xJoe.enter(balance);
            balance = IERC20(stakeToken).balanceOf(address(this));
            masterChefJoe.deposit(poolId,balance);
        }
    }
    function swapJoe(address token,uint256 sellLimit)internal{
        uint256 balance = (token != address(0)) ? IERC20(token).balanceOf(address(this)) : address(this).balance;
        if (balance < sellLimit){
            return;
        }
        swapTraderJoe(token,joeToken,balance);
//        swapTraderJoe(token,LPToken1,balance/2);
    }
    function getStakeTokenPrice() public override view returns (uint256) {
        uint256 totalSuply = stakeToken.totalSupply();
        uint256 balance = IERC20(joeToken).balanceOf(address(stakeToken));
        //1 xjoe = balance(joe)/totalSuply joe
        (,uint256 price) = oraclePrice(joeToken);
        return price.mul(balance)/totalSuply;
    }
}