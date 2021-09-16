pragma solidity =0.5.16;
interface ICollateralVault {
    function initContract(bytes32 _vaultID,address _collateralToken,address _taxPool,address _systemToken,address _dsOracle,
        uint256 _taxRate,uint256 _taxInterval,uint256 _debtCeiling,uint256 _debtFloor,
        uint256 _collateralRate,uint256 _liquidationReward,uint256 _liquidationPunish)external;
}