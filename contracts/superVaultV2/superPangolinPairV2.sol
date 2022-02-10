// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superTokenV2.sol";
import "../interface/IMiniChefV2.sol";
import "../uniswap/IUniswapV2Pair.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superPangolinPairV2 is superTokenV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public LPToken0;
    address public LPToken1;
    IMiniChefV2 public constant miniChef = IMiniChefV2(0x1f806f7C8dED893fd3caE279191ad7Aa3798E928);
    uint256 public poolId;
    bool public bEmergencyWithdraw = false;
    event EmergencyWithdraw(address indexed from);
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool,uint256 _poolId)
            superTokenV2(multiSignature,origin0,origin1,_stakeToken,_dsOracle,_FeePool) {
        poolId = _poolId;
        swapRouter = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
        IERC20(_stakeToken).safeApprove(address(miniChef), uint(-1));
        IERC20(LPToken0).safeApprove(address(swapRouter),uint256(-1));
        IERC20(LPToken1).safeApprove(address(swapRouter),uint256(-1));
    }
    function setTokenErc20() internal override{
        IUniswapV2Pair pair = IUniswapV2Pair(address(stakeToken));
        LPToken0 = pair.token0();
        LPToken1 = pair.token1();
        string memory tokenName_ = string(abi.encodePacked("Super Pangolin LP ",IERC20(LPToken0).name()," & ",IERC20(LPToken1).name()));
        string memory symble_ = string(abi.encodePacked("SPLP-",IERC20(LPToken0).symbol(), "-" ,IERC20(LPToken1).symbol()));
        setErc20Info(tokenName_,symble_,IERC20(stakeToken).decimals());
    }
    function deposit(address account,uint256 _amount)internal override{
                // Lock the stakeToken in the contract
        stakeToken.safeTransferFrom(account, address(this), _amount);
        if(!bEmergencyWithdraw){
            miniChef.deposit(poolId,_amount,address(this));
        }
    }
    function withdraw(address account,uint256 _amount)internal override{
        if(!bEmergencyWithdraw){
            miniChef.withdraw(poolId,_amount,account);
        }else{
            stakeToken.safeTransfer(account, _amount);
        }
    }
    function stakeBalance()public view override returns (uint256){
        if(!bEmergencyWithdraw){
            (uint amount,) = miniChef.userInfo(poolId,address(this));
            return amount;
        }else{
            return stakeToken.balanceOf(address(this));
        }
    }
    function emergencyWithdraw()external onlyOrigin {
        require(!bEmergencyWithdraw,"superPangolinPairV2 : supervault has been emergency withdrawn!");
        bEmergencyWithdraw = true;
        miniChef.emergencyWithdraw(poolId, address(this));
        emit EmergencyWithdraw(msg.sender);        
    }
    function compound() external{
        require(!bEmergencyWithdraw,"superPangolinPairV2 : supervault has been emergency withdrawn!");
        latestCompoundTime = block.timestamp;
        miniChef.harvest(poolId,address(this));
        uint nLen = rewardInfos.length;
        for (uint i=0;i<nLen;i++){
            rewardInfo memory info = rewardInfos[i];
            if(info.bClosed){
                continue;
            }
            swapPair(info.rewardToken,info.sellLimit);
        }
        uint256 balance0 = IERC20(LPToken0).balanceOf(address(this));
        uint256 balance1 = IERC20(LPToken1).balanceOf(address(this));
        if (balance0>0 && balance1>0){
            uint256 fee = balance0.mul(feeRate)/10000;
            IERC20(LPToken0).safeTransfer(FeePool,fee);
            balance0 = balance0.sub(fee);
            fee = balance1.mul(feeRate)/10000;
            IERC20(LPToken1).safeTransfer(FeePool,fee);
            balance1 = balance1.sub(fee);
            IJoeRouter01(swapRouter).addLiquidity(LPToken0, LPToken1, balance0, balance1,0,0, address(this), block.timestamp+30);
            balance0 = IERC20(stakeToken).balanceOf(address(this));
            miniChef.deposit(poolId,balance0,address(this));
        }
    }
    function swapPair(address token,uint256 sellLimit)internal{
        uint256 balance = (token != address(0)) ? IERC20(token).balanceOf(address(this)) : address(this).balance;
        if (balance < sellLimit){
            return;
        }
        swapOnDex(token,LPToken0,balance/2);
        swapOnDex(token,LPToken1,balance/2);
    }
    function getStakeTokenPrice() public override view returns (uint256) {
        IUniswapV2Pair upair = IUniswapV2Pair(address(stakeToken));
        (uint112 reserve0, uint112 reserve1,) = upair.getReserves();
        (bool have0,uint256 price0) = oraclePrice(upair.token0());
        (bool have1,uint256 price1) = oraclePrice(upair.token1());
        uint256 totalAssets = 0;
        if(have0 && have1){
            price0 *= reserve0;  
            price1 *= reserve1;
            totalAssets = price0+price1;
            uint256 total = upair.totalSupply();
            if (total == 0){
                return 0;
            }
            return totalAssets/total;
        }else{
            return 0;
        }
    }
}