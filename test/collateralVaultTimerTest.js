let defrostFactory = require("./defrostFactory.js");
let eventDecoderClass = require("./eventDecoder.js")
let eth = "0x0000000000000000000000000000000000000000";
let collateralVaultAbi = require("../build/contracts/collateralVault.json").abi;
let systemCoinAbi = require("D:\\work\\solidity\\defrostCoin\\build\\contracts\\systemCoin.json").abi;
let coinMinePoolAbi = require("../build/contracts/coinMinePool.json").abi;
const IERC20 = artifacts.require("IERC20");
const BN = require("bn.js");
let bigNum = "1000000000000000000000000000000";
contract('collateralVault', function (accounts){
    let beforeInfo;
    let factory;
    before(async () => {
        beforeInfo = await defrostFactory.before();
        eventDecoder = new eventDecoderClass();
        eventDecoder.initEventsMap([collateralVaultAbi,coinMinePoolAbi,systemCoinAbi]);
        factory = await defrostFactory.createTestFactory(accounts[0],accounts);
    }); 
    it('collateralVault normal tests', async function (){
    });
    it('collateralVault collateral join tests', async function (){
        await vaults.vaultPool.join(accounts[1],1e15,{from:accounts[0],value:1e15})
        let result = await vaults.vaultPool.totalAssetAmount();
        console.log("totalAssetAmount",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[0]);
        console.log("collateralBalances accounts[0]",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[1]);
        console.log("collateralBalances accounts[1]",result.toString());
        await vaults.vaultPool.exit(accounts[0],1e15,{from:accounts[1]})
        result = await vaults.vaultPool.totalAssetAmount();
        console.log("totalAssetAmount",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[0]);
        console.log("collateralBalances accounts[0]",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[1]);
        console.log("collateralBalances accounts[1]",result.toString());
    });
    it('collateralVault system coin mint tests', async function (){
        await vaults.vaultPool.join(accounts[1],"1000000000000000000",{from:accounts[0],value:1e15})
        let result = await vaults.vaultPool.totalAssetAmount();
        console.log("totalAssetAmount",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[0]);
        console.log("collateralBalances accounts[0]",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[1]);
        console.log("collateralBalances accounts[1]",result.toString());
        await vaults.vaultPool.mintSystemCoin(accounts[0],"10000000000000000000",{from:accounts[1]})
        await vaults.vaultPool.mintSystemCoin(accounts[0],"10000000000000000000",{from:accounts[1]})
        console.log("time 0 :",(new Date()).getTime());
        result = await vaults.vaultPool.totalAssetAmount();
        console.log("totalAssetAmount",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[0]);
        console.log("collateralBalances accounts[0]",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[1]);
        console.log("collateralBalances accounts[1]",result.toString());
        result = await vaults.vaultPool.getAssetBalance(accounts[0]);
        console.log("getAssetBalance accounts[0]",result.toString());
        result = await vaults.vaultPool.getAssetBalance(accounts[1]);
        console.log("getAssetBalance accounts[1]",result.toString());
        result = await factory.systemCoin.balanceOf(accounts[0]);
        console.log("systemCoin Balance accounts[0]",result.toString());
        result = await factory.systemCoin.balanceOf(accounts[1]);
        console.log("systemCoin Balance accounts[1]",result.toString());
        let price = new BN(1e15);
        price = price.mul(new BN(3000e3));
        for (var i=0;i<10;i++){
            await factory.oracle.setPrice(eth,price,{from:accounts[1]});
        }
        console.log("time 1 :",(new Date()).getTime());
        result = await vaults.vaultPool.getAssetBalance(accounts[0]);
        console.log("getAssetBalance accounts[0]",result.toString());
        result = await vaults.vaultPool.getAssetBalance(accounts[1]);
        console.log("getAssetBalance accounts[1]",result.toString());

        await factory.systemCoin.approve(vaults.vaultPool.address,"10000000000000000000",{from:accounts[0]});
        await vaults.vaultPool.repaySystemCoin(accounts[1],"5000000000000000000",{from:accounts[0]})
        console.log("time 0 :",(new Date()).getTime());
        result = await vaults.vaultPool.totalAssetAmount();
        console.log("totalAssetAmount",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[0]);
        console.log("collateralBalances accounts[0]",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[1]);
        console.log("collateralBalances accounts[1]",result.toString());
        result = await vaults.vaultPool.getAssetBalance(accounts[0]);
        console.log("getAssetBalance accounts[0]",result.toString());
        result = await vaults.vaultPool.getAssetBalance(accounts[1]);
        console.log("getAssetBalance accounts[1]",result.toString());
        result = await factory.systemCoin.balanceOf(accounts[0]);
        console.log("systemCoin Balance accounts[0]",result.toString());
        result = await factory.systemCoin.balanceOf(accounts[1]);
        console.log("systemCoin Balance accounts[1]",result.toString());;
        for (var i=0;i<10;i++){
            await factory.oracle.setPrice(eth,price,{from:accounts[1]});
        }
        console.log("time 1 :",(new Date()).getTime());
        result = await vaults.vaultPool.getAssetBalance(accounts[0]);
        console.log("getAssetBalance accounts[0]",result.toString());
        result = await vaults.vaultPool.getAssetBalance(accounts[1]);
        console.log("getAssetBalance accounts[1]",result.toString());
    });
});