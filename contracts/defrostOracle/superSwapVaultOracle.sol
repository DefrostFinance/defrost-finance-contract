/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "./chainLinkOracle.sol";
import "../uniswap/IUniswapV2Pair.sol";
import "../modules/SafeMath.sol";
import "../interface/ISuperToken.sol";
import "../interface/IStakeDao.sol";
contract superSwapVaultOracle is chainLinkOracle {
    using SafeMath for uint256;
    address public constant CEther = 0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c;
    address public constant joe = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
    address public constant xjoe = 0x57319d41F71E81F3c65F2a47CA4e001EbAFd4F33;
    address public constant sdav3CRV = 0x0665eF3556520B21368754Fb644eD3ebF1993AD4;
    address public constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    constructor(address multiSignature,address origin0,address origin1)
    chainLinkOracle(multiSignature,origin0,origin1) {
        assetPriceMap[uint256(0x1337BedC9D22ecbe766dF105c9623922A27963EC)] = 1e18; // curve av3
        assetPriceMap[uint256(0x5B5CFE992AdAC0C9D48E05854B2d91C73a003858)] = 1e18; // curve av3 gauge
        _setAssetsAggregator(address(0),0x0A77230d17318075983913bC2145DB16C7366156);
        _setAssetsAggregator(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,0x0A77230d17318075983913bC2145DB16C7366156);//wavax
        //_setAssetsAggregator(ALPHA ,0x7B0ca9A6D03FE0467A31Ca850f5bcA51e027B3aF);
        _setAssetsAggregator(0x63a72806098Bd3D9520cC43356dD78afe5D386D9 ,0x3CA13391E9fb38a75330fb28f8cc2eB3D9ceceED);//aave
        _setAssetsAggregator(0x50b7545627a5162F82A992c33b87aDc75187B218 ,0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743);//wbtc
        //_setAssetsAggregator(BUSD ,0x827f8a0dC5c943F7524Dda178E2e7F275AAd743f);
        //_setAssetsAggregator(CAKE ,0x79bD0EDd79dB586F22fF300B602E85a662fc1208);
        //_setAssetsAggregator(CHF ,0x3B37950485b450edF90cBB85d0cD27308Af4AB9A);
        _setAssetsAggregator(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70 ,0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300); //dai
        //_setAssetsAggregator(EPS ,0xB3ace8467271D12D8216818Dd2E8F84Cb6F9c212);
        _setAssetsAggregator(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB ,0x976B3D034E162d8bD72D6b9C989d545b839003b0);//weth
        _setAssetsAggregator(0x5947BB275c521040051D82396192181b413227A3 ,0x49ccd9ca821EfEab2b98c60dC60F518E765EDe9a); //link
        //_setAssetsAggregator(LUNA ,0x12Fe6A4DF310d4aD9887D27D4fce45a6494D4a4a);
        //_setAssetsAggregator(MDX ,0x6131b26D4aD63004df7540a3B3031072273f003e);
        //_setAssetsAggregator(MIM ,0x54EdAB30a7134A16a54218AE64C73e1DAf48a8Fb);
        //_setAssetsAggregator(OHM ,0x0c40Be7D32311b36BE365A2A220243B8A651df5E);
        _setAssetsAggregator(0xCE1bFFBD5374Dac86a2893119683F4911a2F7814 ,0x4F3ddF9378a4865cf4f28BE51E10AECb83B7daeE);//spell
        //_setAssetsAggregator(SUSHI ,0x449A373A090d8A1e5F74c63Ef831Ceff39E94563);
        //_setAssetsAggregator(TRY ,0xA61bF273688Ea095b5e4c11f1AF5E763F7aEEE91);
        //_setAssetsAggregator(TUSD ,0x9Cf3Ef104A973b351B2c032AA6793c3A6F76b448);
        _setAssetsAggregator(0x8eBAf22B6F053dFFeaf46f4Dd9eFA95D89ba8580 ,0x9a1372f9b1B71B3A5a72E092AE67E172dBd7Daaa); //uni
        _setAssetsAggregator(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664 ,0xF096872672F44d6EBA71458D74fe67F9a77a23B9);//usdc
        _setAssetsAggregator(0xc7198437980c041c805A1EDcbA50c1Ce5db95118 ,0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a);//usdt
        _setAssetsAggregator(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd,0x02D35d3a8aC3e1626d3eE09A78Dd87286F5E8e3a);//joe
        _setAssetsAggregator(0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5,0x36E039e6391A5E7A7267650979fdf613f659be5D);//qi
        _setAssetsAggregator(0x47536F17F4fF30e64A96a7555826b8f9e66ec468,0x7CF8A6090A9053B01F3DF4D4e6CfEdd8c90d9027);//crv
    }

    function getPriceInfo(address token) public override view returns (bool,uint256){
        (bool bHave,uint256 price) = _getPrice(uint256(token));
        if(bHave){
            return (bHave,price);
        }
        if(token == xjoe){
            return getXjoePrice();
        }
        if(token == sdav3CRV) {
            return getSdav3CRVPrice();
        }  
        (bool success,) = token.staticcall(abi.encodeWithSignature("stakeToken()"));
        if(success){
            return getSuperPrice(token);
        }
        (success,) = token.staticcall(abi.encodeWithSignature("getReserves()"));
        if(success){
            return getUniswapPairPrice(token);
        }
        return (false,0);
    }
    function getSuperPrice(address token) public view returns (bool,uint256){
        address underlying = ISuperToken(token).stakeToken();
        (bool bTol,uint256 price) = getInnerTokenPrice(underlying);
        uint256 totalSuply = IERC20(token).totalSupply();
        if(totalSuply == 0){
            return (bTol,price);
        }
        uint256 balance = ISuperToken(token).stakeBalance();
        //1 qiToken = balance(underlying)/totalSuply super
        return (bTol,price.mul(balance)/totalSuply);
    }
    function getInnerTokenPrice(address token) internal view returns (bool,uint256){
        (bool bHave,uint256 price) = _getPrice(uint256(token));
        if(bHave){
            return (bHave,price);
        }
        if(token == xjoe){
            return getXjoePrice();
        }
        if(token == sdav3CRV) {
            return getSdav3CRVPrice();
        }   
        (bool success,) = token.staticcall(abi.encodeWithSignature("getReserves()"));
        if(success){
            return getUniswapPairPrice(token);
        }
        return (false,0);
    }
    function getXjoePrice()  public view returns (bool,uint256) {
            uint256 totalSuply = IERC20(xjoe).totalSupply();
            uint256 balance = IERC20(joe).balanceOf(xjoe);
            //1 xjoe = balance(joe)/totalSuply joe
            (bool bTol,uint256 price) = _getPrice(uint256(joe));
            if (totalSuply == 0){
                return (bTol,price);
            }
            return (bTol,price.mul(balance)/totalSuply);
    }
    function getSdav3CRVPrice() public view returns (bool,uint256){
        uint256 priceRate = IVault(sdav3CRV).getPricePerFullShare();
        //1 xjoe = balance(joe)/totalSuply joe
        (bool have,uint256 price) = getInnerTokenPrice(av3Crv);
        return (have,price.mul(priceRate)/1e18);
    }
    function getUniswapPairPrice(address pair) public view returns (bool,uint256) {
        IUniswapV2Pair upair = IUniswapV2Pair(pair);
        (uint112 reserve0, uint112 reserve1,) = upair.getReserves();
        (bool have0,uint256 price0) = _getPrice(uint256(upair.token0()));
        (bool have1,uint256 price1) = _getPrice(uint256(upair.token1()));
        uint256 totalAssets = 0;
        if(have0 && have1){
            price0 *= reserve0;  
            price1 *= reserve1;
            uint256 tol = price1/10;  
            bool inTol = (price0 < price1+tol && price0 > price1-tol);
            totalAssets = price0+price1;
            uint256 total = upair.totalSupply();
            if (total == 0){
                return (false,0);
            }
            return (inTol,totalAssets/total);
        }else{
            return (false,0);
        }
    }
}