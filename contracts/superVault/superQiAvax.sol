// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superQiToken.sol";

// This contract handles swapping to and from superQiAvax.
contract superQiAvax is superQiToken {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _dsOracle,address payable _FeePool)
            superQiToken(multiSignature,origin0,origin1,0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c,_dsOracle,_FeePool) {
        underlying = address(0);
    }
    function compound() external{
        latestCompoundTime = block.timestamp;
        uint nLen = rewardInfos.length;
        for (uint i=0;i<nLen;i++){
            claimReward(i);
        }
        uint256 balance = address(this).balance;
        if(balance > 0){
            uint256 fee = balance.mul(feeRate)/10000;
            FeePool.transfer(fee);
            ICEther(address(stakeToken)).mint{value:balance.sub(fee)}();
        }
    }
    function claimReward(uint index) internal {
        rewardInfo memory info = rewardInfos[index];
        if(info.bClosed){
            return;
        }
        address[] memory qiTokens = new address[](1); 
        qiTokens[0] = address(stakeToken);
        compounder.claimReward(info.rewardType,address(this),qiTokens);
        swapTraderJoe(info.rewardToken,info.sellLimit);
    }
    function swapTraderJoe(address token,uint256 sellLimit)internal{
        if(token == underlying){
            return;
        }
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < sellLimit){
            return;
        }
        address[] memory path = getSwapRouterPath(token);
        uint256 minOut = getSwapMinAmountOut(token,underlying,balance);
        IJoeRouter01(traderJoe).swapExactTokensForAVAX(balance,minOut,path,address(this),block.timestamp+30);
    }
}