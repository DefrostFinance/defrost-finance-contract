pragma solidity =0.5.16;
import "../PhoenixModules/proxyModules/Halt.sol";
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/modules/oneBlockLimit.sol";
import "../PhoenixModules/interface/IPHXOracle.sol";
import "../interestEngine/ISystemToken.sol";
import "../interestEngine/interestEngine.sol";
contract taxEngineData is Halt,versionUpdater,oneBlockLimit,ImportOracle,interestEngine {
    uint256 constant internal currentVersion = 4;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    bytes32 public vaultID;
    //Special decimals for calculation
    uint256 constant calDecimals = 1e18;

    uint256 public collateralRate;
    uint256 public liquidationReward;
    uint256 public liquidationPunish;

    //collateral balance
    mapping(address=>uint256) public collateralBalances;
    
    address public collateralToken;
    address public reservePool;
    ISystemToken public systemToken;

    event MintSystemCoin(address indexed sender,address indexed account,uint256 amount);
    event RepaySystemCoin(address indexed sender,address indexed account,uint256 amount);
    event Liquidate(address indexed sender,address indexed account,address indexed collateralToken,
        uint256 debt,uint256 punishment,uint256 amount);
    event Join(address indexed sender, address indexed account, uint256 amount);
    event Exit(address indexed sender, address indexed account, uint256 amount);
}