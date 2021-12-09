// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superToken.sol";
import "./IBenqiCompound.sol";
import "../uniswap/IJoeRouter01.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superQiToken is superToken {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    address public underlying;

    struct rewardInfo {
        uint8 rewardType;
        bool bClosed;
        address rewardToken;
        uint256 sellLimit;
    }
    rewardInfo[] public rewardInfos;
    IBenqiCompound public constant compounder = IBenqiCompound(0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4);
    address public constant traderJoe = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    event SetReward(address indexed from, uint256 index,uint8 _reward,bool _bClosed,address _rewardToken,uint256 _sellLimit);
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool)
            superToken(multiSignature,origin0,origin1,_stakeToken,_dsOracle,_FeePool) {
        _setReward(0,0,false,0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5,1e17);
        _setReward(1,1,false,address(0),1e15);
    }
     function getSwapRouterPath(address token)public view returns (address[] memory path){
         return getSwapRouterPathInfo(token,underlying);
    }
    function setReward(uint256 index,uint8 _reward,bool _bClosed,address _rewardToken,uint256 _sellLimit)  external onlyOrigin {
        _setReward(index,_reward,_bClosed,_rewardToken,_sellLimit);
    }
    function _setReward(uint256 index,uint8 _reward,bool _bClosed,address _rewardToken,uint256 _sellLimit) internal{
        if(index <rewardInfos.length){
            rewardInfo storage info = rewardInfos[index];
            info.rewardType = _reward;
            info.bClosed = _bClosed;
            info.rewardToken = _rewardToken;
            info.sellLimit = _sellLimit;
        }else{
            rewardInfos.push(rewardInfo(_reward,_bClosed,_rewardToken,_sellLimit));
            if(_rewardToken != address(0)){
                SafeERC20.safeApprove(IERC20(_rewardToken), traderJoe, uint(-1));
            }
        }
        emit SetReward(msg.sender,index,_reward,_bClosed,_rewardToken,_sellLimit);
    }
}