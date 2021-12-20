// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superBase.sol";
import "./IMasterChefJoeV2.sol";
import "../../uniswap/IUniswapV2Pair.sol";
import "../../interface/IJoeBar.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superXJoe is superBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IMasterChefJoeV2 public constant masterChefJoe = IMasterChefJoeV2(0xd6a4F121CA35509aF06A0Be99093d08462f53052);
    uint256 public constant poolId = 24;
    address public constant joeToken = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
    IJoeBar public xJoe = IJoeBar(0x57319d41F71E81F3c65F2a47CA4e001EbAFd4F33);
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool)
            superBase(multiSignature,origin0,origin1,_stakeToken,_dsOracle,_FeePool) {

        string memory tokenName_ = string(abi.encodePacked("Super ",IERC20(_stakeToken).name()));
        string memory symble_ = string(abi.encodePacked("S",IERC20(_stakeToken).symbol()));
        setErc20Info(tokenName_,symble_,IERC20(_stakeToken).decimals());
        IERC20(_stakeToken).safeApprove(address(masterChefJoe), uint(-1));
        IERC20(joeToken).safeApprove(address(xJoe),uint256(-1));
        _setReward(0,0,false,joeToken,1e17);
    }
    function stakeBalance()internal view returns (uint256){
        (uint amount,) = masterChefJoe.userInfo(poolId,address(this));
        return amount;
    }
    // Enter the bar. Pay some stakeTokens. Earn some shares.
    // Locks stakeToken and mints superToken
    function enter(uint256 _amount) external nonReentrant {
        // Gets the amount of stakeToken locked in the contract
        uint256 totalstakeToken = stakeBalance();
        // Gets the amount of superToken in existence
        uint256 totalShares = totalSupply();
        // If no superToken exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalstakeToken == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of superToken the stakeToken is worth. The ratio will change overtime, as superToken is burned/minted and stakeToken deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalstakeToken);
            _mint(msg.sender, what);
        }
        // Lock the stakeToken in the contract
        stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
        masterChefJoe.deposit(poolId,_amount);
    }
    // Leave the bar. Claim back your stakeTokens.
    // Unlocks the staked + gained stakeToken and burns superToken
    function leave(uint256 _share) external nonReentrant {
        // Gets the amount of superToken in existence
        uint256 totalShares = totalSupply();
        uint256 totalstakeToken = stakeBalance();
        // Calculates the amount of stakeToken the superToken is worth
        uint256 what = _share.mul(totalstakeToken).div(totalShares);
        _burn(msg.sender, _share);
        _withdraw(what);
        stakeToken.safeTransfer(msg.sender, what);
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
            swapJoe(info.rewardToken,info.sellLimit);
        }
        uint256 balance = IERC20(joeToken).balanceOf(address(this));
        if (balance > 0){
            uint256 fee = balance.mul(feeRate)/10000;
            IERC20(joeToken).safeTransfer(FeePool,fee);
            balance = balance.sub(fee);
            xJoe.enter(balance);
            balance = IERC20(stakeToken).balanceOf(address(this));
            masterChefJoe.deposit(poolId,balance);
        }
    }
    function _withdraw(uint256 _amount)internal {
        masterChefJoe.withdraw(poolId,_amount);
    }
    function swapJoe(address token,uint256 sellLimit)internal{
        uint256 balance = (token != address(0)) ? IERC20(token).balanceOf(address(this)) : address(this).balance;
        if (balance < sellLimit){
            return;
        }
        swapTraderJoe(token,joeToken,balance);
//        swapTraderJoe(token,LPToken1,balance/2);
    }
    function swapTraderJoe(address token0,address token1,uint256 balance)internal{
        if(token0 == token1){
            return;
        }
        uint256 minOut = getSwapMinAmountOut(token0,token1,balance);
        address[] memory path = getSwapRouterPathInfo(token0,token1);
        if (token0 == address(0)){
            IJoeRouter01(traderJoe).swapExactAVAXForTokens{value : balance}(minOut,path,address(this),block.timestamp+30);
        }else{
            if (token1 == address(0)){
                IJoeRouter01(traderJoe).swapExactTokensForAVAX(balance,minOut,path,address(this),block.timestamp+30);
            }else{
                IJoeRouter01(traderJoe).swapExactTokensForTokens(balance,minOut,path,address(this),block.timestamp+30);
            }
        }
    }
    modifier isAuthorized {
        require(isOrigin(), "global Oracle/account-not-authorized");
        _;
    }
    /**
     * @dev Withdraw asset.
     * @param _assetAddress Asset to be withdrawn.
     */
    function withdraw(address _assetAddress) public isAuthorized {
        uint assetBalance;
        if (_assetAddress == address(0)) {
            address self = address(this); // workaround for a possible solidity bug
            assetBalance = self.balance;
            msg.sender.transfer(assetBalance);
        } else {
            assetBalance = IERC20(_assetAddress).balanceOf(address(this));
            IERC20(_assetAddress).safeTransfer(msg.sender, assetBalance);
        }
    }
}