// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
import "./defrostFactoryData.sol";
import "../collateralVault/collateralVault.sol";
import "../systemCoin/Coin.sol";
interface Authorization{
    function addAuthorization(address account) external;
}
contract defrostFactory is defrostFactoryData {
    /**
     * @dev constructor.
     */
    constructor (address multiSignature,address origin0,address origin1,address _reservePool,address _dsOracle) 
        proxyOwner(multiSignature,origin0,origin1) {
        reservePool = _reservePool;
        dsOracle = _dsOracle;
    }
    function createVault(bytes32 vaultID,address collateral,uint256 debtCeiling,uint256 debtFloor,uint256 collateralRate,
    int256 stabilityFee,uint256 feeInterval,uint256 liquidationReward,uint256 liquidationPenalty)external onlyOrigin returns(address){
        address vaultAddress = getVault(vaultID);
        require(vaultAddress == address(0),"this vault is already created!");
        return createVaultPool(vaultID,collateral,debtCeiling,debtFloor,collateralRate,
            stabilityFee,feeInterval,liquidationReward,liquidationPenalty);
    }
    function getVault(bytes32 vaultID)public view returns (address){
        return vaultsMap[vaultID];
    }
    function getAllVaults()external view returns (address[] memory){
        return allVaults;
    }
    function createVaultPool(bytes32 vaultID,address collateral,uint256 debtCeiling,uint256 debtFloor,uint256 collateralRate,
    int256 stabilityFee,uint256 feeInterval,uint256 liquidationReward,uint256 liquidationPenalty)internal virtual returns(address){
        (address _origin0,address _origin1) = txOrigin();
        collateralVault vaultPool = new collateralVault(getMultiSignatureAddress(),_origin0,_origin1,vaultID,collateral,reservePool,systemCoin,dsOracle);
        vaultPool.initContract(stabilityFee,feeInterval,debtCeiling,debtFloor,collateralRate,liquidationReward,liquidationPenalty);
        Authorization(systemCoin).addAuthorization(address(vaultPool));
        vaultsMap[vaultID] = address(vaultPool);
        allVaults.push(address(vaultPool));
        emit CreateVaultPool(address(vaultPool),vaultID,collateral,debtCeiling,debtFloor,collateralRate,
            stabilityFee,feeInterval);
        return address(vaultPool);
    }
    function createSystemCoin(string memory name_,
        string memory symbol_,
        uint256 chainId_)external onlyOrigin {
        require(systemCoin == address(0),"systemCoin : systemCoin is already deployed!");
        Coin coin = new Coin(name_,symbol_,chainId_);
        systemCoin = address(coin);
    }
}