const BN = require("bn.js");
const fs = require('fs');
let contractInfo = require("./testInfo.json");
const collateralVault = artifacts.require("collateralVault");
const coinMinePool = artifacts.require("coinMinePool");
const defrostFactory = artifacts.require("defrostFactory");
const phxProxy = artifacts.require("phxProxy");
const multiSignature = artifacts.require("multiSignature");
const IERC20 = artifacts.require("IERC20");
let eth = "0x0000000000000000000000000000000000000000";
module.exports = {
    before : async function() {
        let fnx = await IERC20.at(contractInfo.FNX);
        let USDC = await IERC20.at(contractInfo.USDC);
        let WBTC = await IERC20.at(contractInfo.WBTC);
        let WETH = await IERC20.at(contractInfo.WETH);
        return {
            fnx : fnx,
            USDC :USDC,
            WBTC :WBTC,
            WETH : WETH,
        }
    },
    createFactory : async function(account,accounts) {
        let multiSign = await multiSignature.new([accounts[0],accounts[1],accounts[2],accounts[3],accounts[4]],3)
        let collateralVaultImpl = await collateralVault.new(multiSign.address,{from:account});
        let oracle = await this.createFromJson("D:\\work\\solidity\\PhoenixOptionsV1.0\\build\\contracts\\PHXOracle.json",account);
        let systemCoin = await this.createFromJson("D:\\work\\solidity\\defrostCoin\\build\\contracts\\systemCoin.json",account,multiSign.address,"H2O","H2O",5777);
        let dFactory = await defrostFactory.new(multiSign.address,{from:account});
        proxy = await phxProxy.new(dFactory.address,multiSign.address,{from:account});
        dFactory = await defrostFactory.at(proxy.address);
        await dFactory.initContract(accounts[1],systemCoin.address,oracle.address,collateralVaultImpl.address,"80000000000000000","50000000000000000")
        
        await this.multiSignatureAndSend(multiSign,systemCoin,"addAuthorization",account,accounts,dFactory.address);

        let minePoolImpl = await coinMinePool.new(multiSign.address,{from:account});

        await this.multiSignatureAndSend(multiSign,dFactory,"createSystemCoinMinePool",account,accounts,minePoolImpl.address);
        minePoolImpl = await dFactory.systemCoinMinePool();
        let minePool = await coinMinePool.at(minePoolImpl);
        return {
            oracle: oracle,
            systemCoin:systemCoin,
            multiSignature : multiSign,
            factory : dFactory,
            minePool : minePool
        }
    },
    multiSignatureAndSend: async function(multiContract,toContract,method,account,owners,...args){
        let msgData = await toContract.contract.methods[method](...args).encodeABI();
        let hash = await this.createApplication(multiContract,account,toContract.address,0,msgData)
        let index = await multiContract.getApplicationCount(hash)
        index = index.toNumber()-1;
        await multiContract.signApplication(hash,index,{from:owners[0]})
        await multiContract.signApplication(hash,index,{from:owners[1]})
        await multiContract.signApplication(hash,index,{from:owners[2]})
        await toContract[method](...args,{from:account});
    },
    createApplication: async function (multiSign,account,to,value,message){
        await multiSign.createApplication(to,value,message,{from:account});
        return await multiSign.getApplicationHash(account,to,value,message)
    },
    createCollateralVault : async function(factoryInfo,account,accounts,vaultID,collateral,debtCeiling,debtFloor,collateralRate,taxRate,taxInterval) {
        let vaultIDbytes = web3.utils.asciiToHex(vaultID);
        await this.multiSignatureAndSend(factoryInfo.multiSignature,factoryInfo.factory,"createVault",account,accounts,
        vaultIDbytes,collateral,debtCeiling,debtFloor,collateralRate,taxRate,taxInterval)
        let spoolAddress = await factoryInfo.factory.getVault(vaultIDbytes);
        let vaultPool = await collateralVault.at(spoolAddress);
        let contracts = {
            oracle : factoryInfo.oracle,
            collateral : collateral,
            vaultPool : vaultPool,
        }
        return contracts;
    },
    setAddressFromJson: async function(fileName,address) {
        var contract = require("@truffle/contract");
        let buildJson = require(fileName)
        let newContract = contract(buildJson)
        newContract.setProvider(web3.currentProvider);
        let artifact = await newContract.at(address);
        return artifact;
    },
    createFromJson: async function(fileName,account,...args) {
        var contract = require("@truffle/contract");
        let buildJson = require(fileName)
        let newContract = contract(buildJson)
        newContract.setProvider(web3.currentProvider);
        let artifact = await newContract.new(...args,{from : account});
        return artifact;
    }
}