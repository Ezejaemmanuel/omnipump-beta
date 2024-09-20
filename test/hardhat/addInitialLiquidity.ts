

// // 1. Test Setup and Imports
// import { expect } from "chai";
// import { ethers } from "hardhat";
// import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
// import { MainEngine, CustomToken } from "../../typechain-types";
// import { DeployMainEngine } from "../../script/deployMainEngine.s";
// import { Pool, Position, NonfungiblePositionManager, nearestUsableTick, TickMath } from '@uniswap/v3-sdk';
// import { Price, Token } from '@uniswap/sdk-core';
// import JSBI from 'jsbi';
// import { abi as IUniswapV3PoolABI } from '@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json';
// import dotenv from "dotenv";
// import { TOKEN_AMOUNT, ETH_AMOUNT } from "./constants";
// import { collectingBackEth } from "./collect-liquidity";
// import BigNumber from "bignumber.js";
// // import { calculateWideTicks } from "./newTickCalculator";
// // import { calculateWideTicks } from "./tickCalculator";

// dotenv.config();

// // 2. Test Constants and Variables
// describe("MainEngine Integration Test", function () {
//     this.timeout(12000000); // 2 minutes

//     let mainEngine: MainEngine;
//     let deployer: SignerWithAddress;
//     let user: SignerWithAddress;
//     let customToken: CustomToken;
//     let wethAddress: string;
//     let tokenAddress: string;

//     // 3. Before Hook (Test Environment Setup)
//     before(async function () {
//         console.log("Setting up test environment...");
//         [deployer] = await ethers.getSigners();
//         user = await ethers.getSigner(process.env.SEPOLIA_TEST_WALLET!);
//         console.log("Deployer address:", deployer.address);
//         console.log("User address:", user.address);

//         const network = await ethers.provider.getNetwork();
//         console.log("Current network:", network.name);
//         console.log("Current block number:", await ethers.provider.getBlockNumber());

//         mainEngine = await DeployMainEngine(network);
//         //@ts-ignore
//         console.log("MainEngine deployed at:", mainEngine.address);

//         wethAddress = await mainEngine.WETH9();
//         console.log("WETH9 address:", wethAddress);

//         console.log("Test environment setup complete.");
//     });

//     it("should create a token, setup a pool, and add initial liquidity", async function () {
//         console.log("Starting main test...");

//         // Step 1: Create Token
//         console.log("Step 1: Creating token...");
//         const name = "Test Token";
//         const symbol = "TST";
//         const description = "A test token for integration testing";
//         const imageUrl = "https://example.com/test-token.png";
//         const initialSupply = ethers.BigNumber.from(TOKEN_AMOUNT); // 1 million tokens

//         console.log("Creating token with parameters:");
//         console.log("Name:", name);
//         console.log("Symbol:", symbol);
//         console.log("Description:", description);
//         console.log("Image URL:", imageUrl);
//         console.log("Initial Supply:", initialSupply.toString());

//         const createTokenTx = await mainEngine.connect(user).createTokenForTest(name, symbol, description, imageUrl, initialSupply);
//         console.log("Token creation transaction hash:", createTokenTx.hash);
//         const createTokenReceipt = await createTokenTx.wait();
//         console.log("Token creation transaction mined. Gas used:", createTokenReceipt.gasUsed.toString());

//         const tokenCreatedEvent = createTokenReceipt.events?.find(e => e.event === "TokenCreated");
//         if (!tokenCreatedEvent || !tokenCreatedEvent.args) {
//             throw new Error("TokenCreated event not found in transaction receipt");
//         }
//         tokenAddress = tokenCreatedEvent.args.tokenAddress;
//         console.log("Token created at address:", tokenAddress);

//         customToken = await ethers.getContractAt("CustomToken", tokenAddress) as CustomToken;

//         // Verify token creation
//         console.log("Verifying token details...");
//         const tokenName = await customToken.name();
//         const tokenSymbol = await customToken.symbol();
//         const tokenDescription = await customToken.getDescription();
//         const tokenImageUrl = await customToken.getImageUrl();
//         const tokenTotalSupply = await customToken.totalSupply();
//         const tokenOwner = await customToken.owner();

//         console.log("Token name:", tokenName);
//         console.log("Token symbol:", tokenSymbol);
//         console.log("Token description:", tokenDescription);
//         console.log("Token image URL:", tokenImageUrl);
//         console.log("Token total supply:", tokenTotalSupply.toString());
//         console.log("Token owner:", tokenOwner);

