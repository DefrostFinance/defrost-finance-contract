/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "./lendOracle.sol";
contract benqiOracle is lendOracle {
    constructor(address multiSignature,address origin0,address origin1,address _CEther)
    chainLinkOracle(multiSignature,origin0,origin1) {
        CEther = _CEther;
        _setAssetsAggregator(address(0),0x0A77230d17318075983913bC2145DB16C7366156);
        //_setAssetsAggregator(ALPHA ,0x7B0ca9A6D03FE0467A31Ca850f5bcA51e027B3aF);
        //_setAssetsAggregator(AAVE ,0x3CA13391E9fb38a75330fb28f8cc2eB3D9ceceED);
        //_setAssetsAggregator(BTC ,0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743);
        //_setAssetsAggregator(BUSD ,0x827f8a0dC5c943F7524Dda178E2e7F275AAd743f);
        //_setAssetsAggregator(CAKE ,0x79bD0EDd79dB586F22fF300B602E85a662fc1208);
        //_setAssetsAggregator(CHF ,0x3B37950485b450edF90cBB85d0cD27308Af4AB9A);
        //_setAssetsAggregator(DAI ,0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300);
        //_setAssetsAggregator(EPS ,0xB3ace8467271D12D8216818Dd2E8F84Cb6F9c212);
        //_setAssetsAggregator(ETH ,0x976B3D034E162d8bD72D6b9C989d545b839003b0);
        //_setAssetsAggregator(LINK ,0x49ccd9ca821EfEab2b98c60dC60F518E765EDe9a);
        //_setAssetsAggregator(LUNA ,0x12Fe6A4DF310d4aD9887D27D4fce45a6494D4a4a);
        //_setAssetsAggregator(MDX ,0x6131b26D4aD63004df7540a3B3031072273f003e);
        //_setAssetsAggregator(MIM ,0x54EdAB30a7134A16a54218AE64C73e1DAf48a8Fb);
        //_setAssetsAggregator(OHM ,0x0c40Be7D32311b36BE365A2A220243B8A651df5E);
        //_setAssetsAggregator(SPELL ,0x4F3ddF9378a4865cf4f28BE51E10AECb83B7daeE);
        //_setAssetsAggregator(SUSHI ,0x449A373A090d8A1e5F74c63Ef831Ceff39E94563);
        //_setAssetsAggregator(TRY ,0xA61bF273688Ea095b5e4c11f1AF5E763F7aEEE91);
        //_setAssetsAggregator(TUSD ,0x9Cf3Ef104A973b351B2c032AA6793c3A6F76b448);
        //_setAssetsAggregator(UNI ,0x9a1372f9b1B71B3A5a72E092AE67E172dBd7Daaa);
        //_setAssetsAggregator(USDC ,0xF096872672F44d6EBA71458D74fe67F9a77a23B9);
        //_setAssetsAggregator(USDT ,0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a);
    }
}