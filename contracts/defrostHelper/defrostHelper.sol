// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "./defrostHelperData.sol";
import "../interface/ICollateralVault.sol";
import "../interface/IDSOracle.sol";
import "../modules/IERC20.sol";
contract defrostHelper is defrostHelperData {
    constructor (address _defrostFactory) {
        defrostFactory = IDefrostFactory(_defrostFactory);
    }
    function getCollateralInfo()external view returns(address[] memory,address[] memory,uint8[] memory,uint256[] memory){
        address[] memory vaults = defrostFactory.getAllVaults();
        uint256 len = vaults.length-2;
        address[] memory tokens = new address[](len);
        uint8[] memory decimals = new uint8[](len);
        uint256[] memory prices = new uint256[](len);
        for (uint256 i=0;i<len;i++){
            ICollateralVault IVault = ICollateralVault(vaults[i]);
            address oracle = IVault.getOracleAddress();
            tokens[i] = IVault.collateralToken();
            if(tokens[i] == address(0)){
                decimals[i] = 18;    
            }else{
                decimals[i] = IERC20(tokens[i]).decimals();
            }
            (,prices[i]) = IDSOracle(oracle).getPriceInfo(tokens[i]);
        }
        return (vaults,tokens,decimals,prices);
    }
}