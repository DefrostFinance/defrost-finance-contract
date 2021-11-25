/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "./chainLinkOracle.sol";
import "../modules/SafeMath.sol";
contract xjoeOracle is chainLinkOracle {
    using SafeMath for uint256;
    address public joe = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
    address public xjoe = 0x57319d41F71E81F3c65F2a47CA4e001EbAFd4F33;
    constructor(address multiSignature,address origin0,address origin1)
        chainLinkOracle(multiSignature,origin0,origin1) {
            _setAssetsAggregator(joe,0x02D35d3a8aC3e1626d3eE09A78Dd87286F5E8e3a);
    }
    function getPriceInfo(address token) public override view returns (bool,uint256){
        if(token == xjoe){
            uint256 totalSuply = IERC20(xjoe).totalSupply();
            uint256 balance = IERC20(joe).balanceOf(xjoe);
            //1 xjoe = balance(joe)/totalSuply joe
            (bool bTol,uint256 price) = _getPrice(uint256(joe));
            return (bTol,price.mul(balance)/totalSuply);
        }else{
            return _getPrice(uint256(token));
        }
    }
}