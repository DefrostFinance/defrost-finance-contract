// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
interface IMiniChefV2 {
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
    function userInfo(uint pid, address user) external view returns (
        uint amount,
        uint rewardDebt
    );
}