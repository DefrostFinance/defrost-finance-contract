/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "../modules/IERC20.sol";
import "../interface/IDSOracle.sol";
import "../modules/SafeMath.sol";
interface IMinter {
//    function coins(uint256 i) external view returns (address);
    function balances(uint256 arg0) external view returns (uint256);
}
interface ICurveToken {
    function minter() external view returns (address);
}
contract curve3CoinAggregator {
    using SafeMath for uint256;
    address public minter;
    address public token;
    address[] coins;
    IDSOracle internal oracle;
    constructor(address _token,address _oracle,address[]memory _coins) {
        minter = ICurveToken(_token).minter();
        token = _token;
        coins = _coins;
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
    function getTokenPrice() public view returns (int256){
        uint256 totalSupply = IERC20(token).totalSupply();
        if(totalSupply == 0){
            return 0;
        }
        IMinter _minter = IMinter(minter);
        uint256 totalMoney = 0;
        uint256 len = coins.length;
        for (uint256 i = 0;i<len;i++){
            address coin = coins[i];
            uint256 balance = _minter.balances(i);
            (bool bGet ,uint256 price) = oracle.getPriceInfo(coin);
            if(!bGet){
                return 0;
            }
            totalMoney = totalMoney.add(balance.mul(price));
        }
        return int256(totalMoney/totalSupply);
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