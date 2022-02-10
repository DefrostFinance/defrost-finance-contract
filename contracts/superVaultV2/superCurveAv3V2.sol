// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superTokenV2.sol";
import "../superVault/ICurveGauge.sol";
//
// This contract handles swapping to and from superQiErc20
contract superCurveAv3V2 is superTokenV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public underlying = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    ICurveGauge public constant curveGauge = ICurveGauge(0x5B5CFE992AdAC0C9D48E05854B2d91C73a003858);
    ICurvePool public constant curvePool = ICurvePool(0x7f90122BF0700F9E7e1F688fe926940E8839F353);
    address public constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _dsOracle,address payable _FeePool)
            superTokenV2(multiSignature,origin0,origin1,0x5B5CFE992AdAC0C9D48E05854B2d91C73a003858,_dsOracle,_FeePool) {
        _setReward(0,0,false,0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,1e15);
        _setReward(1,1,false,0x47536F17F4fF30e64A96a7555826b8f9e66ec468,1e16);
        SafeERC20.safeApprove(IERC20(underlying), address(curvePool), uint(-1));
        SafeERC20.safeApprove(IERC20(av3Crv), address(curveGauge), uint(-1));

        address crv = 0x47536F17F4fF30e64A96a7555826b8f9e66ec468;
        swapRoutingPath[crv][underlying] = new address[](3);
        swapRoutingPath[crv][underlying][0] = crv;
        swapRoutingPath[crv][underlying][1] = WAVAX;
        swapRoutingPath[crv][underlying][2] = underlying;
    }
    function getSwapRouterPath(address token)public view returns (address[] memory path){
        return getSwapRouterPathInfo(token,underlying);
    }
    function compound() external{
        latestCompoundTime = block.timestamp;
        curveGauge.claim_rewards();
        uint nLen = rewardInfos.length;
        for (uint i=0;i<nLen;i++){
            rewardInfo memory info = rewardInfos[i];
            if(info.bClosed){
                continue;
            }
            swapOnDex(info.rewardToken,info.sellLimit);
        }
        IERC20 oToken = IERC20(underlying);
        uint256 balance = oToken.balanceOf(address(this));
        if (balance>0){
            uint256 fee = balance.mul(feeRate)/10000;
            oToken.safeTransfer(FeePool,fee);
            uint256[3] memory amounts = [0,balance.sub(fee),0]; 
            curvePool.add_liquidity(amounts,0,true);
            balance = IERC20(av3Crv).balanceOf(address(this));
            curveGauge.deposit(balance);
        }
    }
    function swapOnDex(address token,uint256 sellLimit)internal{
        uint256 balance = (token != address(0)) ? IERC20(token).balanceOf(address(this)) : address(this).balance;
        if (balance < sellLimit){
            return;
        }
        swapOnDex(token,underlying,balance);
    }
}