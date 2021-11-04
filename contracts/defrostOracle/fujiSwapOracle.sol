/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "./swapOracle.sol";
contract fujiSwapOracle is swapOracle {
    constructor(address multiSignature,address origin0,address origin1)
    chainLinkOracle(multiSignature,origin0,origin1) {
        _setAssetsAggregator(0x9a25b9C20520682eF2e82641934B9d44B1bEbAb9,0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
        _setAssetsAggregator(0x4D32Aa832043a8d894cE53363eB45B575DAEB39C ,0x31CF013A08c6Ac228C94551d535d5BAfE19c602a);
        _setAssetsAggregator(0xf66E44c9bA658c29D08f43F3D4d69704fF527149 ,0x86d67c3D38D2bCeE722E601025C25a575021c6EA);
        _setAssetsAggregator(0x5E2eeB9e21C490dE6e5f7661ccB1E1eecA6dE207 ,0x7898AcCC83587C3C55116c5230C17a6Cd9C71bad);
        _setAssetsAggregator(0x52c34Aaa4FDB961C5084218fabc80ee9f61EF98b ,0x7898AcCC83587C3C55116c5230C17a6Cd9C71bad);
    }
}