//         expect(tokenName).to.equal(name);
//         expect(tokenSymbol).to.equal(symbol);
//         expect(tokenDescription).to.equal(description);
//         expect(tokenImageUrl).to.equal(imageUrl);
//         expect(tokenTotalSupply).to.equal(initialSupply);
//         //@ts-ignore
//         expect(tokenOwner).to.equal(mainEngine.address);
//         console.log("Token details verified successfully.");

//         // Step 2: Setup Pool
//         console.log("Step 2: Setting up pool...");
//         const ethAmount = ethers.BigNumber.from(ETH_AMOUNT); // 1 ETH for pool setup
//         console.log("ETH amount for pool setup:", ethers.utils.formatEther(ethAmount), "ETH");

//         const setupPoolTx = await mainEngine.connect(user).testSetupPool(tokenAddress, { value: ethAmount });
//         console.log("Pool setup transaction hash:", setupPoolTx.hash);
//         const setupPoolReceipt = await setupPoolTx.wait();
//         console.log("Pool setup transaction mined. Gas used:", setupPoolReceipt.gasUsed.toString());

//         const poolCreatedEvent = setupPoolReceipt.events?.find(e => e.event === "PoolCreated");
//         if (!poolCreatedEvent || !poolCreatedEvent.args) {
//             throw new Error("PoolCreated event not found in transaction receipt");
//         }
//         const poolAddress = poolCreatedEvent.args.pool;
//         console.log("Pool created at address:", poolAddress);

//         // Verify pool setup
//         console.log("Verifying pool setup...");
//         const poolContract = new ethers.Contract(poolAddress, IUniswapV3PoolABI, ethers.provider);
//         const [token0, token1] = await mainEngine.orderTokens(tokenAddress);
//         const fee = await poolContract.fee();
//         const liquidity = await poolContract.liquidity();
//         const slot0 = await poolContract.slot0();

//         console.log("Pool token0:", token0);
//         console.log("Pool token1:", token1);
//         console.log("Pool fee:", fee);
//         console.log("Pool initial liquidity:", liquidity.toString());
//         console.log("Pool sqrtPriceX96:", slot0.sqrtPriceX96.toString());
//         console.log("Pool tick:", slot0.tick.toString());

//         expect(fee).to.equal(3000); // 0.3% fee
//         expect(liquidity).to.equal(0); // Liquidity should be 0 before adding initial liquidity
//         expect(slot0.sqrtPriceX96).to.be.gt(0);
//         expect([token0, token1]).to.include(tokenAddress);
//         expect([token0, token1]).to.include(wethAddress);
//         console.log("Pool setup verified successfully.");

//         // Step 3: Add Initial Liquidity
//         console.log("Step 3: Adding initial liquidity...");
//         const tokenAmount = ethers.BigNumber.from(TOKEN_AMOUNT);
//         console.log("Token amount for initial liquidity:", ethers.utils.formatEther(tokenAmount), "tokens");
//         console.log("ETH amount for initial liquidity:", ethers.utils.formatEther(ethAmount), "ETH");

//         // Approve token spending
//         const approveTx = await customToken.connect(user).approve(mainEngine.address, tokenAmount);
//         console.log("Token approval transaction hash:", approveTx.hash);
//         await approveTx.wait();
//         console.log("Token approval granted.");

//         const Token0 = new Token(await ethers.provider.getNetwork().then(n => n.chainId), token0, 18);
//         const Token1 = new Token(await ethers.provider.getNetwork().then(n => n.chainId), token1, 18);

//         const pool = new Pool(
//             Token0,
//             Token1,
//             3000,
//             slot0.sqrtPriceX96.toString(),
//             '0', // liquidity is 0 before adding initial liquidity
//             slot0.tick
//         );

//         console.log("Calculating position...");

//         // Create separate variables for amount0 and amount1
//         const amount0 = token0.toLowerCase() === tokenAddress.toLowerCase() ? tokenAmount : ethAmount;
//         const amount1 = token1.toLowerCase() === tokenAddress.toLowerCase() ? tokenAmount : ethAmount;
//         const network = await ethers.provider.getNetwork();
//         const chainId = network.chainId;
//         console.log("Current network:", network.name);
//         console.log("Chain ID:", chainId);

//         // Use calculateWideTicks to get the tick range

