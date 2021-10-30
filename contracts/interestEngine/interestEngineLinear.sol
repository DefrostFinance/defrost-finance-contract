// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "./interestEngine.sol";
/**
 * @title interest engine.
    * @dev calculate interest by assets,not compounded interest.
 *
 */
contract interestEngineLinear is interestEngine{
    using SafeMath for uint256;
    function getAssetBalance(address account)public override view returns(uint256){
        if(assetInfoMap[account].interestRateOrigin == 0 || interestInterval == 0){
            return 0;
        }
        uint256 newRate = newAccumulatedRate();
        return assetInfoMap[account].assetAndInterest.add(
            assetInfoMap[account].originAsset.mul(newRate.sub(assetInfoMap[account].interestRateOrigin)));
    }
    function _settlement(address account)internal override view returns (uint256) {
        if (assetInfoMap[account].interestRateOrigin == 0){
            return 0;
        }
        return assetInfoMap[account].assetAndInterest.add(
            assetInfoMap[account].originAsset.mul(accumulatedRate.sub(assetInfoMap[account].interestRateOrigin)));
    }
    function newAccumulatedRate()internal override view returns (uint256){
        int256 newRate = interestRate*(int256((block.timestamp-latestSettleTime)/interestInterval));
        if (newRate>=0){
            return accumulatedRate.add(uint256(newRate));
        }else{
            require(accumulatedRate>=uint256(-newRate),"Interest Engine : interest rate overflow!");
            return accumulatedRate - uint256(-newRate);
        }
    }
}