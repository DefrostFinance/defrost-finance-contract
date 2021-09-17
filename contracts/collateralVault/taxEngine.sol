pragma solidity =0.5.16;
import "../PhoenixModules/modules/SafeMath.sol";
import "./taxEngineData.sol";
import "../PhoenixModules/modules/safeTransfer.sol";
/**
 * @title Tax calculate pool.
 * @dev Borrow system coin, your debt will be increased with interests every minute.
 *
 */
contract taxEngine is taxEngineData,safeTransfer {
    using SafeMath for uint256;
    /**
     * @dev default function for foundation input miner coins.
     */
    function()external payable{

    }
    function setInterestInfo(uint256 _interestRate,uint256 _interestInterval)external onlyOrigin{
        _setInterestInfo(_interestRate,_interestInterval);
    }
    function canLiquidate(address account) external view returns (bool){
        uint256 assetAndInterest =getAssetBalance(account);
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 allCollateral = collateralBalances[account].mul(collateralPrice);
        return assetAndInterest.mul(collateralRate)>allCollateral;
    }
    function checkLiquidate(address account,uint256 removeCollateral,uint256 newMint) internal returns(bool){
        _interestSettlement();
        settleUserInterest(account);
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 allCollateral = (collateralBalances[account].sub(removeCollateral)).mul(collateralPrice);
        uint256 assetAndInterest = assetInfoMap[account].assetAndInterest.add(newMint);
        return assetAndInterest.mul(collateralRate)<=allCollateral;
    }
}