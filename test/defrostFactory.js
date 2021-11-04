const BN = require("bn.js");
const fs = require('fs');
let contractInfo = require("./testInfo.json");
const collateralVault = artifacts.require("collateralVault");
const coinMinePool = artifacts.require("coinMinePool");
const defrostFactory = artifacts.require("defrostFactory");
const defrostFactoryTest = artifacts.require("defrostFactoryTest");
const mineCoin = artifacts.require("mineCoin");
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
        let multiSign = await this.createFromJson("D:\\work\\solidity\\PhoenixOptionsV1.0\\build\\contracts\\multiSignature.json",account,
            [accounts[0],accounts[1],accounts[2],accounts[3],accounts[4]],3);
        let oracle = await this.createFromJson("D:\\work\\solidity\\PhoenixOptionsV1.0\\build\\contracts\\PHXOracle.json",account);
        let dFactory = await defrostFactory.new(multiSign.address,accounts[0],accounts[1],accounts[1],oracle.address,{from:account});
        
        await this.multiSignatureAndSend(multiSign,dFactory,"createSystemCoin",account,accounts,"H2O","H2O");
        let h2oCoin = await dFactory.systemCoin();
        let systemCoin = await mineCoin.at(h2oCoin);
//        let minePool = await coinMinePool.new(multiSign.address,accounts[0],accounts[1],h2oCoin,{from:account});
//        await this.multiSignatureAndSend(multiSign,dFactory,"setSystemCoinMinePool",account,accounts,minePool.address);


        return {
            oracle: oracle,
            systemCoin:systemCoin,
            multiSignature : multiSign,
            factory : dFactory,
//            minePool : minePool
        }
    },
    createTestFactory : async function(account,accounts) {
        let multiSign = await this.createFromJson("D:\\work\\solidity\\PhoenixOptionsV1.0\\build\\contracts\\multiSignature.json",account,
            [accounts[0],accounts[1],accounts[2],accounts[3],accounts[4]],3);
        let oracle = await this.createFromJson("D:\\work\\solidity\\PhoenixOptionsV1.0\\build\\contracts\\PHXOracle.json",account);
        let dFactory = await defrostFactoryTest.new(multiSign.address,accounts[0],accounts[1],accounts[1],oracle.address,{from:account});
        
        await this.multiSignatureAndSend(multiSign,dFactory,"createSystemCoin",account,accounts,"H2O","H2O");
        let h2oCoin = await dFactory.systemCoin();
        let systemCoin = await mineCoin.at(h2oCoin);
//        let minePool = await coinMinePool.new(multiSign.address,accounts[0],accounts[1],h2oCoin,{from:account});
//        await this.multiSignatureAndSend(multiSign,dFactory,"setSystemCoinMinePool",account,accounts,minePool.address);
        return {
            oracle: oracle,
            systemCoin:systemCoin,
            multiSignature : multiSign,
            factory : dFactory,
//            minePool : minePool
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
        vaultIDbytes,collateral,debtCeiling,debtFloor,collateralRate,taxRate,taxInterval,"80000000000000000","50000000000000000")
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
    },
    testViolation : async function(message,testFunc){
        bErr = false;
        try {
            await testFunc();        
        } catch (error) {
            console.log(error);
            bErr = true;
        }
        assert(bErr,message);
    }
}