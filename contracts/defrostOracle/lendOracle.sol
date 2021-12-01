/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "./chainLinkOracle.sol";
import "../interface/ICToken.sol";
import "../modules/SafeMath.sol";
abstract contract lendOracle is chainLinkOracle {
    using SafeMath for uint256;
    address public CEther;
    function getCTokenPrice(address ctoken) public view returns (bool,uint256) {
        ICErc20 token = ICErc20(ctoken);
        uint256 exchangeRate = token.exchangeRateStored();
        (bool have,uint256 price) = _getPrice(uint256(token.underlying()));
        return (have,price.mul(exchangeRate)/1e18);
    }
    function getCEtherPrice() public view returns (bool,uint256){
        ICEther token = ICEther(CEther);
        uint256 exchangeRate = token.exchangeRateStored();
        (bool have,uint256 price) = _getPrice(0);
        return (have,price.mul(exchangeRate)/1e18);
    }
    function getPriceInfo(address token) public override view returns (bool,uint256){
        if(token == CEther){
            return getCEtherPrice();
        }else{
            (bool success,) = token.staticcall(abi.encodeWithSignature("exchangeRateStored()"));
            if(success){
                return getCTokenPrice(token);
            }else{
                return _getPrice(uint256(token));
            }
        }
    }
}