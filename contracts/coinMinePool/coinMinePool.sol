// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
import "./MinePoolData.sol";
import "../modules/SafeMath.sol";
/**
 * @title systemCoin mine pool, which manager contract is systemCoin.
 * @dev A smart-contract which distribute some mine coins by systemCoin balance.
 *
 */
contract coinMinePool is MinePoolData {
    using SafeMath for uint256;
    using whiteListAddress for address[];
    constructor (address multiSignature,address origin0,address origin1,address systemCoin) proxyOwner(multiSignature,origin0,origin1) {
        _operators[managerIndex] = systemCoin;
    }
    /**
     * @dev default function for foundation input miner coins.
     */
    receive()external payable{

    }
    /**
     * @dev foundation redeem out mine coins.
     * @param mineCoin mineCoin address
     * @param amount redeem amount.
     */
    function redeemOut(address mineCoin,uint256 amount)public onlyOrigin{
        _redeem(msg.sender,mineCoin,amount);
    }
    /**
     * @dev retrieve total distributed mine coins.
     * @param mineCoin mineCoin address
     */
    function getTotalMined(address mineCoin)public view returns(uint256){
        uint256 _totalSupply = totalSupply();
        uint256 _mineInterval = mineInterval[mineCoin];
        if (_totalSupply > 0 && _mineInterval>0){
            uint256 _mineAmount = mineAmount[mineCoin];
            uint256 latestMined = _mineAmount.mul(block.timestamp-latestSettleTime[mineCoin])/_mineInterval;
            return totalMinedCoin[mineCoin].add(latestMined);
        }
        return totalMinedCoin[mineCoin];
    }
    /**
     * @dev retrieve minecoin distributed informations.
     * @param mineCoin mineCoin address
     * @return distributed amount and distributed time interval.
     */
    function getMineInfo(address mineCoin)public view returns(uint256,uint256){
        return (mineAmount[mineCoin],mineInterval[mineCoin]);
    }
    /**
     * @dev retrieve user's mine balance.
     * @param account user's account
     * @param mineCoin mineCoin address
     */
    function getMinerBalance(address account,address mineCoin)public view returns(uint256){
        uint256 totalBalance = minerBalances[mineCoin][account];
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0){
            uint256 tokenNetWorth = _getCurrentTokenNetWorth(mineCoin);
            totalBalance= totalBalance.add(_settlement(mineCoin,account,tokenNetWorth));
        }
        return totalBalance;
    }
    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     * @param mineCoin mineCoin address
     * @param _mineAmount mineCoin distributed amount
     * @param _mineInterval mineCoin distributied time interval
     */
    function setMineCoinInfo(address mineCoin,uint256 _mineAmount,uint256 _mineInterval)public onlyOrigin {
        require(_mineAmount<1e30,"input mine amount is too large");
        require(_mineInterval>0,"input mine Interval must larger than zero");
        _globalSettlement(mineCoin);
        mineAmount[mineCoin] = _mineAmount;
        mineInterval[mineCoin] = _mineInterval;
        whiteList.addWhiteListAddress(mineCoin);
        emit SetMineCoinInfo(msg.sender,mineCoin,_mineAmount,_mineInterval);
    }
     /*
    /**
     * @dev transfer mineCoin to recieptor when account transfer amount FPTCoin to recieptor, only manager contract can modify database.
     * @param account the account transfer from
     * @param recieptor the account transfer to
     */
     /*
    function transferMinerCoin(address account,address recieptor) public onlyManager {
        _globalSettlementAll();
        _userSettlementAll(account);
        _userSettlementAll(recieptor);
        emit TranserMiner(account,recieptor);
    }
    */
    /**
     * @dev mint mineCoin to account when account add collateral to collateral pool, only manager contract can modify database.
     * @param account user's account
     */
    function changeUserbalance(address account,int256 amount) public onlyManager {
        _globalSettlementAll();
        _userSettlementAll(account);
        _changeBalance(account,amount);
        emit ChangeUserbalance(account,amount);
    }
    function _changeBalance(address account,int256 amount)internal{
        if (amount >= 0){
            distributeBalance[account] = distributeBalance[account].add(uint256(amount)); 
            _totalsupply = _totalsupply.add(uint256(amount)); 
        }else{
            distributeBalance[account] = distributeBalance[account].sub(uint256(-amount)); 
            _totalsupply = _totalsupply.sub(uint256(-amount));
        }
    }
    /**
     * @dev user redeem mine rewards.
     * @param mineCoin mine coin address
     */
    function redeemMinerCoin(address mineCoin)public nonReentrant notHalted {
        _globalSettlement(mineCoin);
        _userSettlement(mineCoin,msg.sender);
        uint256 minerAmount = minerBalances[mineCoin][msg.sender];
        require(minerAmount>0,"miner balance is zero");
        minerBalances[mineCoin][msg.sender] = 0;
        _redeem(msg.sender,mineCoin,minerAmount);
        emit RedeemMineCoin(msg.sender,mineCoin,minerAmount);
    }
    /**
     * @dev settle all mine coin.
     */    
    function _globalSettlementAll()internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            _globalSettlement(whiteList[i]);
        }
    }
    /**
     * @dev the auxiliary function for _mineSettlementAll.
     */    
    function _globalSettlement(address mineCoin)internal{
        uint256 _mineInterval = mineInterval[mineCoin];
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0 && _mineInterval>0){
            uint256 _mineAmount = mineAmount[mineCoin];
            uint256 mintTime = (block.timestamp-latestSettleTime[mineCoin])/_mineInterval;
            uint256 latestMined = _mineAmount*mintTime;
            mineNetworth[mineCoin] = mineNetworth[mineCoin].add(latestMined.mul(rayDecimals)/_totalSupply);
            latestSettleTime[mineCoin] = block.timestamp/_mineInterval*_mineInterval;
        }else{
            latestSettleTime[mineCoin] = block.timestamp;
        }
    }
    /**
     * @dev the auxiliary function for _mineSettlementAll. Calculate latest time phase distributied mine amount.
     */ 
    function _getLatestMined(address mineCoin)internal view returns(uint256){
        uint256 _mineInterval = mineInterval[mineCoin];
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0 && _mineInterval>0){
            uint256 _mineAmount = mineAmount[mineCoin];
            uint256 mintTime = (block.timestamp-latestSettleTime[mineCoin])/_mineInterval;
            uint256 latestMined = _mineAmount*mintTime;
            return latestMined;
        }
        return 0;
    }
    /**
     * @dev subfunction, transfer mineCoin to recieptor when account transfer amount FPTCoin to recieptor
     * @param account the account transfer from
     */
    function _userSettlementAll(address account)internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            _userSettlement(whiteList[i],account);
        }
    }

    function _userSettlement(address mineCoin,address account)internal{
        minerBalances[mineCoin][account] = minerBalances[mineCoin][account].add(_settlement(mineCoin,account,mineNetworth[mineCoin]));
        minerOrigins[mineCoin][account] = mineNetworth[mineCoin];
    }
    /**
     * @dev subfunction, settle user's latest mine amount.
     * @param mineCoin the mine coin address
     * @param account user's account
     * @param tokenNetWorth the latest token net worth
     */
    function _settlement(address mineCoin,address account,uint256 tokenNetWorth)internal view returns (uint256) {
        uint256 origin = minerOrigins[mineCoin][account];
        require(tokenNetWorth>=origin,"error: tokenNetWorth logic error!");
        return balanceOf(account).mul(tokenNetWorth-origin)/rayDecimals;
    }
    function getNetWorth(address mineCoin) public view returns (uint256) {
        return _getCurrentTokenNetWorth(mineCoin);
    }
    /**
     * @dev subfunction, calculate current token net worth.
     * @param mineCoin the mine coin address
     */
    function _getCurrentTokenNetWorth(address mineCoin)internal view returns (uint256) {
        uint256 latestMined = _getLatestMined(mineCoin);
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0){
            return mineNetworth[mineCoin].add(latestMined.mul(rayDecimals)/_totalSupply);
        }
        return mineNetworth[mineCoin];
    }
    /**
     * @dev get FPTCoin's total supply.
     */
    function totalSupply()internal view returns(uint256){
        return _totalsupply;
//        IERC20 _Coin = IERC20(_operators[managerIndex]);
//        return _Coin.totalSupply();
    }
    /**
     * @dev get FPTCoin's user balance.
     */
    function balanceOf(address account)internal view returns(uint256){
        return distributeBalance[account];
        /*
        IERC20 _Coin = IERC20(_operators[managerIndex]);
        return _Coin.balanceOf(account);
        */
    }
}