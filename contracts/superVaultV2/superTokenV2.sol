// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "../superVault/ERC20.sol";
import "../modules/IERC20.sol";
import "../modules/SafeMath.sol";
import "../modules/safeErc20.sol";
import "../uniswap/IJoeRouter01.sol";
import "../modules/ReentrancyGuard.sol";
import "../interface/IDSOracle.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superTokenV2 is ERC20,ImportOracle,ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IERC20 public stakeToken;
    address payable public FeePool;
    uint256 public slipRate = 9500;
    uint256 public feeRate = 2e3;    //1e4
    uint256 public enterFee;
    uint256 public leaveFee;
    uint256 public latestCompoundTime;
    uint256 constant calDecimals = 1e18;
    mapping(address=>mapping(address=>address[])) public swapRoutingPath;
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant traderJoe = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    IERC20 public melt = IERC20(0x47EB6F7525C1aA999FBC9ee92715F5231eB1241D);
    address public constant meltFeePool = 0x286F1738D74E6C1005c802C0686bb81796Fd5318;

    struct rewardInfo {
        uint8 rewardType;
        bool bClosed;
        address rewardToken;
        uint256 sellLimit;
    }
    rewardInfo[] public rewardInfos;

    event SetMeltFee(address indexed from,uint256 _enterFee,uint256 leaveFee);
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
        setTokenErc20();
    }
    function setTokenErc20() internal virtual{
        address _stakeToken = address(stakeToken);
        string memory tokenName_ = string(abi.encodePacked("Super ",IERC20(_stakeToken).name()));
        string memory symble_ = string(abi.encodePacked("S",IERC20(_stakeToken).symbol()));
        setErc20Info(tokenName_,symble_,IERC20(_stakeToken).decimals());
    }
    function deposit(address account,uint256 _amount)internal virtual{
        stakeToken.safeTransferFrom(account, address(this), _amount);
    }
    function withdraw(address account,uint256 _amount)internal virtual{
        stakeToken.safeTransfer(account, _amount);
    }
    function stakeBalance()public virtual view returns (uint256){
        return stakeToken.balanceOf(address(this));
    }
    receive() external payable {
        // React to receiving ether
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
        deposit(msg.sender,_amount);
        transferMeltFee(msg.sender,_getMeltFee(enterFee,_amount));
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
        withdraw(msg.sender, what);
        transferMeltFee(msg.sender,_getMeltFee(leaveFee,what));
    }
    function _getMeltFee(uint256 rate,uint256 enterAmount) internal view returns (uint256){
        if(rate > 0){
            (,uint256 price) = _oracle.getPriceInfo(address(stakeToken));
            uint256 usdAmount = enterAmount.mul(price)/calDecimals;
            return usdAmount.mul(rate)/calDecimals;
        }
        return 0;
    }
    function getEnterMeltFee(uint256 enterAmount) external view returns (uint256){
        return _getMeltFee(enterFee,enterAmount);
    }
    function getLeaveMeltFee(uint256 leaveAmount) external view returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 totalstakeToken = stakeBalance();
        // Calculates the amount of stakeToken the superToken is worth
        uint256 what = leaveAmount.mul(totalstakeToken).div(totalShares);
        return _getMeltFee(leaveFee,what);
    }
    function transferMeltFee(address account,uint256 _amount) internal{
        if(_amount > 0){
            melt.safeTransferFrom(account,meltFeePool, _amount);
        }
    }
    function setMeltFee(uint256 _enterFee,uint256 _leaveFee)external onlyOrigin{
        enterFee = _enterFee;
        leaveFee = _leaveFee;
        emit SetMeltFee(msg.sender,_enterFee,_leaveFee);
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