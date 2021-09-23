pragma solidity =0.5.16;
import "../PhoenixModules/modules/SafeMath.sol";
import "./depositPoolData.sol";
/**
 * @title systemCoin deposit pool.
 * @dev Deposit systemCoin earn interest systemcoin.
 *
 */
contract depositPool is depositPoolData {
    using SafeMath for uint256;
    /**
     * @dev default function for foundation input miner coins.
     */
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }
    function update() public versionUpdate {
    }
    function initContract(address _systemToken,uint256 _interestRate,uint256 _interestInterval,
        uint256 _assetCeiling,uint256 _assetFloor)external originOnce{
        systemToken = ISystemToken(_systemToken);
        interestRate = _interestRate;
        interestInterval = _interestInterval;
        assetCeiling = _assetCeiling;
        assetFloor = _assetFloor;
        latestSettleTime = now;
        accumulatedRate = rayDecimals;
    }
    function()external payable{
        require(false);
    }
    function setInterestInfo(uint256 _interestRate,uint256 _interestInterval)external onlyOrigin{
        _setInterestInfo(_interestRate,_interestInterval);
    }
    function depositSystemCoin(address account, uint256 amount) notHalted OneBlockLimit(msg.sender) settleAccount(msg.sender) external{
        require(systemToken.transferFrom(msg.sender, address(this), amount),"systemToken : transferFrom failed!");
        addAsset(account,amount);
        emit Deposit(msg.sender,account,amount);
    }
    function withdrawSystemCoin(address account, uint256 amount) notHalted OneBlockLimit(msg.sender) settleAccount(msg.sender) external{
        if(amount == uint256(-1)){
            amount = assetInfoMap[account].assetAndInterest;
        }
        subAsset(msg.sender,amount);
        require(systemToken.transfer(account, amount),"systemToken : transfer failed!");
        emit Withdraw(msg.sender,account,amount);
    }
}