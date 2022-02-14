/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "./chainLinkOracle.sol";
import "../interface/ICToken.sol";
import "../modules/SafeMath.sol";
import "../interface/ISuperToken.sol";
interface IMinter {
//    function coins(uint256 i) external view returns (address);
    function balances(uint256 arg0) external view returns (uint256);
}
interface ICurveToken {
    function minter() external view returns (address);
}
contract superCurveVaultOracle is chainLinkOracle {
    using SafeMath for uint256;
    address public constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    address public constant av3Gauge = 0x5B5CFE992AdAC0C9D48E05854B2d91C73a003858;
    address public constant crvUSDBTCETH = 0x1daB6560494B04473A0BE3E7D83CF3Fdf3a51828;
    address public constant crvUSDBTCETHGauge = 0x445FE580eF8d70FF569aB36e80c647af338db351;
    constructor(address multiSignature,address origin0,address origin1)
    chainLinkOracle(multiSignature,origin0,origin1) {
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

        _setAssetsAggregator(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E ,0xF096872672F44d6EBA71458D74fe67F9a77a23B9);//usdc
        _setAssetsAggregator(0x260Bbf5698121EB85e7a74f2E45E16Ce762EbE11 ,0xf58B78581c480caFf667C63feDd564eCF01Ef86b);//ust
        _setAssetsAggregator(0x120AD3e5A7c796349e591F1570D9f7980F4eA9cb ,0x12Fe6A4DF310d4aD9887D27D4fce45a6494D4a4a);//luna
    }
    function getCurvePrice(address token,address[] memory coins)public view returns (bool,uint256){
        uint256 totalSupply = IERC20(token).totalSupply();
        if(totalSupply == 0){
            return (false,0);
        }
        address minter = ICurveToken(token).minter();
        IMinter _minter = IMinter(minter);
        uint256 totalMoney = 0;
        uint256 len = coins.length;
        uint256[] memory coinPrices = new uint256[](len);
        for (uint256 i = 0;i<len;i++){
            address coin = coins[i];
            uint256 balance = _minter.balances(i);
            (bool bGet ,uint256 price) = getInnerTokenPrice(coin);
            if(!bGet){
                return (false,0);
            }
            coinPrices[i] = balance.mul(price);
            totalMoney = totalMoney.add(coinPrices[i]);
        }
        bool bTol = true;
        uint256 minTol = 10000/len-1000;
        uint256 maxTol= 10000/len+1000;
        for (uint256 i = 0;i<len;i++){
            uint256 tol = coinPrices[i].mul(10000)/totalMoney;
            if(tol <minTol || tol > maxTol){
                bTol = false;
                break;
            }
        }
        return (bTol,totalMoney/totalSupply);
    }
    function getPriceInfo(address token) public override view returns (bool,uint256){
        (bool bHave,uint256 price) = getInnerTokenPrice(token);
        if(bHave){
            return (bHave,price);
        }
        (bool success,) = token.staticcall(abi.encodeWithSignature("stakeToken()"));
        if(success){
            return getSuperPrice(token);
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
        uint256 balance = IERC20(underlying).balanceOf(token);
        //1 qiToken = balance(underlying)/totalSuply super
        return (bTol,price.mul(balance)/totalSuply);
    }
    function getInnerTokenPrice(address token) internal view returns (bool,uint256){
        (bool bHave,uint256 price) = _getPrice(uint256(token));
        if(bHave){
            return (bHave,price);
        }

        if(token == av3Crv || token == av3Gauge){
            address[] memory coins = new address[](3); 
            coins[0] = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;//dai
            coins[1] = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;//USDC
            coins[2] = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;//dai
            return getCurvePrice(av3Crv,coins);
        }
        if (token == crvUSDBTCETH || token == crvUSDBTCETHGauge){
            address[] memory coins = new address[](3); 
            coins[0] = av3Crv;//av3Crv
            coins[1] = 0x50b7545627a5162F82A992c33b87aDc75187B218;//wbtc
            coins[2] = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;//dai
            return getCurvePrice(crvUSDBTCETH,coins);
        }
        return (false,0);
    }
}