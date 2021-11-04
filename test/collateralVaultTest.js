let defrostFactory = require("./defrostFactory.js");
let eventDecoderClass = require("./eventDecoder.js")
let eth = "0x0000000000000000000000000000000000000000";
let collateralVaultAbi = require("../build/contracts/collateralVault.json").abi;
let systemCoinAbi = require("D:\\work\\solidity\\defrostCoin\\build\\contracts\\systemCoin.json").abi;
let coinMinePoolAbi = require("../build/contracts/coinMinePool.json").abi;
const IERC20 = artifacts.require("IERC20");
const BN = require("bn.js");
let bigNum = "1000000000000000000000000000000";
let big20 = new BN("100000000000000000000");
let maxFee = new BN("20813179695551943456673");
let minFee = new BN("-25472683706574430182440");
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
    }); 
    it('collateralVault normal tests', async function (){
        let price = new BN(1e15);
        price = price.mul(new BN(3000e3));
        await factory.oracle.setOperator(3,accounts[1],{from:accounts[0]});
        await factory.oracle.setPrice(eth,price,{from:accounts[1]});
        let result = await vaults.vaultPool.totalAssetAmount();
        console.log("totalAssetAmount",result.toString());
        result = await vaults.vaultPool.assetCeiling();
        console.log("assetCeiling",result.toString());
        result = await vaults.vaultPool.assetFloor();
        console.log("assetFloor",result.toString());
        result = await vaults.vaultPool.collateralRate();
        console.log("collateralRate",result.toString());
        result = await vaults.vaultPool.liquidationReward();
        console.log("liquidationReward",result.toString());
        result = await vaults.vaultPool.liquidationPenalty();
        console.log("liquidationPenalty",result.toString());

        result = await vaults.vaultPool.getInterestInfo();
        console.log("getInterestInfo",result[0].toString(),result[1].toString());

        result = await vaults.vaultPool.collateralToken();
        console.log("collateralToken",result);
        result = await vaults.vaultPool.reservePool();
        console.log("reservePool",result);
        result = await vaults.vaultPool.systemCoin();
        console.log("systemCoin",result);
        result = await vaults.vaultPool.vaultID();
        console.log("vaultID",result);

    });
    it('collateralVault stability and liquidation setting tests', async function (){
        let ray = new BN(1e15);
        ray = ray.mul(new BN(5e3));
        let vault1 = await defrostFactory.createCollateralVault(factory,accounts[0],accounts,"ETH-3",eth,bigNum,
            "1000000000000000000","1500000000000000000",ray,1);

        await defrostFactory.multiSignatureAndSend(factory.multiSignature,vault1.vaultPool,"setStabilityFee",accounts[1],accounts,
        maxFee,3600);
        await defrostFactory.multiSignatureAndSend(factory.multiSignature,vault1.vaultPool,"setStabilityFee",accounts[1],accounts,
        minFee,3600);
        await defrostFactory.testViolation("stability Fee Is too big",async function(){
            await defrostFactory.multiSignatureAndSend(factory.multiSignature,vault1.vaultPool,"setStabilityFee",accounts[0],accounts,
            maxFee.addn(1),3600);
        })
        await defrostFactory.testViolation("stability Fee Is too small",async function(){
            await defrostFactory.multiSignatureAndSend(factory.multiSignature,vault1.vaultPool,"setStabilityFee",accounts[0],accounts,
            minFee.subn(1),3600);
        })
        await defrostFactory.testViolation("Liquidation reward is greater than collateral rate",async function(){
            await defrostFactory.multiSignatureAndSend(factory.multiSignature,vault1.vaultPool,"setLiquidationInfo",accounts[0],accounts,
            "600000000000000000","80000000000000000");
        })
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
        await defrostFactory.multiSignatureAndSend(factory.multiSignature,vaults.vaultPool,"setHalt",accounts[0],accounts,true);
        await defrostFactory.testViolation("emergencyExit is not set",async function(){
            await vaults.vaultPool.emergencyExit(accounts[1])
        })
        await defrostFactory.multiSignatureAndSend(factory.multiSignature,vaults.vaultPool,"setHalt",accounts[0],accounts,false);
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