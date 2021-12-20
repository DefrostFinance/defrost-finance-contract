// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superJoeFarm.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superPair is superJoeFarm {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public LPToken0;
    address public LPToken1;
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool,uint256 _poolId)
            superJoeFarm(multiSignature,origin0,origin1,_stakeToken,_dsOracle,_FeePool,_poolId) {
        IUniswapV2Pair pair = IUniswapV2Pair(_stakeToken);
        LPToken0 = pair.token0();
        LPToken1 = pair.token1();
        string memory tokenName_ = string(abi.encodePacked("Super LP ",IERC20(LPToken0).name()," & ",IERC20(LPToken1).name()));
        string memory symble_ = string(abi.encodePacked("SLP-",IERC20(LPToken0).symbol(), "-" ,IERC20(LPToken1).symbol()));
        setErc20Info(tokenName_,symble_,IERC20(_stakeToken).decimals());
        IERC20(LPToken0).safeApprove(address(traderJoe),uint256(-1));
        IERC20(LPToken1).safeApprove(address(traderJoe),uint256(-1));
        setJoeTokenPath(LPToken0);
        setJoeTokenPath(LPToken1);
    }
    function setJoeTokenPath(address _token) internal {
        if(_token != WAVAX){
            swapRoutingPath[joeToken][_token] = new address[](3);
            swapRoutingPath[joeToken][_token][0] = joeToken;
            swapRoutingPath[joeToken][_token][1] = WAVAX;
            swapRoutingPath[joeToken][_token][2] = _token;
        }
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
            swapPair(info.rewardToken,info.sellLimit);
        }
        uint256 balance0 = IERC20(LPToken0).balanceOf(address(this));
        uint256 balance1 = IERC20(LPToken1).balanceOf(address(this));
        if (balance0>0 && balance1>0){
            uint256 fee = balance0.mul(feeRate)/10000;
            IERC20(LPToken0).safeTransfer(FeePool,fee);
            balance0 = balance0.sub(fee);
            fee = balance1.mul(feeRate)/10000;
            IERC20(LPToken1).safeTransfer(FeePool,fee);
            balance1 = balance1.sub(fee);
            IJoeRouter01(traderJoe).addLiquidity(LPToken0, LPToken1, balance0, balance1,0,0, address(this), block.timestamp+30);
            balance0 = IERC20(stakeToken).balanceOf(address(this));
            masterChefJoe.deposit(poolId,balance0);
        }
    }
    function swapPair(address token,uint256 sellLimit)internal{
        uint256 balance = (token != address(0)) ? IERC20(token).balanceOf(address(this)) : address(this).balance;
        if (balance < sellLimit){
            return;
        }
        swapTraderJoe(token,LPToken0,balance/2);
        swapTraderJoe(token,LPToken1,balance/2);
    }
}