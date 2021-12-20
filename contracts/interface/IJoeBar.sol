// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface IJoeBar {
    function enter(uint256 _amount) external;
    // Leave the bar. Claim back your JOEs.
    // Unlocks the staked + gained Joe and burns xJoe
    function leave(uint256 _share) external;
}