// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superQiToken.sol";
//
// This contract handles swapping to and from superQiErc20
contract superQiErc20 is superQiToken {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _qiToken,address _dsOracle,address payable _FeePool)
            superQiToken(multiSignature,origin0,origin1,_qiToken,_dsOracle,_FeePool) {
        underlying = ICErc20(_qiToken).underlying();
        SafeERC20.safeApprove(IERC20(underlying), _qiToken, uint(-1));

        address QI = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5;
        swapRoutingPath[QI][underlying] = new address[](3);
        swapRoutingPath[QI][underlying][0] = QI;
        swapRoutingPath[QI][underlying][1] = WAVAX;
        swapRoutingPath[QI][underlying][2] = underlying;
    }
    function compound() external{
        latestCompoundTime = block.timestamp;
        uint nLen = rewardInfos.length;
        for (uint i=0;i<nLen;i++){
            claimReward(i);
        }
        IERC20 oToken = IERC20(underlying);
        uint256 balance = oToken.balanceOf(address(this));
        if (balance>0){
            uint256 fee = balance.mul(feeRate)/10000;
            oToken.safeTransfer(FeePool,fee);
            ICErc20(address(stakeToken)).mint(balance.sub(fee));
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
        if (token != address(0)){
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance < sellLimit){
                return;
            }
            address[] memory path = getSwapRouterPath(token);
            uint256 minOut = getSwapMinAmountOut(token,underlying,balance);
            IJoeRouter01(traderJoe).swapExactTokensForTokens(balance,minOut,path,address(this),block.timestamp+30);
        }else{
            uint256 balance = address(this).balance;
            if (balance < sellLimit){
                return;
            }
            address[] memory path = getSwapRouterPath(token);
            uint256 minOut = getSwapMinAmountOut(token,underlying,balance);
            IJoeRouter01(traderJoe).swapExactAVAXForTokens{value : balance}(minOut,path,address(this),block.timestamp+30);
        }
    }
}