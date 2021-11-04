// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "../modules/SafeMath.sol";
import "./vaultEngineData.sol";
import "../modules/safeTransfer.sol";
/**
 * @title Tax calculate pool.
 * @dev Borrow system coin, your debt will be increased with interests every minute.
 *
 */
abstract contract vaultEngine is vaultEngineData,safeTransfer {
    using SafeMath for uint256;
    /**
     * @dev default function for foundation input miner coins.
     */
    receive()external payable{

    }
    function setStabilityFee(int256 stabilityFee,uint256 feeInterval)external onlyOrigin{
        _setInterestInfo(stabilityFee,feeInterval,12e26,8e26);
    }
    function getCollateralLeft(address account) external view returns (uint256){
        uint256 assetAndInterest =getAssetBalance(account).mul(collateralRate);
        (,uint256 collateralPrice) = oraclePrice(collateralToken);
        uint256 allCollateral = collateralBalances[account].mul(collateralPrice);
        if (allCollateral > assetAndInterest){
            return (allCollateral - assetAndInterest)/collateralPrice;
        }
        return 0;
    }
    function canLiquidate(address account) external view returns (bool){
        uint256 assetAndInterest =getAssetBalance(account);
        (,uint256 collateralPrice) = oraclePrice(collateralToken);
        uint256 allCollateral = collateralBalances[account].mul(collateralPrice);
        return assetAndInterest.mul(collateralRate)>allCollateral;
    }
    function checkLiquidate(address account,uint256 removeCollateral,uint256 newMint) internal view returns(bool){
        (bool inTol,uint256 collateralPrice) = oraclePrice(collateralToken);
        require(inTol,"Oracle price is abnormal!");
        uint256 allCollateral = (collateralBalances[account].sub(removeCollateral)).mul(collateralPrice);
        uint256 assetAndInterest = assetInfoMap[account].assetAndInterest.add(newMint);
        return assetAndInterest.mul(collateralRate)<=allCollateral;
    }


}