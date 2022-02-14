/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "../modules/IERC20.sol";
import "../interface/IDSOracle.sol";
contract curveLPAggregator {
    address public token;
    IDSOracle internal oracle;
    constructor(address _token,address _oracle) {
        token = _token;
        oracle = IDSOracle(_oracle);
    } 
    function decimals() external view returns (uint8){
        return IERC20(token).decimals();
    }
    function description() external view returns (string memory){
        return IERC20(token).symbol();
    }
    function version() external pure returns (uint256){
        return 1;
    }
    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ){
        (,uint256 price) = oracle.getPriceInfo(token);
        return (0,int256(price),0,0,0);
    }
    function latestRoundData()
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ){
        (,uint256 price) = oracle.getPriceInfo(token);
        return (0,int256(price),0,0,0);
    }

}