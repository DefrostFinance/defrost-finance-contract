// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superATokenV2.sol";
import "../interface/IAToken.sol";

//
// This contract handles swapping to and from superQiErc20
contract superAErc20V2 is superATokenV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _AToken,address _dsOracle,address payable _FeePool)
            superATokenV2(multiSignature,origin0,origin1,_AToken,_dsOracle,_FeePool) {
        underlying = IAToken(_AToken).UNDERLYING_ASSET_ADDRESS();
        SafeERC20.safeApprove(IERC20(underlying), address(aavePool), uint(-1));
    }
    function compound() external{
        latestCompoundTime = block.timestamp;
        claimReward();
        IERC20 oToken = IERC20(underlying);
        uint256 balance = oToken.balanceOf(address(this));
        if (balance>0){
            uint256 fee = balance.mul(feeRate)/10000;
            oToken.safeTransfer(FeePool,fee);
            aavePool.supply(underlying, balance.sub(fee), address(this), 0);
        }
    }
}