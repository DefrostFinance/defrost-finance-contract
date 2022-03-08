/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "./AggregatorV3Interface.sol";
contract gOHMAggregator {
    AggregatorV3Interface internal ohmIndex = AggregatorV3Interface(0xB2B94f103406bD5d04d84a1beBc3E89F05EEDDEa);
    AggregatorV3Interface internal gOhmV2 = AggregatorV3Interface(0x1fA4Fc8E55939fC511d048e1ceCaFB4b2d30f9Eb);

    constructor() {
    } 
    function decimals() external view returns (uint8){
        return 18;
    }
    function description() external view returns (string memory){
        return "gOHM";
    }
    function version() external pure returns (uint256){
        return 1;
    }
    function getTokenPrice() public view returns (int256){
        (, int index,,,) = ohmIndex.latestRoundData();
        (, int price,,,) = gOhmV2.latestRoundData();
        return price*index*10;
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
        return (0,getTokenPrice(),0,0,0);
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
        return (0,getTokenPrice(),0,0,0);
    }

}