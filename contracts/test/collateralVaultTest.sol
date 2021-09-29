// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
import "../collateralVault/collateralVault.sol";
contract collateralVaultTest is collateralVault {
    uint256 internal timer;
        constructor (address multiSignature,bytes32 _vaultID,address _collateralToken,address _reservePool,address _systemCoin,address _dsOracle)
        super(multiSignature,_vaultID,_collateralToken,_reservePool,_systemCoin,_dsOracle){
    }
    function setTimer(uint256 _timer) external {
        timer = _timer;
    }
    function currentTime() internal virtual view returns (uint256){
        return timer;
    }
}