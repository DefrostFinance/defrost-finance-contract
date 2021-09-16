pragma solidity =0.5.16;
import "../PhoenixModules/proxyModules/Halt.sol";
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/modules/oneBlockLimit.sol";
import "../PhoenixModules/interface/IPHXOracle.sol";
import "../interestEngine/ISystemToken.sol";
import "../interestEngine/interestEngine.sol";
contract taxEngineData is Halt,versionUpdater,oneBlockLimit,ImportOracle,interestEngine {
    uint256 constant internal currentVersion = 1;
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
    address public taxPool;
    ISystemToken public systemToken;

    /**
     * @dev Emitted when `account` mint `amount` miner shares.
     */
    event MintMiner(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `account` burn `amount` miner shares.
     */
    event BurnMiner(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `from` redeem `value` mineCoins.
     */
    event RedeemMineCoin(address indexed from, address indexed mineCoin, uint256 value);
    /**
     * @dev Emitted when `from` transfer to `to` `amount` mineCoins.
     */
    event TranserMiner(address indexed from, address indexed to, uint256 amount);
    /**
     * @dev Emitted when `account` buying options get `amount` mineCoins.
     */
    event BuyingMiner(address indexed account,address indexed mineCoin,uint256 amount);

    event Join(address sender, address account, uint256 amount);
    event Exit(address sender, address account, uint256 amount);
}