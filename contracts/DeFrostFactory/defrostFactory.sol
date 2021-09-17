pragma solidity =0.5.16;
import "./defrostFactoryData.sol";
import "../collateralVault/ICollateralVault.sol";
import "../interestEngine/ISystemToken.sol";
import "../PhoenixModules/proxy/phxProxy.sol";
import "../PhoenixModules/modules/Address.sol";
import "../PhoenixModules/proxyModules/proxyOperator.sol";
interface Authorization{
    function addAuthorization(address account) external;
}
contract defrostFactory is defrostFactoryData {
    /**
     * @dev constructor.
     */
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }
    function update() public versionUpdate {
    }

    function initContract(address _taxPool,address _systemToken,address _dsOracle,address _vaultPoolImpl,
        uint256 _liquidationReward,uint256 _liquidationPunish)public originOnce{
        taxPool = _taxPool;
        systemToken = _systemToken;
        dsOracle = _dsOracle;
        liquidationReward = _liquidationReward;
        liquidationPunish = _liquidationPunish; 
        proxyinfoMap[vaultPoolID].implementation = _vaultPoolImpl;
    }
    function createVault(bytes32 vaultID,address collateral,uint256 debtCeiling,uint256 debtFloor,uint256 collateralRate,
    uint256 taxRate,uint256 taxInterval)external onlyOrigin returns(address payable){
        address vaultAddress = getVault(vaultID);
        require(vaultAddress == address(0),"this vault is already created!");
        return createVaultPool(vaultID,collateral,debtCeiling,debtFloor,collateralRate,taxRate,taxInterval);
    }
    function getVault(bytes32 vaultID)public view returns (address){
        return vaultsMap[vaultID];
    }
    function getAllVaults()external view returns (address payable[] memory){
        return proxyinfoMap[vaultPoolID].proxyList;
    }
    function createVaultPool(bytes32 vaultID,address collateral,uint256 debtCeiling,uint256 debtFloor,uint256 collateralRate,
    uint256 taxRate,uint256 taxInterval)internal returns(address payable){
        address payable vaultPool = createPhxProxy(vaultPoolID);
        ICollateralVault(vaultPool).initContract(vaultID,collateral,taxPool,systemToken,dsOracle,
            taxRate,taxInterval,debtCeiling,debtFloor,collateralRate,liquidationReward,liquidationPunish);
        Authorization(systemToken).addAuthorization(vaultPool);
        vaultsMap[vaultID] = vaultPool;
        emit CreateVaultPool(vaultPool,vaultID,collateral,debtCeiling,debtFloor,collateralRate,
            taxRate,taxInterval);
        return vaultPool;
    }
    function createPhxProxy(uint256 index) internal returns (address payable){
        proxyInfo storage curInfo = proxyinfoMap[index];
        phxProxy newProxy = new phxProxy(curInfo.implementation,getMultiSignatureAddress());
        curInfo.proxyList.push(address(newProxy));
        return address(newProxy);
    }
    function setContractsInfo(uint256 index,bytes memory data)internal{
        proxyInfo storage curInfo = proxyinfoMap[index];
        uint256 len = curInfo.proxyList.length;
        for(uint256 i = 0;i<len;i++){
            Address.functionCall(curInfo.proxyList[i],data,"setContractsInfo error");
        }
    }
    function setOracleAddress(address _dsOracle)public onlyOrigin{
        dsOracle = _dsOracle;
        setContractsInfo(vaultPoolID,abi.encodeWithSignature("setOracleAddress(address)",_dsOracle));
    }
    function upgradePhxProxy(uint256 index,address implementation) public onlyOrigin{
        proxyInfo storage curInfo = proxyinfoMap[index];
        curInfo.implementation = implementation;
        uint256 len = curInfo.proxyList.length;
        for(uint256 i = 0;i<len;i++){
            phxProxy(curInfo.proxyList[i]).upgradeTo(implementation);
        }        
    }
    function createSystemCoinMinePool(address _implementation) external onlyOrigin returns(address){
        phxProxy newProxy = new phxProxy(_implementation,getMultiSignatureAddress());
        proxyOperator(address(newProxy)).setManager(systemToken);
        systemCoinMinePool = address(newProxy);
        ISystemToken(systemToken).setMinePool(address(newProxy));
        emit CreateSystemCoinMinePool(address(newProxy));
        return address(newProxy);
    }
}