//         // const { lowerTick, upperTick } = await calculateWideTicks(
//         //     mainEngine,
//         //     token0,
//         //     token1,
//         //     poolAddress,
//         //     Token0.decimals,
//         //     Token1.decimals,
//         //     3000, // fee,
//         //     chainId

//         // );



//         // Create the position
//         // Create the position
//         function getTickSpacing(fee: number): number {
//             console.log(`Getting tick spacing for fee: ${fee}`);
//             let tickSpacing: number;
//             switch (fee) {
//                 case 100:
//                     tickSpacing = 1;
//                     break;
//                 case 500:
//                     tickSpacing = 10;
//                     break;
//                 case 3000:
//                     tickSpacing = 60;
//                     break;
//                 case 10000:
//                     tickSpacing = 200;
//                     break;
//                 default:
//                     throw new Error(`Invalid fee: ${fee}`);
//             }
//             console.log(`Tick spacing for fee ${fee}: ${tickSpacing}`);
//             return tickSpacing;
//         }
//         const tickSpacing = getTickSpacing(fee);
//         const lowerTick = nearestUsableTick(-273496, tickSpacing);
//         const upperTick = nearestUsableTick(273496, tickSpacing);
//         const position = Position.fromAmounts({
//             pool,
//             tickLower: lowerTick,
//             tickUpper: upperTick,
//             amount0: amount0,
//             amount1: amount1.toString(),
//             useFullPrecision: true,
//         });

//         console.log("Calculated position:");
//         console.log(position);
//         console.log("Tick lower:", position.tickLower);
//         console.log("Tick upper:", position.tickUpper);

//         console.log("thia is the amount0", amount0);
//         console.log("this is the amount1 oooo", amount1);



//         try {
//             // const addLiquidityTx = await mainEngine.connect(user).testAddInitialLiquidity(
//             //     tokenAddress,
//             //     3000, // fee
//             //     position.tickLower,
//             //     position.tickUpper,
//             //     amount0.toString(),
//             //     amount1.toString(),
//             //     0, // amount0Min
//             //     0 // amount1Min
//             // );
//             const token0Decimals =  Token0.decimals;
//             const token1Decimals =  Token1.decimals;
//             console.log("this is the token0 decimals", token0Decimals);
//             console.log("this is the token1 decimals ", token1Decimals);

//             // Format the amounts
//             const formattedAmount0 = ethers.utils.parseUnits(amount0.toString(), token0Decimals).toString();
//             const formattedAmount1 = ethers.utils.parseUnits(amount1.toString(), token1Decimals).toString();
//             console.log("this is the formattted amount 0", formattedAmount0);
//             console.log("this is the formatted amount 1", formattedAmount1);
            
//             // Now use these formatted amounts in your function call
//             const addLiquidityTx = await mainEngine.connect(user).testAddInitialLiquidity(
//                 tokenAddress,
//                 3000,
//                 position.tickLower,
//                 position.tickUpper,
//                 formattedAmount0,
//                 formattedAmount1,
//                 0,
//                 0,
//                 { gasLimit: 1000000 } // Increase gas limit
//             );
//             console.log("Add liquidity transaction hash:", addLiquidityTx.hash);
//             const addLiquidityReceipt = await addLiquidityTx.wait();
//             console.log("Initial liquidity added. Gas used:", addLiquidityReceipt.gasUsed.toString());

//             const liquidityAddedEvent = addLiquidityReceipt.events?.find(e => e.event === "LiquidityAdded");
//             expect(liquidityAddedEvent).to.not.be.undefined;
//         } catch (error) {
//             console.error("Error adding initial liquidity:", error);
//             throw error; // Re-throw the error to fail the test
//         }

//         // Step 4: Verify Initial Liquidity
//         console.log("Step 4: Verifying initial liquidity...");
//         console.log("LiquidityAdded event found.");

//         const tokenInfo = await mainEngine.tokenInfo(tokenAddress);
//         console.log("Token info:");
//         console.log("Initial liquidity added:", tokenInfo.initialLiquidityAdded);
//         console.log("Liquidity:", tokenInfo.liquidity.toString());
//         console.log("Position ID:", tokenInfo.positionId.toString());

//         expect(tokenInfo.initialLiquidityAdded).to.be.true;
//         expect(tokenInfo.liquidity).to.be.gt(0);

//         const updatedPool = new Pool(
//             Token0,
//             Token1,
//             3000,
//             (await poolContract.slot0()).sqrtPriceX96.toString(),
//             tokenInfo.liquidity.toString(),
//             (await poolContract.slot0()).tick
//         );

