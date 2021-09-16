pragma solidity =0.5.16;
interface ICoinMinePool {
    function transferMinerCoin(address account,address recieptor)external;
    function changeUserbalance(address account) external;
}
