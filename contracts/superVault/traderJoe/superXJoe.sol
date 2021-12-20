// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superJoeFarm.sol";
import "../../interface/IJoeBar.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superXJoe is superJoeFarm {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IJoeBar public xJoe = IJoeBar(0x57319d41F71E81F3c65F2a47CA4e001EbAFd4F33);
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool)
            superJoeFarm(multiSignature,origin0,origin1,_stakeToken,_dsOracle,_FeePool,24) {

        string memory tokenName_ = string(abi.encodePacked("Super ",IERC20(_stakeToken).name()));
        string memory symble_ = string(abi.encodePacked("S",IERC20(_stakeToken).symbol()));
        setErc20Info(tokenName_,symble_,IERC20(_stakeToken).decimals());
        IERC20(joeToken).safeApprove(address(xJoe),uint256(-1));
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
}