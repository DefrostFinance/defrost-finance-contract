pragma solidity =0.5.16;
interface ISystemToken {
    function decimals() external view returns (uint256);
    function transfer(address,uint256) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
    function mint(address,uint256) external;
    function burn(address,uint256) external;
    function setMinePool(address _MinePool) external;
}