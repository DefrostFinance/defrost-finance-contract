/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "./lendOracle.sol";
contract benqiOracle is lendOracle {
    constructor(address multiSignature,address origin0,address origin1)
    chainLinkOracle(multiSignature,origin0,origin1) {
        CEther = 0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c;
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
    }
}