// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface ICurveGaugeBTCETH {
    function deposit(uint256 _value) external;
    function claim_rewards(address to)external;
}
interface ICurvePoolBTCETH {
    function add_liquidity(uint256[5] calldata _amounts, uint256 _min_mint_amount)external;
}