pragma solidity =0.5.16;
import "../PhoenixModules/proxyModules/Halt.sol";
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/modules/oneBlockLimit.sol";
import "../interestEngine/ISystemToken.sol";
import "../interestEngine/interestEngine.sol";
contract depositPoolData is Halt,versionUpdater,oneBlockLimit,interestEngine {
    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }

    ISystemToken public systemToken;
    event Deposit(address indexed sender, address indexed account, uint256 amount);
    event Withdraw(address indexed sender, address indexed account, uint256 amount);
}