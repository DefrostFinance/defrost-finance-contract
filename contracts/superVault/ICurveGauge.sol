// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface ICurveGauge {
    function deposit(uint256 _value) external;
    function claim_rewards()external;
}
interface ICurvePool{
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount, bool _use_underlying)external returns (uint256);
}