//         console.log("Updated pool info:");
//         console.log("Liquidity:", updatedPool.liquidity.toString());
//         console.log("Tick:", updatedPool.tickCurrent);
//         console.log("SqrtPriceX96:", updatedPool.sqrtRatioX96.toString());

//         // Check token balances
//         console.log("Checking token balances...");
//         const userTokenBalance = await customToken.balanceOf(user.address);
//         //@ts-ignore
//         const mainEngineTokenBalance = await customToken.balanceOf(mainEngine.address);
//         const userEthBalance = await ethers.provider.getBalance(user.address);
//         //@ts-ignore
//         const mainEngineEthBalance = await ethers.provider.getBalance(mainEngine.address);

//         console.log("User token balance:", ethers.utils.formatEther(userTokenBalance));
//         console.log("MainEngine token balance:", ethers.utils.formatEther(mainEngineTokenBalance));
//         console.log("User ETH balance:", ethers.utils.formatEther(userEthBalance));
//         console.log("MainEngine ETH balance:", ethers.utils.formatEther(mainEngineEthBalance));

//         expect(mainEngineTokenBalance).to.be.gt(0);
//         expect(mainEngineEthBalance).to.be.gt(0);

//         // Check position
//         console.log("Checking position details...");
//         const positionId = tokenInfo.positionId;
//         const positionDetails = await mainEngine.deposits(positionId);
//         console.log("Position details:");
//         console.log("Liquidity:", positionDetails.liquidity.toString());
//         console.log("Token0:", positionDetails.token0);
//         console.log("Token1:", positionDetails.token1);

//         expect(positionDetails.liquidity).to.be.gt(0);

//         // Verify pool state
//         console.log("Verifying final pool state...");
//         const poolLiquidity = await poolContract.liquidity();
//         const poolSlot0 = await poolContract.slot0();
//         console.log("Final pool state:");
//         console.log("Liquidity:", poolLiquidity.toString());
//         console.log("Tick:", poolSlot0.tick.toString());
//         console.log("SqrtPriceX96:", poolSlot0.sqrtPriceX96.toString());

//         expect(poolLiquidity).to.equal(tokenInfo.liquidity);
//         expect(poolSlot0.tick).to.be.within(position.tickLower, position.tickUpper);

//         // Step 6: Calculate and log token/ETH price using sqrtPriceX96
//         console.log("Step 6: Calculating and logging token/ETH price");

//         // Use orderTokens function to determine the correct order
//         const [token0Address_, token1Address_] = await mainEngine.orderTokens(tokenAddress);
//         const token0_ = await ethers.getContractAt("IERC20Metadata", token0Address_);
//         const token1_ = await ethers.getContractAt("IERC20Metadata", token1Address_);
//         const token0Decimals = await token0_.decimals();
//         const token1Decimals = await token1_.decimals();
//         const token0Symbol = await token0_.symbol();
//         const token1Symbol = await token1_.symbol();

//         const tokenA = new Token(31337, token0Address_, token0Decimals, token0Symbol, await token0_.name());
//         const tokenB = new Token(31337, token1Address_, token1Decimals, token1Symbol, await token1_.name());

//         function calculatePrice(sqrtPriceX96: BigNumber, token0Decimals: number, token1Decimals: number): {
//             price0: number,
//             price1: number,
//             price0Wei: string,
//             price1Wei: string
//         } {
//             const sqrtPriceX96Number = parseFloat(sqrtPriceX96.toString());

//             const buyOneOfToken0 = ((sqrtPriceX96Number / 2 ** 96) ** 2) / (10 ** token1Decimals / 10 ** token0Decimals);
//             const buyOneOfToken1 = 1 / buyOneOfToken0;

//             console.log("price of token0 in value of token1 : " + buyOneOfToken0.toFixed(token1Decimals));
//             console.log("price of token1 in value of token0 : " + buyOneOfToken1.toFixed(token0Decimals));
//             console.log("");

//             // Convert to wei
//             const buyOneOfToken0Wei = Math.floor(buyOneOfToken0 * (10 ** token1Decimals)).toLocaleString('fullwide', { useGrouping: false });
//             const buyOneOfToken1Wei = Math.floor(buyOneOfToken1 * (10 ** token0Decimals)).toLocaleString('fullwide', { useGrouping: false });

//             console.log("price of token0 in value of token1 in lowest decimal : " + buyOneOfToken0Wei);
//             console.log("price of token1 in value of token0 in lowest decimal : " + buyOneOfToken1Wei);
//             console.log("");

