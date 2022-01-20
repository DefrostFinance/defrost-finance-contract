// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superQiTokenV2.sol";

// This contract handles swapping to and from superQiAvax.
contract superQiAvaxV2 is superQiTokenV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _dsOracle,address payable _FeePool)
            superQiTokenV2(multiSignature,origin0,origin1,0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c,_dsOracle,_FeePool) {
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
}