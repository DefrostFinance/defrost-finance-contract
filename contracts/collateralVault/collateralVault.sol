// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
import "./vaultEngine.sol";
contract collateralVault is vaultEngine {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    constructor (address multiSignature,bytes32 _vaultID,address _collateralToken,address _reservePool,address _systemCoin,address _dsOracle) proxyOwner(multiSignature){
        vaultID = _vaultID;
        collateralToken = _collateralToken;
        reservePool = _reservePool;
        systemCoin = ISystemCoin(_systemCoin);
        _oracle = IDSOracle(_dsOracle);
    }
    function initContract(uint256 _stabilityFee,uint256 _feeInterval,uint256 _assetCeiling,uint256 _assetFloor,
        uint256 _collateralRate,uint256 _liquidationReward,uint256 _liquidationPenalty)external onlyOwner{
        interestRate = _stabilityFee;
        interestInterval = _feeInterval;
        assetCeiling = _assetCeiling;
        assetFloor = _assetFloor;
        collateralRate = _collateralRate;
        liquidationReward = _liquidationReward;
        liquidationPenalty = _liquidationPenalty;
        latestSettleTime = block.timestamp;
        accumulatedRate = rayDecimals;
    }
    /**
    * @notice Join collateral in the system
    * @dev This function locks collateral in the adapter and creates a 'representation' of
    *      the locked collateral inside the system. This adapter assumes that the collateral
    *      has 18 decimals
    * @param account Account from which we transferFrom collateral and add it in the system
    * @param amount Amount of collateral to transfer in the system
    **/

    function join(address account, uint256 amount) notHalted payable external {
        _join(account,amount);
    }
    function _join(address account, uint256 amount) internal {
        collateralBalances[account] = collateralBalances[account].add(amount);
        amount = getPayableAmount(collateralToken,amount);
        emit Join(msg.sender, account, amount);
    }    
    /**
    * @notice Exit collateral from the system
    * @dev This function destroys the collateral representation from inside the system
    *      and exits the collateral from this adapter. The adapter assumes that the collateral
    *      has 18 decimals
    * @param account Account to which we transfer the collateral
    * @param amount Amount of collateral to transfer to 'account'
    **/
    function exit(address account, uint256 amount) notHalted settleAccount(msg.sender) external {
        require(checkLiquidate(msg.sender,0,amount),"collateral remove overflow!");
        collateralBalances[msg.sender] = collateralBalances[msg.sender].sub(amount);
        _redeem(account,collateralToken,amount);
        emit Exit(msg.sender, account, amount);
    }
    function getMaxBorrowAmount(address account,uint256 newAddCollateral) external view returns(uint256){
        uint256 allDebt =getAssetBalance(account);
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 newMint = collateralBalances[account].add(newAddCollateral).mul(collateralPrice)/collateralRate;
        if (newMint>allDebt){
            return newMint - allDebt;
        }
        return 0;
    }
    function mintSystemCoin(address account, uint256 amount) notHalted external{
        _mintSystemCoin(account,amount);
    }
    function _mintSystemCoin(address account, uint256 amount) settleAccount(msg.sender) internal{
        require(checkLiquidate(msg.sender,0,amount),"overflow liquidation limit!");
        systemCoin.mint(account,amount);
        addAsset(msg.sender,amount);
        emit MintSystemCoin(msg.sender,account,amount);
    }
    function joinAndMint(uint256 collateralamount, uint256 systemCoinAmount)payable notHalted settleAccount(msg.sender) external{
        _join(msg.sender,collateralamount);
        _mintSystemCoin(msg.sender,systemCoinAmount);
    }
    function repaySystemCoin(address account, uint256 amount) notHalted settleAccount(account) external{
        if(amount == uint256(-1)){
            amount = assetInfoMap[account].assetAndInterest;
        }
        _repaySystemCoin(account,amount);
        emit RepaySystemCoin(msg.sender,account,amount);
    }
    function _repaySystemCoin(address account, uint256 amount) internal{
        uint256 _repayDebt = subAsset(account,amount);
        require(systemCoin.transferFrom(msg.sender, reservePool, amount.sub(_repayDebt)),"systemCoin : transferFrom failed!");
        systemCoin.burn(msg.sender,_repayDebt);
        emit RepaySystemCoin(msg.sender,account,amount);
    }
    function liquidate(address account) notHalted settleAccount(account) external{        
        require(!checkLiquidate(account,0,0),"liquidation check error!");
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 collateral = collateralBalances[account];
        uint256 allDebt = assetInfoMap[account].assetAndInterest;
        uint256 punish = allDebt.mul(liquidationPenalty)/calDecimals;
        IERC20 oToken = IERC20(address(systemCoin));
        _repaySystemCoin(account,allDebt);
        oToken.safeTransferFrom(msg.sender, reservePool, punish);
        allDebt += punish;
        uint256 _payback = allDebt.mul(calDecimals+liquidationReward)/collateralPrice;
        _payback = _payback <= collateral ? _payback : collateral;
        collateralBalances[account] = collateralBalances[account].sub(_payback);
        _redeem(msg.sender,collateralToken,_payback);
        emit Liquidate(msg.sender,account,collateralToken,allDebt,punish,_payback);
        
    }
}