//             return {
//                 price0: buyOneOfToken0,
//                 price1: buyOneOfToken1,
//                 price0Wei: buyOneOfToken0Wei,
//                 price1Wei: buyOneOfToken1Wei
//             };
//         }

//         const slot0_ = await poolContract.slot0();
//         console.log("this is the slot0:", slot0_);
//         const sqrtPriceX96 = slot0_.sqrtPriceX96;
//         console.log("this is the sqrtPriceX96:", sqrtPriceX96);

//         const prices = calculatePrice(sqrtPriceX96, token0Decimals, token1Decimals);
//         console.log(`Current pool price:`);


//         const ethPrice = 1000; // Assuming 1 ETH = $1000
//         console.log(`\nAssuming 1 ETH = $${ethPrice}:`);
//         if (token1Address_ === wethAddress) {
//             console.log(`1 ${token0Symbol} = $${(prices.price1 * ethPrice).toFixed(2)}`);
//             console.log(`$1 = ${(1 / (prices.price1 * ethPrice)).toFixed(6)} ${token0Symbol}`);
//         } else {
//             console.log(`1 ${token1Symbol} = $${(prices.price0 * ethPrice).toFixed(2)}`);
//             console.log(`$1 = ${(1 / (prices.price0 * ethPrice)).toFixed(6)} ${token1Symbol}`);
//         }

//         console.log("Main test completed successfully.");
//     });

//     afterEach(async function () {
//         // This will run after each test, regardless of pass or fail
//         console.log("it ran ppppppppppppppppppppppppppppppppppppppppp");
//         await collectingBackEth(user, mainEngine, tokenAddress);
//         // Assuming there's a reset function
//         // Or you could redeploy the contract here
//         // Or reset any external services or mocks
//     });

//     after(async function () {
//         console.log("Cleaning up...");
//         // Any cleanup code if needed
//     });

//     // function nearestUsableTick(tick: number, tickSpacing: number): number {
//     //     return Math.round(tick / tickSpacing) * tickSpacing;
//     // }
// });



import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MainEngine, CustomToken } from "../../typechain-types";
import { DeployMainEngine } from "../../script/deployMainEngine.s";
import { Pool, Position, NonfungiblePositionManager, nearestUsableTick, TickMath } from '@uniswap/v3-sdk';
import { Token } from '@uniswap/sdk-core';
import { abi as IUniswapV3PoolABI } from '@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json';
import dotenv from "dotenv";
import { TOKEN_AMOUNT, ETH_AMOUNT } from "./constants";
import { collectingBackEth } from "./collect-liquidity";

dotenv.config();

