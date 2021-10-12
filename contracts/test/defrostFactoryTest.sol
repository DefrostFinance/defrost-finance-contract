// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
import "../defrostFactory/defrostFactory.sol";
import "./collateralVaultTest.sol";
contract defrostFactoryTest is defrostFactory {
    constructor (address multiSignature,address origin0,address origin1,address _reservePool,address _dsOracle) 
        defrostFactory(multiSignature,origin0,origin1,_reservePool,_dsOracle) {
    }
    function createVaultPool(bytes32 vaultID,address collateral,uint256 debtCeiling,uint256 debtFloor,uint256 collateralRate,
        int256 stabilityFee,uint256 feeInterval,uint256 liquidationReward,uint256 liquidationPenalty)internal override returns(address){
        (address _origin0,address _origin1) = txOrigin();
        collateralVaultTest vaultPool = new collateralVaultTest(getMultiSignatureAddress(),_origin0,_origin1,vaultID,collateral,reservePool,systemCoin,dsOracle);
        vaultPool.initContract(stabilityFee,feeInterval,debtCeiling,debtFloor,collateralRate,liquidationReward,liquidationPenalty);
        Authorization(systemCoin).addAuthorization(address(vaultPool));
        vaultsMap[vaultID] = address(vaultPool);
        emit CreateVaultPool(address(vaultPool),vaultID,collateral,debtCeiling,debtFloor,collateralRate,
            stabilityFee,feeInterval);
        return address(vaultPool);
    }
}