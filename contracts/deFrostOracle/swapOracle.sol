/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "../modules/IERC20.sol";
import "../uniswap/IUniswapV2Pair.sol";
import "../uniswap/IUniswapV2Factory.sol";
import "./AggregatorV3Interface.sol";
import "../modules/proxyOwner.sol";
contract swapOracle is proxyOwner {
    IUniswapV2Factory public uniswapFactory;
    mapping(uint256 => AggregatorV3Interface) internal assetsMap;
    mapping(uint256 => uint256) internal decimalsMap;
    constructor(address multiSignature,address origin0,address origin1,address _uniswapFactory) public
    proxyOwner(multiSignature,origin0,origin1) {
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
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
    }
    function getAssetsAggregator(address asset) public view returns (address,uint256) {
        return (address(assetsMap[uint256(asset)]),decimalsMap[uint256(asset)]);
    }
    function getUnderlyingAggregator(uint256 underlying) external view returns (address,uint256) {
        return (address(assetsMap[underlying]),decimalsMap[underlying]);
    }

    function getUnderlyingPrice(uint256 underlying) public view returns (bool,uint256) {
        AggregatorV3Interface assetsPrice = assetsMap[underlying];
        if (address(assetsPrice) != address(0)){
            (, int price,,,) = assetsPrice.latestRoundData();
            uint256 tokenDecimals = decimalsMap[underlying];
            return (true,uint256(price)*(10**tokenDecimals));
        }else {
            return (false,0);
        }
    }
    function getErc20Price(address erc20) public view returns (bool,uint256) {
        return getUnderlyingPrice(uint256(erc20));        
    }
    function getUniswapPairPrice(address pair) public view returns (uint256) {
        IUniswapV2Pair upair = IUniswapV2Pair(pair);
        (uint112 reserve0, uint112 reserve1,) = upair.getReserves();
        (bool have0,uint256 price0) = getErc20Price(upair.token0());
        (bool have1,uint256 price1) = getErc20Price(upair.token1());
        uint256 totalAssets = 0;
        if(have0 && have1){
            totalAssets = price0*reserve0+price1*reserve1;
        }else if(have0){
            totalAssets = price0*reserve0*2;
        }else if(have1){
            totalAssets = price1*reserve1*2;
        }else{
            return 0;
        }
        uint256 total = upair.totalSupply();
        if (total == 0){
            return 0;
        }
        return totalAssets/total;
    }
    function getPrice(address token) public view returns (uint256) {
        (bool success, bytes memory returnData) = token.staticcall(abi.encodeWithSignature("getReserves()"));
        if(success){
            return getUniswapPairPrice(token);
        }else{
            (,uint256 price) = getErc20Price(token);
            return price;
        }
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