// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superTokenV2.sol";
import "./IStakeDao.sol";
import "../superVault/ICurveGauge.sol";
//
// This contract handles swapping to and from superStakeDaoV2
contract superStakeDaoV2 is superTokenV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public underlying = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    IMultiRewards public constant multiRewards = IMultiRewards(0x20fa7BDAC9bb235c7DE5232507eB963048E56B1E);
    ICurvePool public constant curvePool = ICurvePool(0x7f90122BF0700F9E7e1F688fe926940E8839F353);
    address public constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool)
            superTokenV2(multiSignature,origin0,origin1,_stakeToken,_dsOracle,_FeePool) {
        _setReward(0,0,false,0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,1e15);
        SafeERC20.safeApprove(IERC20(underlying), address(curvePool), uint(-1));
        SafeERC20.safeApprove(IERC20(av3Crv), address(stakeToken), uint(-1));
        IERC20(_stakeToken).safeApprove(address(multiRewards), uint(-1));
    }
    function getSwapRouterPath(address token)public view returns (address[] memory path){
        return getSwapRouterPathInfo(token,underlying);
    }
    function compound() external{
        latestCompoundTime = block.timestamp;
        multiRewards.getReward();
        uint nLen = rewardInfos.length;
        for (uint i=0;i<nLen;i++){
            rewardInfo memory info = rewardInfos[i];
            if(info.bClosed){
                continue;
            }
            swapTraderJoe(info.rewardToken,info.sellLimit);
        }
        IERC20 oToken = IERC20(underlying);
        uint256 balance = oToken.balanceOf(address(this));
        if (balance>0){
            uint256 fee = balance.mul(feeRate)/10000;
            oToken.safeTransfer(FeePool,fee);
            uint256[3] memory amounts = [0,balance.sub(fee),0]; 
            curvePool.add_liquidity(amounts,0,true);
            balance = IERC20(av3Crv).balanceOf(address(this));
            IVault(address(stakeToken)).deposit(balance);
            balance = stakeToken.balanceOf(address(this));
            multiRewards.stake(balance);
        }
    }
    function deposit(address account,uint256 _amount)internal override{
                // Lock the stakeToken in the contract
        stakeToken.safeTransferFrom(account, address(this), _amount);
        multiRewards.stake(_amount);
    }
    function withdraw(address account,uint256 _amount)internal override{
        multiRewards.withdraw(_amount);
        stakeToken.safeTransfer(account, _amount);
    }
    function stakeBalance()public view override returns (uint256){
        return multiRewards.balanceOf(address(this));
    }
    function swapTraderJoe(address token,uint256 sellLimit)internal{
        uint256 balance = (token != address(0)) ? IERC20(token).balanceOf(address(this)) : address(this).balance;
        if (balance < sellLimit){
            return;
        }
        swapTraderJoe(token,underlying,balance);
    }
    function getStakeTokenPrice() public override view returns (uint256) {
        uint256 priceRate = IVault(address(stakeToken)).getPricePerFullShare();
        //1 xjoe = balance(joe)/totalSuply joe
        (,uint256 price) = oraclePrice(av3Crv);
        return price.mul(priceRate)/calDecimals;
    }
}