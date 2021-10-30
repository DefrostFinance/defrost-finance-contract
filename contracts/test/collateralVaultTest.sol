// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "../collateralVault/collateralVault.sol";
contract collateralVaultTest is collateralVault {
    uint256 internal timer;
    constructor (address multiSignature,address origin0,address origin1,bytes32 _vaultID,address _collateralToken,address _reservePool,address _systemCoin,address _dsOracle)
        collateralVault(multiSignature,origin0,origin1,_vaultID,_collateralToken,_reservePool,_systemCoin,_dsOracle){
    }
    function setTimer(uint256 _timer) external {
        timer = _timer;
    }
    function currentTime() internal override view returns (uint256){
        return timer;
    }
    function getAccumulatedRate()external view returns(uint256){
        return accumulatedRate;
    }
}