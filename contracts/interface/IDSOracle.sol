// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "../modules/proxyOwner.sol";
interface IDSOracle {
    /**
  * @notice retrieves price of an asset
  * @dev function to get price for an asset
  * @param token Asset for which to get the price
  * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
  */
    function getPriceInfo(address token) external view returns (bool,uint256);
    function getPrices(address[]calldata assets) external view returns (uint256[]memory);
}
abstract contract ImportOracle is proxyOwner{
    IDSOracle internal _oracle;
    function oraclePrice(address asset) internal view returns (bool,uint256){
        (bool inTol,uint256 price) = _oracle.getPriceInfo(asset);
        require(price >= 100 && price <= 1e45,"oracle price error");
        return (inTol,price);
    }
    function getOracleAddress() public view returns(address){
        return address(_oracle);
    }
    function setOracleAddress(address oracle)public OwnerOrOrigin{
        _oracle = IDSOracle(oracle);
    }
}
