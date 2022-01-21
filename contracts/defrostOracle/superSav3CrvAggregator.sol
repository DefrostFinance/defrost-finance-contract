/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "../interface/IStakeDao.sol";
import "../modules/IERC20.sol";
contract superSav3CrvAggregator {
    address public constant sdav3CRV = 0x0665eF3556520B21368754Fb644eD3ebF1993AD4;
    address public constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    constructor() {
    } 
    function decimals() external view returns (uint8){
        return IERC20(sdav3CRV).decimals();
    }
    function description() external view returns (string memory){
        return IERC20(sdav3CRV).symbol();
    }
    function version() external pure returns (uint256){
        return 1;
    }
    function getSdav3CRVPrice() public view returns (int256){
        return int256(IVault(sdav3CRV).getPricePerFullShare());
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
        return (0,getSdav3CRVPrice(),0,0,0);
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
        return (0,getSdav3CRVPrice(),0,0,0);
    }

}