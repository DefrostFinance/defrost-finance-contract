let defrostFactory = require("./defrostFactory.js");
let eventDecoderClass = require("./eventDecoder.js")
let eth = "0x0000000000000000000000000000000000000000";
let collateralVaultAbi = require("../build/contracts/collateralVault.json").abi;
let systemCoinAbi = require("D:\\work\\solidity\\defrostCoin\\build\\contracts\\systemCoin.json").abi;
let coinMinePoolAbi = require("../build/contracts/coinMinePool.json").abi;
const collateralVaultTest = artifacts.require("collateralVaultTest");
const IERC20 = artifacts.require("IERC20");
const BN = require("bn.js");
let bigNum = "1000000000000000000000000000000";
let ether = new BN("1000000000000000000")
contract('collateralVault', function (accounts){
    let beforeInfo;
    let factory;
    before(async () => {
        beforeInfo = await defrostFactory.before();
        eventDecoder = new eventDecoderClass();
        eventDecoder.initEventsMap([collateralVaultAbi,coinMinePoolAbi,systemCoinAbi]);
        factory = await defrostFactory.createTestFactory(accounts[0],accounts);
        await factory.oracle.setOperator(3,accounts[1],{from:accounts[0]});
    }); 
    it('collateralVault collateral check normal tests', async function (){
        let price = new BN(1e15);
        price = price.mul(new BN(30000e3));
        await factory.oracle.setPrice(eth,price,{from:accounts[1]});
        let ray = new BN(1e15);
        ray = ray.mul(new BN(1e3));
        let vault1 = await defrostFactory.createCollateralVault(factory,accounts[0],accounts,"ETH-C1",eth,bigNum,
            "1000000000000000000","1500000000000000000",ray,1);
        vault1.vaultPool = await collateralVaultTest.at(vault1.vaultPool.address);
        await vault1.vaultPool.join(accounts[1],ether,{from:accounts[1],value:ether});
        let maxMint = await vault1.vaultPool.getMaxMintAmount(accounts[1],0);
        console.log("getMaxMintAmount",maxMint.toString());
        await vault1.vaultPool.mintSystemCoin(accounts[1],maxMint,{from:accounts[1]});
        await defrostFactory.testViolation("collateral is insufficient!",async function(){
            await vault1.vaultPool.mintSystemCoin(accounts[1],1,{from:accounts[1]});
        })
        await vault1.vaultPool.setTimer(1);
        let bLiquidate = await vault1.vaultPool.canLiquidate(accounts[1]);
        assert(bLiquidate,"collateral liquidate check error!");

        await vault1.vaultPool.join(accounts[2],ether,{from:accounts[3],value:ether});
        maxMint = await vault1.vaultPool.getMaxMintAmount(accounts[2],0);
        console.log("getMaxMintAmount",maxMint.toString());
        await vault1.vaultPool.mintSystemCoin(accounts[3],maxMint,{from:accounts[2]});
        await defrostFactory.testViolation("collateral is insufficient!",async function(){
            await vault1.vaultPool.exit(accounts[3],1,{from:accounts[2]});
        })
        await vault1.vaultPool.setTimer(2);
        bLiquidate = await vault1.vaultPool.canLiquidate(accounts[2]);
        assert(bLiquidate,"collateral liquidate check error!");

    });
    it('collateralVault stability fee normal tests', async function (){

        let ray = new BN(1e15);
        ray = ray.mul(new BN(1e3));
        let vault1 = await defrostFactory.createCollateralVault(factory,accounts[0],accounts,"ETH-3",eth,bigNum,
            "1000000000000000000","1500000000000000000",ray,1);
        vault1.vaultPool = await collateralVaultTest.at(vault1.vaultPool.address);
        let rate = await vault1.vaultPool.getAccumulatedRate();
        assert(rate.eq(new BN("1000000000000000000000000000")),"accumulated Rate initial error!");
        await checkStabilityFee(vault1,10,ray.muln(2),new BN("1000000010000000045000000120"));
        await checkStabilityFee(vault1,30,ray.muln(3),new BN("1000000050000001205000018640"));
        await checkStabilityFee(vault1,79,ray.muln(4),new BN("1000000197000019139001222423"));
        await checkStabilityFee(vault1,298,ray.muln(3),new BN("1000001073000573647203736448"));
    });
    it('collateralVault user settlement stability fee normal tests', async function (){
        let price = new BN(1e15);
        price = price.mul(new BN(30000e3));
        await factory.oracle.setPrice(eth,price,{from:accounts[1]});
        let ray = new BN(1e15);
        ray = ray.mul(new BN(1e3));
        let vault1 = await defrostFactory.createCollateralVault(factory,accounts[0],accounts,"ETH-4",eth,bigNum,
            "1000000000000000000","1500000000000000000",ray,1);
        vault1.vaultPool = await collateralVaultTest.at(vault1.vaultPool.address);
        await vault1.vaultPool.join(accounts[0],ether,{from:accounts[0],value:ether})
        await vault1.vaultPool.mintSystemCoin(accounts[0],ether.muln(5000),{from:accounts[0]});
        let result = await vault1.vaultPool.getAssetBalance(accounts[0]);
        assert(result.eq(new BN("5000000000000000000000")),"getAssetBalance accounts[0] check error!");
        await checkAssetBalance(vault1,10,0,ray.muln(2),new BN("5000000050000000225000"));
        await checkAssetBalance(vault1,30,0,ray.muln(3),new BN("5000000250000006025000"));
        await checkAssetBalance(vault1,79,0,ray.muln(4),new BN("5000000985000095695006"));
        await checkAssetBalance(vault1,298,0,ray.muln(3),new BN("5000005365002868236018"));
    });
    async function checkStabilityFee(vault1,newTime,stabilityFee,checkRate){
        await vault1.vaultPool.setTimer(newTime);
        await defrostFactory.multiSignatureAndSend(factory.multiSignature,vault1.vaultPool,"setStabilityFee",accounts[0],accounts,
        stabilityFee,1);
        rate = await vault1.vaultPool.getAccumulatedRate();
        assert(rate.eq(checkRate),"accumulated Rate check error!");
    }
    async function checkAssetBalance(vault1,newTime,accountID,stabilityFee,checkBalance){
        await vault1.vaultPool.setTimer(newTime);
        await defrostFactory.multiSignatureAndSend(factory.multiSignature,vault1.vaultPool,"setStabilityFee",accounts[0],accounts,
        stabilityFee,1);
        let result = await vault1.vaultPool.getAssetBalance(accounts[accountID]);
        assert(result.eq(new BN(checkBalance)),"accounts "+ accountID + " getAssetBalance check error!");
    }
});
