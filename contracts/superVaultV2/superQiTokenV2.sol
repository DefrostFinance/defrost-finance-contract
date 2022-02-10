// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;
import "../interface/ICToken.sol";
import "./superTokenV2.sol";
import "../superVault/IBenqiCompound.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superQiTokenV2 is superTokenV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    address public underlying;

    IBenqiCompound public constant compounder = IBenqiCompound(0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4);
    
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool)
            superTokenV2(multiSignature,origin0,origin1,_stakeToken,_dsOracle,_FeePool) {
        _setReward(0,0,false,0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5,1e17);
        _setReward(1,1,false,address(0),1e15);
    }
    function getSwapRouterPath(address token)public view returns (address[] memory path){
         return getSwapRouterPathInfo(token,underlying);
    }
    function claimReward(uint index) internal {
        rewardInfo memory info = rewardInfos[index];
        if(info.bClosed){
            return;
        }
        address[] memory qiTokens = new address[](1); 
        qiTokens[0] = address(stakeToken);
        compounder.claimReward(info.rewardType,address(this),qiTokens);
        swapOnDex(info.rewardToken,info.sellLimit);
    }
    function swapOnDex(address token,uint256 sellLimit)internal{
        uint256 balance = (token != address(0)) ? IERC20(token).balanceOf(address(this)) : address(this).balance;
        if (balance < sellLimit){
            return;
        }
        swapOnDex(token,underlying,balance);
    }
    function getStakeTokenPrice() public override view returns (uint256) {
        ICErc20 token = ICErc20(address(stakeToken));
        uint256 exchangeRate = token.exchangeRateStored();
        (,uint256 price) = oraclePrice(address(underlying));
        return price.mul(exchangeRate)/1e18;
    }
}