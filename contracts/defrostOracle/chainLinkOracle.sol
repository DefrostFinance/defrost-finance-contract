/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "../modules/IERC20.sol";
import "./AggregatorV3Interface.sol";
import "../modules/proxyOwner.sol";
contract chainLinkOracle is proxyOwner {
    mapping(uint256 => AggregatorV3Interface) internal assetsMap;
    mapping(uint256 => uint256) internal decimalsMap;
    mapping(uint256 => uint256) internal assetPriceMap;
    event SetAssetsAggregator(address indexed sender,uint256 asset,address aggeregator);
    constructor(address multiSignature,address origin0,address origin1)
    proxyOwner(multiSignature,origin0,origin1) {
    } 
    /**
      * @notice set price of an asset
      * @dev function to set price for an asset
      * @param asset Asset for which to set the price
      * @param aggergator the Asset's aggergator
      */    
    function setAssetsAggregator(address asset,address aggergator) public onlyOrigin {
        _setAssetsAggregator(asset,aggergator);
    }
    function _setAssetsAggregator(address asset,address aggergator) internal {
        assetsMap[uint256(asset)] = AggregatorV3Interface(aggergator);
        uint8 _decimals = 18;
        if (asset != address(0)){
            _decimals = IERC20(asset).decimals();
        }
        uint8 priceDecimals = AggregatorV3Interface(aggergator).decimals();
        decimalsMap[uint256(asset)] = 36-priceDecimals-_decimals;
        emit SetAssetsAggregator(msg.sender,uint256(asset),aggergator);
    }
    /**
      * @notice set price of an underlying
      * @dev function to set price for an underlying
      * @param underlying underlying for which to set the price
      * @param aggergator the underlying's aggergator
      */  
    function setUnderlyingAggregator(uint256 underlying,address aggergator,uint256 _decimals) public onlyOrigin {
        _setUnderlyingAggregator(underlying,aggergator,_decimals);
    }
    function _setUnderlyingAggregator(uint256 underlying,address aggergator,uint256 _decimals) internal{
        require(underlying>0 , "underlying cannot be zero");
        assetsMap[underlying] = AggregatorV3Interface(aggergator);
        uint8 priceDecimals = AggregatorV3Interface(aggergator).decimals();
        decimalsMap[underlying] = 36-priceDecimals-_decimals;
        emit SetAssetsAggregator(msg.sender,underlying,aggergator);
    }
    function getAssetsAggregator(address asset) public view returns (address,uint256) {
        return (address(assetsMap[uint256(asset)]),decimalsMap[uint256(asset)]);
    }
    function getUnderlyingAggregator(uint256 underlying) external view returns (address,uint256) {
        return (address(assetsMap[underlying]),decimalsMap[underlying]);
    }
    function _getPrice(uint256 underlying) internal view returns (bool,uint256) {
        AggregatorV3Interface assetsPrice = assetsMap[underlying];
        if (address(assetsPrice) != address(0)){
            (, int price,,,) = assetsPrice.latestRoundData();
            uint256 tokenDecimals = decimalsMap[underlying];
            return (true,uint256(price)*(10**tokenDecimals));
        }else {
            uint256 price = assetPriceMap[underlying];
            if (price > 0){
                return (true,price);
            }
            return (false,0);
        }
    }
    function getUnderlyingPrice(uint256 underlying) public view returns (uint256) {
        (,uint256 price) = _getPrice(underlying);
        return price;
    }
    function getPriceInfo(address token) public virtual view returns (bool,uint256){
        return _getPrice(uint256(token));
    }
    function getPrice(address token) public view returns (uint256) {
        (,uint256 price) = getPriceInfo(token);
        return price;
    }
    function getPrices(address[]calldata assets) external view returns (uint256[]memory) {
        uint256 len = assets.length;
        uint256[] memory prices = new uint256[](len);
        for (uint i=0;i<len;i++){
            prices[i] = getPrice(assets[i]);
        }
        return prices;
    }
}