// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "../ERC20.sol";
import "../../modules/IERC20.sol";
import "../../modules/SafeMath.sol";
import "../../modules/safeErc20.sol";
import "../../uniswap/IJoeRouter01.sol";
import "../../modules/ReentrancyGuard.sol";
import "../../interface/IDSOracle.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superBase is ERC20,ImportOracle,ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IERC20 public stakeToken;
    address payable public FeePool;
    uint256 public slipRate = 9500;
    uint256 public feeRate = 2e3;    //1e4
    uint256 public latestCompoundTime;
    mapping(address=>mapping(address=>address[])) public swapRoutingPath;
    struct rewardInfo {
        uint8 rewardType;
        bool bClosed;
        address rewardToken;
        uint256 sellLimit;
    }
    rewardInfo[] public rewardInfos;
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant traderJoe = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;

    event SetFeePoolAddress(address indexed from,address _feePool);
    event SetSlipRate(address indexed from,uint256 _slipRate);
    event SetFeeRate(address indexed from,uint256 _feeRate);
    event SetSwapRoutingPath(address indexed from,address indexed token0,address indexed token1,address[] swapPath);
    event SetReward(address indexed from, uint256 index,uint8 _reward,bool _bClosed,address _rewardToken,uint256 _sellLimit);

    // Define the stakeToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool)
            proxyOwner(multiSignature,origin0,origin1) {
        FeePool = _FeePool;
        _oracle = IDSOracle(_dsOracle);
        stakeToken = IERC20(_stakeToken);
    }
    receive() external payable {
        // React to receiving ether
    }
    function setFeePoolAddress(address payable feeAddress)external onlyOrigin notZeroAddress(feeAddress){
        FeePool = feeAddress;
        emit SetFeePoolAddress(msg.sender,feeAddress);
    }
    function setSlipRate(uint256 _slipRate) external onlyOrigin{
        require(_slipRate < 10000,"slipRate out of range!");
        slipRate = _slipRate;
        emit SetSlipRate(msg.sender,_slipRate);
    }
    function setFeeRate(uint256 _feeRate) external onlyOrigin{
        require(_feeRate < 5000,"feeRate out of range!");
        feeRate = _feeRate;
        emit SetFeeRate(msg.sender,_feeRate);
    }
    function getSwapRouterPathInfo(address token0,address token1)public view returns (address[] memory path){
        path = swapRoutingPath[token0][token1];
        if (path.length > 1){
            return path;
        }
        path = new address[](2);
        path[0] = token0 == address(0) ? WAVAX : token0;
        path[1] = token1 == address(0) ? WAVAX : token1;
    }
    function setSwapRoutingPathInfo(address token0,address token1,address[] calldata swapPath) external onlyOrigin {
        swapRoutingPath[token0][token1] = swapPath;
        emit SetSwapRoutingPath(msg.sender,token0,token1,swapPath);
    }
    function getSwapMinAmountOut(address tokenIn,address tokenOut,uint256 amountIn)internal view returns(uint256){
        address[] memory assets = new address[](2);
        assets[0] = tokenIn;
        assets[1] = tokenOut;
        uint256[]memory prices = _oracle.getPrices(assets);
        if (prices[0]>0 && prices[1]>0){
            return amountIn.mul(prices[0]).mul(slipRate)/prices[1]/1e4;
        }
        return 0;
    }
    modifier notZeroAddress(address inputAddress) {
        require(inputAddress != address(0), "superToken : input zero address");
        _;
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
}