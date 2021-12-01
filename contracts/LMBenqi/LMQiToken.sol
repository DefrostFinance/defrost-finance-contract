// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./ERC20.sol";
import "./IBenqiCompound.sol";
import "../modules/IERC20.sol";
import "../modules/SafeMath.sol";
import "../modules/safeErc20.sol";
import "../interface/ICToken.sol";
import "../modules/proxyOwner.sol";
import "../uniswap/IJoeRouter01.sol";
// qiTokenBar is the coolest bar in town. You come in with some qiToken, and leave with more! The longer you stay, the more qiToken you get.
//
// This contract handles swapping to and from xqiToken, qiTokenSwap's staking token.
contract LMQiToken is ERC20,proxyOwner {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IERC20 public qiToken;
    address public underlying;
    address payable public FeePool;
    uint256 public feeRate = 1e3;    //1e4
    uint256 public slipRate = 9500;
    struct rewardInfo {
        uint8 rewardType;
        bool bClosed;
        address rewardToken;
        uint256 sellLimit;
    }
    rewardInfo[] public rewardInfos;
    mapping(address=>address[]) public swapRoutingPath;
    IBenqiCompound public compounder = IBenqiCompound(0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4);
    address public traderJoe = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address public WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    event SetReward(address indexed from, uint256 index,uint8 _reward,bool _bClosed,address _rewardToken,uint256 _sellLimit);
    event SetFeePoolAddress(address indexed from,address _feePool);
    event SetSlipRate(address indexed from,uint256 _slipRate);
    event SetFeeRate(address indexed from,uint256 _feeRate);
    event SetSwapRoutingPath(address indexed from,address indexed token,address[] swapPath);
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address payable _FeePool)
            proxyOwner(multiSignature,origin0,origin1) {
        FeePool = _FeePool;
        _setReward(0,0,false,0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5,1e17);
        _setReward(1,1,false,address(0),1e15);
    }
    receive() external payable {
        // React to receiving ether
    }
    function getSwapRouterPath(address token)public view returns (address[] memory path){
        path = swapRoutingPath[token];
        if (path.length > 1){
            return path;
        }
        path = new address[](2);
        path[0] = token == address(0) ? WAVAX : token;
        path[1] = underlying == address(0) ? WAVAX : underlying;
    }
    // Enter the bar. Pay some qiTokens. Earn some shares.
    // Locks qiToken and mints xqiToken
    function enter(uint256 _amount) public {
        // Gets the amount of qiToken locked in the contract
        uint256 totalqiToken = qiToken.balanceOf(address(this));
        // Gets the amount of xqiToken in existence
        uint256 totalShares = totalSupply();
        // If no xqiToken exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalqiToken == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xqiToken the qiToken is worth. The ratio will change overtime, as xqiToken is burned/minted and qiToken deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalqiToken);
            _mint(msg.sender, what);
        }
        // Lock the qiToken in the contract
        qiToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your qiTokens.
    // Unlocks the staked + gained qiToken and burns xqiToken
    function leave(uint256 _share) public {
        // Gets the amount of xqiToken in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of qiToken the xqiToken is worth
        uint256 what = _share.mul(qiToken.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        qiToken.safeTransfer(msg.sender, what);
    }
    function setFeePoolAddress(address payable feeAddress)external onlyOrigin notZeroAddress(feeAddress){
        FeePool = feeAddress;
        emit SetFeePoolAddress(msg.sender,feeAddress);
    }
    function setSlipRate(uint256 _slipRate) external onlyOrigin{
        require(_slipRate < 5000,"slipRate out of range!");
        slipRate = _slipRate;
        emit SetSlipRate(msg.sender,_slipRate);
    }
    function setFeeRate(uint256 _feeRate) external onlyOrigin{
        require(_feeRate < 5000,"feeRate out of range!");
        feeRate = _feeRate;
        emit SetFeeRate(msg.sender,_feeRate);
    }
    function setSwapRoutingPath(address token,address[] calldata swapPath) external onlyOrigin {
        swapRoutingPath[token] = swapPath;
        SetSwapRoutingPath(msg.sender,token,swapPath);
    }
    function setReward(uint256 index,uint8 _reward,bool _bClosed,address _rewardToken,uint256 _sellLimit)  external onlyOrigin {
        _setReward(index,_reward,_bClosed,_rewardToken,_sellLimit);
    }
    function _setReward(uint256 index,uint8 _reward,bool _bClosed,address _rewardToken,uint256 _sellLimit) internal{
        if(index <rewardInfos.length){
            rewardInfo storage info = rewardInfos[index];
            info.rewardType = _reward;
            info.bClosed = _bClosed;
            info.rewardToken = _rewardToken;
            info.sellLimit = _sellLimit;
        }else{
            rewardInfos.push(rewardInfo(_reward,_bClosed,_rewardToken,_sellLimit));
            if(_rewardToken != address(0)){
                SafeERC20.safeApprove(IERC20(_rewardToken), traderJoe, uint(-1));
            }
        }
        emit SetReward(msg.sender,index,_reward,_bClosed,_rewardToken,_sellLimit);
    }
    modifier notZeroAddress(address inputAddress) {
        require(inputAddress != address(0), "LMQiToken : input zero address");
        _;
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