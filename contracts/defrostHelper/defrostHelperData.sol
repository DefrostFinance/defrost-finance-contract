pragma solidity =0.5.16;
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../interestEngine/ISystemToken.sol";
import "../DeFrostFactory/IDefrostFactory.sol";

contract defrostHelperData is versionUpdater {
    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    ISystemToken public systemToken;
    IDefrostFactory public defrostFactory;
}