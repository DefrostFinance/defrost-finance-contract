pragma solidity =0.5.16;
import "./interestEngine.sol";
/**
 * @title interest engine.
    * @dev calculate interest by assets,not compounded interest.
 *
 */
contract interestEngineLinear is interestEngine{
    function getAssetBalance(address account)public view returns(uint256){
        if(assetInfoMap[account].interestRateOrigin == 0 || interestInterval == 0){
            return 0;
        }
        uint256 newRate = newAccumulatedRate();
        return assetInfoMap[account].assetAndInterest.add(
            assetInfoMap[account].originAsset.mul(newRate.sub(assetInfoMap[account].interestRateOrigin)));
    }
    function _settlement(address account)internal view returns (uint256) {
        if (assetInfoMap[account].interestRateOrigin == 0){
            return 0;
        }
        return assetInfoMap[account].assetAndInterest.add(
            assetInfoMap[account].originAsset.mul(accumulatedRate.sub(assetInfoMap[account].interestRateOrigin)));
    }
    function newAccumulatedRate()internal view returns (uint256){
        uint256 newRate = interestRate.mul((now-latestSettleTime)/interestInterval);
        return accumulatedRate.add(newRate);
    }
}