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
contract('coinMinePool', function (accounts){
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
    it('coinMinePool one account tests', async function (){
        await defrostFactory.multiSignatureAndSend(factory.multiSignature,factory.minePool,"setMineCoinInfo",accounts[0],accounts,beforeInfo.fnx.address,2e15,1);
        result = await factory.minePool.getMineInfo(beforeInfo.fnx.address);
        console.log("getMineInfo",result[0].toString(),result[1].toString());
        let price = ether.muln(30000);
        await factory.oracle.setPrice(eth,price,{from:accounts[1]});
        for (var k=0;k<5;k++){
            console.log("--------------------------round ", k+1, " ---------------------------------------")
            await vaults.vaultPool.join(accounts[0],ether,{from:accounts[0],value:ether})
            let result = await vaults.vaultPool.totalAssetAmount();
            console.log("totalAssetAmount",result.toString());
            result = await vaults.vaultPool.collateralBalances(accounts[0]);
            console.log("collateralBalances accounts[0]",result.toString());
            result = await factory.minePool.getMinerBalance(accounts[0],beforeInfo.fnx.address);
            console.log("getMinerBalance",result.toString());        
            result = await vaults.vaultPool.getMaxMintAmount(accounts[0],0);
            console.log("getMaxMintAmount accounts[0]",result.toString());
            await vaults.vaultPool.mintSystemCoin(accounts[0],ether.muln(2000),{from:accounts[0]})
            console.log("time 0 :",(new Date()).getTime());
            result = await factory.minePool.getMinerBalance(accounts[0],beforeInfo.fnx.address);
            console.log("getMinerBalance",result.toString());   
            for (var i=0;i<10;i++){
                await factory.oracle.setPrice(eth,price,{from:accounts[1]});
            }
            console.log("time 1 :",(new Date()).getTime());
            result = await factory.minePool.getMinerBalance(accounts[0],beforeInfo.fnx.address);
            console.log("getMinerBalance",result.toString()); 
        }
    });
    it('coinMinePool two account tests', async function (){
        await defrostFactory.multiSignatureAndSend(factory.multiSignature,factory.minePool,"setMineCoinInfo",accounts[0],accounts,beforeInfo.fnx.address,2e15,1);
        result = await factory.minePool.getMineInfo(beforeInfo.fnx.address);
        console.log("getMineInfo",result[0].toString(),result[1].toString());
        let price = ether.muln(30000);
        await factory.oracle.setPrice(eth,price,{from:accounts[1]});
        for (var k=0;k<5;k++){
            console.log("--------------------------round ", k+1, " ---------------------------------------")
            await vaults.vaultPool.join(accounts[0],ether,{from:accounts[0],value:ether})
            await vaults.vaultPool.join(accounts[2],ether.muln(100),{from:accounts[2],value:ether.muln(100)})    
            result = await vaults.vaultPool.getAssetBalance(accounts[0]);
            console.log("getAssetBalance accounts[0]",result.toString());
            result = await vaults.vaultPool.getMaxMintAmount(accounts[0],0);
            console.log("getMaxMintAmount accounts[0]",result.toString());   
            await vaults.vaultPool.mintSystemCoin(accounts[0],ether.muln(2000),{from:accounts[0]})
            await logBalance(0,factory.minePool,beforeInfo.fnx.address,accounts[0],accounts[2])
            for (var i=0;i<5;i++){
                await factory.oracle.setPrice(eth,price,{from:accounts[1]});
            }
            await logBalance(1,factory.minePool,beforeInfo.fnx.address,accounts[0],accounts[2])
            await vaults.vaultPool.mintSystemCoin(accounts[2],ether.muln(200000),{from:accounts[2]})
            await logBalance(2,factory.minePool,beforeInfo.fnx.address,accounts[0],accounts[2])
            for (var i=0;i<5;i++){
                await factory.oracle.setPrice(eth,price,{from:accounts[1]});
            }
            await logBalance(3,factory.minePool,beforeInfo.fnx.address,accounts[0],accounts[2])
        }
    });
});
async function logBalance(index,minePool,fnx,account,account1){
    let networth = await minePool.getNetWorth(fnx);
    let balance0 = await minePool.getMinerBalance(account,fnx);
    let balance2 = await minePool.getMinerBalance(account1,fnx);
    console.log(index,":",(new Date()).getTime(),networth.toString(),balance0.toString(),balance2.toString());

}