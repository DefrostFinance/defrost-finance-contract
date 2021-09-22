pragma solidity =0.5.16;
import "../PhoenixModules/proxyModules/versionUpdater.sol";
contract defrostFactoryData is versionUpdater{
    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    struct proxyInfo {
        address implementation;
        address payable[] proxyList;
    }
    uint256 constant public vaultPoolID = 0;
    mapping(uint256=>proxyInfo) public proxyinfoMap;
    mapping(bytes32=>address) public vaultsMap;
    address public reservePool;
    address public systemToken;
    address public dsOracle;
    address public systemCoinMinePool; 
    uint256 public liquidationReward;
    uint256 public liquidationPunish; 

    event CreateVaultPool(address indexed poolAddress,bytes32 indexed vaultID,address indexed collateral,uint256 debtCeiling,uint256 debtFloor,uint256 collateralRate,
    uint256 taxRate,uint256 taxInterval);
    event CreateSystemCoinMinePool(address indexed poolAddress);

}