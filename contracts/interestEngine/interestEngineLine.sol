pragma solidity =0.5.16;
import "./interestEngine.sol";
/**
 * @title interest engine.
    * @dev calculate interest by assets,not compounded interest.
 *
 */
contract interestEngineLine is interestEngine{
    function newAccumulatedRate()internal view returns (uint256){
        uint256 newRate = interestRate.mul((now-latestSettleTime)/interestInterval);
        return accumulatedRate.add(newRate);
    }
}