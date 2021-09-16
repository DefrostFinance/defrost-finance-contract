pragma solidity =0.5.16;
import "../PhoenixModules/modules/SafeMath.sol";
import "./depositPoolData.sol";
/**
 * @title FPTCoin mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by FPTCoin balance.
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
        uint256 _assetCeiling,uint256 _assetFloor)external onlyOwner{
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
    function depositSystemCoin(address account, uint256 amount) notHalted OneBlockLimit(msg.sender) external{
        require(systemToken.transferFrom(msg.sender, address(this), amount),"systemToken : transferFrom failed!");
        addAsset(account,amount);
    }
    function repaySystemCoin(address account, uint256 amount) notHalted OneBlockLimit(msg.sender) external{
        subAsset(msg.sender,amount);
        require(systemToken.transfer(account, amount),"systemToken : transfer failed!");
    }
}