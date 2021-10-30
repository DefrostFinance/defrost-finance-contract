// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface ICoinMinePool {
//    function transferMinerCoin(address account,address recieptor)external;
    function changeUserbalance(address account,int256 amount) external;
}
