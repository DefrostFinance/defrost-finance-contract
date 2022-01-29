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
interface IAnkrAVAXb{
    function ratio() external view returns (uint256);
}
contract superAnkrAVAX is ERC20,ImportOracle,ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IERC20 public stakeToken;
    uint256 public enterFee = 5e15;
    uint256 public leaveFee = 0;
    uint256 constant calDecimals = 1e18;
    IERC20 public melt = IERC20(0x47EB6F7525C1aA999FBC9ee92715F5231eB1241D);
    address public constant meltFeePool = address(1);

    event SetMeltFee(address indexed from,uint256 _enterFee,uint256 leaveFee);
    // Define the stakeToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle)
            proxyOwner(multiSignature,origin0,origin1) {
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
        stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 radio = IAnkrAVAXb(address(stakeToken)).ratio();
        uint256 what = _amount.mul(radio)/calDecimals;
        _mint(msg.sender, what);
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
        stakeToken.safeTransfer(msg.sender, what);
        transferMeltFee(msg.sender,_getMeltFee(leaveFee,what));
    }
    function _getMeltFee(uint256 rate,uint256 enterAmount) internal view returns (uint256){
        if(rate > 0){
            uint256 price = getStakeTokenPrice();
            uint256 usdAmount = enterAmount.mul(price)/calDecimals;
            return usdAmount.mul(rate)/calDecimals;
        }
        return 0;
    }
    function getStakeTokenPrice() public view virtual returns (uint256) {
        (,uint256 price) = oraclePrice(address(stakeToken));
        return price;
    }
    function getEnterMeltFee(uint256 enterAmount) external view returns (uint256){
        return _getMeltFee(enterFee,enterAmount);
    }
    function getLeaveMeltFee(uint256 leaveAmount) external view returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 totalstakeToken = stakeBalance();
        // Calculates the amount of stakeToken the superToken is worth
        if (totalShares > 0){
            uint256 what = leaveAmount.mul(totalstakeToken).div(totalShares);
            return _getMeltFee(leaveFee,what);
        }else{
            return _getMeltFee(leaveFee,leaveAmount);
        }
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
}