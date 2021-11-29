pragma solidity >=0.7.0 <0.8.0;
import "../modules/SafeMath.sol";
import "../modules/SafeERC20.sol";
contract SMelt {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

        //Special decimals for calculation
    uint256 constant internal rayDecimals = 1e27;

    //interest rate
    int256 internal interestRate;
    uint256 internal interestInterval;
        // latest time to settlement
    uint256 internal latestSettleTime;
    uint256 internal accumulatedRate;
    IERC20 Melt;
        /**
     * @dev retrieve Interest informations.
     * @return distributed Interest rate and distributed time interval.
     */
    function getInterestInfo()external view returns(int256,uint256){
        return (interestRate,interestInterval);
    }

    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     * @param _interestRate mineCoin distributed amount
     * @param _interestInterval mineCoin distributied time interval
     */
    function _setInterestInfo(int256 _interestRate,uint256 _interestInterval,uint256 maxRate,uint256 minRate)internal {
        if (accumulatedRate == 0){
            accumulatedRate = rayDecimals;
        }
        require(_interestRate<=1e27 && _interestRate>=-1e27,"input stability fee is too large");
        require(_interestInterval>0,"input mine Interval must larger than zero");
        uint256 newLimit = rpower(uint256(1e27+_interestRate),31536000/_interestInterval,rayDecimals);
        require(newLimit<=maxRate && newLimit>=minRate,"input stability fee is out of range");
        _interestSettlement();
        interestRate = _interestRate;
        interestInterval = _interestInterval;
        emit SetInterestInfo(msg.sender,_interestRate,_interestInterval);
    }
    function enter(uint256 amount){
        _interestSettlement();
        Melt.safeTransferFrom(msg.sender,address(this),amount);
        uint256 smelt = amount.mul(rayDecimals)/accumulatedRate;
        mint(msg.sender,smelt);
    }
    function leave(uint256 amount){
        _interestSettlement();
        uint256 melt = amount.mul(accumulatedRate)/rayDecimals;
        burn(msg.sender,amount);
        Melt.safeTransfer(msg.sender,melt);
    }
    function _interestSettlement()internal{
        uint256 _interestInterval = interestInterval;
        if (_interestInterval>0){
            uint256 newRate = newAccumulatedRate();
            accumulatedRate = newRate;
            latestSettleTime = currentTime()/_interestInterval*_interestInterval;
        }else{
            latestSettleTime = currentTime();
        }
    }
    function newAccumulatedRate()internal virtual view returns (uint256){
        uint256 newRate = rpower(uint256(1e27+interestRate),(currentTime()-latestSettleTime)/interestInterval,rayDecimals);
        return accumulatedRate.mul(newRate)/rayDecimals;
    }
    function currentTime() internal virtual view returns (uint256){
        return block.timestamp;
    }
}