describe("MainEngine Integration Test", function () {
    this.timeout(12000000); // 2 minutes

    let mainEngine: MainEngine;
    let deployer: SignerWithAddress;
    let user: SignerWithAddress;
    let wethAddress: string;

    before(async function () {
        console.log("Setting up test environment...");
        [deployer] = await ethers.getSigners();
        user = await ethers.getSigner(process.env.SEPOLIA_TEST_WALLET!);
        console.log("Deployer address:", deployer.address);
        console.log("User address:", user.address);

        const network = await ethers.provider.getNetwork();
        console.log("Current network:", network.name);
        console.log("Current block number:", await ethers.provider.getBlockNumber());

        mainEngine = await DeployMainEngine(network);
        console.log("MainEngine deployed at:", mainEngine.address);

        wethAddress = await mainEngine.WETH9();
        console.log("WETH9 address:", wethAddress);

        console.log("Test environment setup complete.");
    });

    it("should create a token and add liquidity in one transaction", async function () {
        console.log("Starting main test...");

        const name = "Test Token";
        const symbol = "TST";
        const description = "A test token for integration testing";
        const imageUrl = "https://example.com/test-token.png";
        const initialSupply = ethers.BigNumber.from(TOKEN_AMOUNT);
        const lockedLiquidityPercentage = 50; // 50% locked
        const fee = 3000; // 0.3% fee
        const ethAmount = ethers.BigNumber.from(ETH_AMOUNT);

        console.log("Creating token and adding liquidity with parameters:");
        console.log("Name:", name);
        console.log("Symbol:", symbol);
        console.log("Description:", description);
        console.log("Image URL:", imageUrl);
        console.log("Initial Supply:", initialSupply.toString());
        console.log("Locked Liquidity Percentage:", lockedLiquidityPercentage);
        console.log("Fee:", fee);
        console.log("ETH amount:", ethers.utils.formatEther(ethAmount), "ETH");

        // Calculate ticks
        const tickSpacing = 60; // For 0.3% fee tier
        const tickLower = nearestUsableTick(-273496, tickSpacing);
        const tickUpper = nearestUsableTick(273496, tickSpacing);

        const createAndAddLiquidityTx = await mainEngine.connect(user).createTokenAndAddLiquidity(
            name,
            symbol,
            description,
            imageUrl,
            initialSupply,
            lockedLiquidityPercentage,
            fee,
            tickLower,
            tickUpper,
            initialSupply, // amount0Desired
            ethAmount, // amount1Desired
            0, // amount0Min
            0, // amount1Min
            { value: ethAmount, gasLimit: 5000000 }
        );

        console.log("Create token and add liquidity transaction hash:", createAndAddLiquidityTx.hash);
        const receipt = await createAndAddLiquidityTx.wait();
        console.log("Transaction mined. Gas used:", receipt.gasUsed.toString());

        const tokenCreatedEvent = receipt.events?.find(e => e.event === "TokenCreated");
        if (!tokenCreatedEvent || !tokenCreatedEvent.args) {
            throw new Error("TokenCreated event not found in transaction receipt");
        }

        const tokenAddress = tokenCreatedEvent.args.tokenAddress;
        console.log("Token created at address:", tokenAddress);

        // Verify token creation and liquidity addition
        const customToken = await ethers.getContractAt("CustomToken", tokenAddress) as CustomToken;
        const tokenInfo = await mainEngine.tokenInfo(tokenAddress);

        console.log("Verifying token and liquidity details...");
        console.log("Token name:", await customToken.name());
        console.log("Token symbol:", await customToken.symbol());
        console.log("Token description:", await customToken.getDescription());
        console.log("Token image URL:", await customToken.getImageUrl());
        console.log("Token total supply:", (await customToken.totalSupply()).toString());
        console.log("Token owner:", await customToken.owner());
        console.log("Initial liquidity added:", tokenInfo.initialLiquidityAdded);
        console.log("Liquidity:", tokenInfo.liquidity.toString());
        console.log("Position ID:", tokenInfo.positionId.toString());
        console.log("Locked liquidity percentage:", tokenInfo.lockedLiquidityPercentage.toString());

        expect(await customToken.name()).to.equal(name);
        expect(await customToken.symbol()).to.equal(symbol);
        expect(await customToken.getDescription()).to.equal(description);
        expect(await customToken.getImageUrl()).to.equal(imageUrl);
        expect(await customToken.totalSupply()).to.equal(initialSupply);
        expect(await customToken.owner()).to.equal(mainEngine.address);
        expect(tokenInfo.initialLiquidityAdded).to.be.true;
        expect(tokenInfo.liquidity).to.be.gt(0);
        expect(tokenInfo.positionId).to.be.gt(0);
        expect(tokenInfo.lockedLiquidityPercentage).to.equal(lockedLiquidityPercentage);

        // Verify pool setup
        const poolAddress = tokenInfo.pool;
        console.log("Pool created at address:", poolAddress);

        const poolContract = new ethers.Contract(poolAddress, IUniswapV3PoolABI, ethers.provider);
        const [token0, token1] = await mainEngine.orderTokens(tokenAddress);
        const poolFee = await poolContract.fee();
        const poolLiquidity = await poolContract.liquidity();
        const slot0 = await poolContract.slot0();

        console.log("Pool token0:", token0);
        console.log("Pool token1:", token1);
        console.log("Pool fee:", poolFee);
        console.log("Pool liquidity:", poolLiquidity.toString());
        console.log("Pool sqrtPriceX96:", slot0.sqrtPriceX96.toString());
        console.log("Pool tick:", slot0.tick.toString());

        expect(poolFee).to.equal(fee);
        expect(poolLiquidity).to.be.gt(0);
        expect(slot0.sqrtPriceX96).to.be.gt(0);
        expect([token0, token1]).to.include(tokenAddress);
        expect([token0, token1]).to.include(wethAddress);

        console.log("Token creation, pool setup, and initial liquidity addition verified successfully.");
    });

    afterEach(async function () {
        console.log("Collecting back ETH...");
        // await collectingBackEth(user, mainEngine, tokenAddress);
    });

    after(async function () {
        console.log("Cleaning up...");
        // Any cleanup code if needed
    });
});