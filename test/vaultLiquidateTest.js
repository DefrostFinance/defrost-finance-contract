let defrostFactory = require("./defrostFactory.js");
let eventDecoderClass = require("./eventDecoder.js")
let eth = "0x0000000000000000000000000000000000000000";
let collateralVaultAbi = require("../build/contracts/collateralVault.json").abi;
let systemCoinAbi = require("D:\\work\\solidity\\defrostCoin\\build\\contracts\\systemCoin.json").abi;
let coinMinePoolAbi = require("../build/contracts/coinMinePool.json").abi;
const IERC20 = artifacts.require("IERC20");
const BN = require("bn.js");
let bigNum = "1000000000000000000000000000000";
let ether = new BN("1000000000000000000")
contract('collateralVault', function (accounts){
    let beforeInfo;
    let vaults;
    let factory;
    before(async () => {
        beforeInfo = await defrostFactory.before();
        eventDecoder = new eventDecoderClass();
        eventDecoder.initEventsMap([collateralVaultAbi,coinMinePoolAbi,systemCoinAbi]);
        factory = await defrostFactory.createFactory(accounts[0],accounts);
        let ray = new BN(1e15);
        ray = ray.mul(new BN(5e3));
        vaults = await defrostFactory.createCollateralVault(factory,accounts[0],accounts,"ETH-2",eth,bigNum,
            "1000000000000000000","1500000000000000000",ray,1);
        await factory.oracle.setOperator(3,accounts[1],{from:accounts[0]});
    }); 
    it('collateralVault liquidate tests', async function (){
        await vaults.vaultPool.join(accounts[0],ether,{from:accounts[0],value:ether})
        let result = await vaults.vaultPool.totalAssetAmount();
        console.log("totalAssetAmount",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[0]);
        console.log("collateralBalances accounts[0]",result.toString());
        await vaults.vaultPool.join(accounts[2],ether.muln(100),{from:accounts[2],value:ether.muln(100)})
        result = await vaults.vaultPool.totalAssetAmount();
        console.log("totalAssetAmount",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[2]);
        console.log("collateralBalances accounts[2]",result.toString());
        let price = ether.muln(3000);
        await factory.oracle.setPrice(eth,price,{from:accounts[1]});
        result = await vaults.vaultPool.getMaxMintAmount(accounts[0],0);
        console.log("getMaxMintAmount accounts[0]",result.toString());
        await vaults.vaultPool.mintSystemCoin(accounts[0],ether.muln(2000),{from:accounts[0]})
        console.log("time 0 :",(new Date()).getTime());
        result = await vaults.vaultPool.totalAssetAmount();
        console.log("totalAssetAmount",result.toString());
        result = await vaults.vaultPool.collateralBalances(accounts[0]);
        console.log("collateralBalances accounts[0]",result.toString());
        result = await vaults.vaultPool.getAssetBalance(accounts[0]);
        console.log("getAssetBalance accounts[0]",result.toString());
        result = await factory.systemCoin.balanceOf(accounts[0]);
        console.log("systemCoin Balance accounts[0]",result.toString());
        await factory.oracle.setPrice(eth,ether.muln(2990),{from:accounts[1]});
        result = await vaults.vaultPool.canLiquidate(accounts[0]); 
        console.log("canLiquidate accounts[0]:",result);
        result = await vaults.vaultPool.canLiquidate(accounts[2]); 
        console.log("canLiquidate accounts[2]:",result);
        await vaults.vaultPool.mintSystemCoin(accounts[2],ether.muln(25000),{from:accounts[2]})
        result = await vaults.vaultPool.canLiquidate(accounts[0]); 
        console.log("canLiquidate accounts[0]:",result);
        result = await vaults.vaultPool.canLiquidate(accounts[2]); 
        console.log("canLiquidate accounts[2]:",result);
        await factory.systemCoin.approve(vaults.vaultPool.address,ether.muln(5000),{from:accounts[2]});
        await vaults.vaultPool.liquidate(accounts[0],{from:accounts[2]})
        result = await vaults.vaultPool.canLiquidate(accounts[0]); 
        console.log("canLiquidate accounts[0]:",result);
        result = await vaults.vaultPool.canLiquidate(accounts[2]); 
        console.log("canLiquidate accounts[2]:",result);
        result = await vaults.vaultPool.collateralBalances(accounts[0]);
        console.log("collateralBalances accounts[0]",result.toString());
        result = await vaults.vaultPool.getAssetBalance(accounts[0]);
        console.log("getAssetBalance accounts[0]",result.toString());
    });
});