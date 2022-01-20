// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superTokenV2.sol";
import "../superVault/traderJoe/IMasterChefJoeV2.sol";
import "../uniswap/IUniswapV2Pair.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superPairV2 is superTokenV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public LPToken0;
    address public LPToken1;
    IMasterChefJoeV2 public constant masterChefJoe = IMasterChefJoeV2(0xd6a4F121CA35509aF06A0Be99093d08462f53052);
    uint256 public poolId;
    address public constant joeToken = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;

    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool,uint256 _poolId)
            superTokenV2(multiSignature,origin0,origin1,_stakeToken,_dsOracle,_FeePool) {
        poolId = _poolId;
        IUniswapV2Pair pair = IUniswapV2Pair(_stakeToken);
        LPToken0 = pair.token0();
        LPToken1 = pair.token1();
        string memory tokenName_ = string(abi.encodePacked("Super LP ",IERC20(LPToken0).name()," & ",IERC20(LPToken1).name()));
        string memory symble_ = string(abi.encodePacked("SLP-",IERC20(LPToken0).symbol(), "-" ,IERC20(LPToken1).symbol()));
        setErc20Info(tokenName_,symble_,IERC20(_stakeToken).decimals());
        IERC20(LPToken0).safeApprove(address(traderJoe),uint256(-1));
        IERC20(LPToken1).safeApprove(address(traderJoe),uint256(-1));
        setJoeTokenPath(LPToken0);
        setJoeTokenPath(LPToken1);
    }
    function setTokenErc20() internal override{
        string memory tokenName_ = string(abi.encodePacked("Super LP ",IERC20(LPToken0).name()," & ",IERC20(LPToken1).name()));
        string memory symble_ = string(abi.encodePacked("SLP-",IERC20(LPToken0).symbol(), "-" ,IERC20(LPToken1).symbol()));
        setErc20Info(tokenName_,symble_,IERC20(stakeToken).decimals());
    }
    function deposit(address account,uint256 _amount)internal override{
                // Lock the stakeToken in the contract
        stakeToken.safeTransferFrom(account, address(this), _amount);
        masterChefJoe.deposit(poolId,_amount);
    }
    function withdraw(address account,uint256 _amount)internal override{
        masterChefJoe.withdraw(poolId,_amount);
        stakeToken.safeTransfer(account, _amount);
    }
    function stakeBalance()public view override returns (uint256){
        (uint amount,) = masterChefJoe.userInfo(poolId,address(this));
        return amount;
    }
    function setJoeTokenPath(address _token) internal {
        if(_token != WAVAX){
            swapRoutingPath[joeToken][_token] = new address[](3);
            swapRoutingPath[joeToken][_token][0] = joeToken;
            swapRoutingPath[joeToken][_token][1] = WAVAX;
            swapRoutingPath[joeToken][_token][2] = _token;
        }
    }
    function compound() external{
        latestCompoundTime = block.timestamp;
        masterChefJoe.deposit(poolId,0);
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
            IJoeRouter01(traderJoe).addLiquidity(LPToken0, LPToken1, balance0, balance1,0,0, address(this), block.timestamp+30);
            balance0 = IERC20(stakeToken).balanceOf(address(this));
            masterChefJoe.deposit(poolId,balance0);
        }
    }
    function swapPair(address token,uint256 sellLimit)internal{
        uint256 balance = (token != address(0)) ? IERC20(token).balanceOf(address(this)) : address(this).balance;
        if (balance < sellLimit){
            return;
        }
        swapTraderJoe(token,LPToken0,balance/2);
        swapTraderJoe(token,LPToken1,balance/2);
    }
}