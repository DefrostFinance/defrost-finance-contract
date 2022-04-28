// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;
import "./superTokenV2.sol";
import "../interface/IAAVEPool.sol";
import "../interface/IAAVERewards.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superATokenV2 is superTokenV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    address public underlying;
    IAAVEPool public constant aavePool = IAAVEPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    IAAVERewards public constant aaveRewards = IAAVERewards(0x929EC64c34a17401F460460D4B9390518E5B473e);
    
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool)
            superTokenV2(multiSignature,origin0,origin1,_stakeToken,_dsOracle,_FeePool) {
        _setReward(0,0,false,WAVAX,1e15);
 //       _setReward(1,1,false,address(0),1e15);
    }
    function getSwapRouterPath(address token)public view returns (address[] memory path){
         return getSwapRouterPathInfo(token,underlying);
    }
    function claimReward() internal {
        address[] memory assets = new address[](1);
        assets[0] = address(stakeToken);
        aaveRewards.claimAllRewards(assets,address(this));
        uint nLen = rewardInfos.length;
        for (uint i=0;i<nLen;i++){
            rewardInfo memory info = rewardInfos[i];
            if(info.bClosed){
                continue;
            }
            swapOnDex(info.rewardToken,info.sellLimit);
        }
    }
    function swapOnDex(address token,uint256 sellLimit)internal{
        uint256 balance = (token != address(0)) ? IERC20(token).balanceOf(address(this)) : address(this).balance;
        if (balance < sellLimit){
            return;
        }
        swapOnDex(token,underlying,balance);
    }
    function getStakeTokenPrice() public override view returns (uint256) {
        (,uint256 price) = oraclePrice(address(underlying));
        return price;
    }
}