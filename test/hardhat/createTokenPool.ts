


import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MainEngine, CustomToken } from "../../typechain-types";
import { DeployMainEngine } from "../../script/deployMainEngine.s";
import { abi as IUniswapV3PoolABI } from '@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json';
import { abi as NonfungiblePositionManagerABI } from '@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json';
import dotenv from "dotenv";
import { ETH_AMOUNT, TOKEN_AMOUNT } from "./constants";
import { Token } from "@uniswap/sdk-core";
import { Pool } from "@uniswap/v3-sdk";
import JSBI from "jsbi";
import { BigNumber } from "ethers";

dotenv.config();

describe("MainEngine Pool Setup Test", function () {
    this.timeout(120000); // 2 minutes

    let mainEngine: MainEngine;
    let deployer: SignerWithAddress;
    let user: SignerWithAddress;
    let customToken: CustomToken;
    let wethAddress: string;

    before(async function () {
        try {
            console.log("setUp - Starting setup");

            const network = await ethers.provider.getNetwork();
            console.log("Current network:", network.name);
            console.log("Current block number:", await ethers.provider.getBlockNumber());

            [deployer] = await ethers.getSigners();
            console.log("setUp - Deployer address:", deployer.address);

            const sepoliaWalletAddress = process.env.SEPOLIA_TEST_WALLET;
            if (!sepoliaWalletAddress) {
                throw new Error("SEPOLIA_TEST_WALLET not set in .env file");
            }

            user = await ethers.getSigner(sepoliaWalletAddress);
            console.log("setUp - User address:", user.address);

            await logBalance(deployer.address);
            await logBalance(user.address);

            mainEngine = await DeployMainEngine(network);
            //@ts-ignore

            console.log("setUp - MainEngine deployed at:", mainEngine.address);

            wethAddress = await mainEngine.WETH9();
            console.log("setUp - MainEngine WETH9 address:", wethAddress);

            console.log("setUp - Setup completed");
        } catch (error) {
            console.error("Error in setUp:", error);
            throw error;
        }
    });

    it("should setup a pool correctly", async function () {
        try {
            console.log("Pool Setup Test - Starting");

            // Step 1: Create Token
            const name = "Test Token";
            const symbol = "TST";
            const description = "A test token for pool setup";
            const imageUrl = "https://example.com/test-token.png";
            const initialSupply = TOKEN_AMOUNT; // 1 million tokens

            console.log("Step 1: Creating token");
            const createTokenTx = await mainEngine.connect(user).createTokenForTest(name, symbol, description, imageUrl, initialSupply);
            const createTokenReceipt = await createTokenTx.wait();

            const tokenCreatedEvent = createTokenReceipt.events?.find(e => e.event === "TokenCreated");
            if (!tokenCreatedEvent || !tokenCreatedEvent.args) {
                throw new Error("TokenCreated event not found in transaction receipt");
            }

            const tokenAddress = tokenCreatedEvent.args.tokenAddress;
            console.log("Token created at address:", tokenAddress);

            customToken = await ethers.getContractAt("CustomToken", tokenAddress) as CustomToken;

            // Step 2: Setup pool
            console.log("Step 2: Setting up pool");
            const ethAmount = ETH_AMOUNT; // 1 ETH for pool setup
            const setupPoolTx = await mainEngine.connect(user).testSetupPool(tokenAddress, { value: ethAmount });
            const setupPoolReceipt = await setupPoolTx.wait();

            const poolCreatedEvent = setupPoolReceipt.events?.find(e => e.event === "PoolCreated");
            if (!poolCreatedEvent || !poolCreatedEvent.args) {
                throw new Error("PoolCreated event not found in transaction receipt");
            }

            const poolAddress = poolCreatedEvent.args.pool;
            console.log("Pool created at address:", poolAddress);

            // Step 3: Verify pool setup
            console.log("Step 3: Verifying pool setup");
            const poolContract = new ethers.Contract(poolAddress, IUniswapV3PoolABI, ethers.provider);

            const token0Address = await poolContract.token0();
            const token1Address = await poolContract.token1();
            const fee = await poolContract.fee();
            const liquidity = await poolContract.liquidity();
            const slot0 = await poolContract.slot0();

            console.log("Pool token0:", token0Address);
            console.log("Pool token1:", token1Address);
            console.log("Pool fee:", fee);
            console.log("Pool liquidity:", liquidity.toString());
            console.log("Pool sqrtPriceX96:", slot0.sqrtPriceX96.toString());
            console.log("Pool tick:", slot0.tick.toString());

            // Assertions
            expect(fee).to.equal(3000); // 0.3% fee
            expect(liquidity).to.equal(0); // Expect zero liquidity initially
            expect(slot0.sqrtPriceX96).to.be.gt(0);
            expect([token0Address, token1Address]).to.include(tokenAddress);
            expect([token0Address, token1Address]).to.include(wethAddress);

            // Step 4: Check token balances
            console.log("Step 4: Checking token balances");
            const userTokenBalance = await customToken.balanceOf(user.address);
            //@ts-ignore
            const mainEngineTokenBalance = await customToken.balanceOf(mainEngine.address);
            const userEthBalance = await ethers.provider.getBalance(user.address);
            //@ts-ignore
            const mainEngineEthBalance = await ethers.provider.getBalance(mainEngine.address);

            console.log("User token balance:", ethers.utils.formatEther(userTokenBalance));
            console.log("MainEngine token balance:", ethers.utils.formatEther(mainEngineTokenBalance));
            console.log("User ETH balance:", ethers.utils.formatEther(userEthBalance));
            console.log("MainEngine ETH balance:", ethers.utils.formatEther(mainEngineEthBalance));

            expect(mainEngineTokenBalance).to.equal(initialSupply); // Expect all tokens to be in MainEngine
            expect(mainEngineEthBalance).to.equal(ethAmount); // Expect 1 ETH in MainEngine

            // Step 5: Check Uniswap position
            console.log("Step 5: Checking Uniswap position");
            const tokenInfo = await mainEngine.tokenInfo(tokenAddress);
            const positionId = tokenInfo.positionId;
            console.log("Position ID:", positionId.toString());
            expect(positionId).to.equal(0);

            console.log("Step 6: Checking token/ETH price using Uniswap SDK");

            // Use orderTokens function to determine the correct order
            const [token0Address_, token1Address_] = await mainEngine.orderTokens(tokenAddress);

            const token0 = await ethers.getContractAt("IERC20Metadata", token0Address_);
            const token1 = await ethers.getContractAt("IERC20Metadata", token1Address_);

            const token0Decimals = await token0.decimals();
            const token1Decimals = await token1.decimals();

            const token0Symbol = await token0.symbol();
            const token1Symbol = await token1.symbol();

            const tokenA = new Token(31337, token0Address_, token0Decimals, token0Symbol, await token0.name());
            const tokenB = new Token(31337, token1Address_, token1Decimals, token1Symbol, await token1.name());

            // Step 6: Calculate and log token/ETH price using sqrtPriceX96
            console.log("Step 6: Calculating and logging token/ETH price");


            function calculatePrice(sqrtPriceX96: BigNumber, token0Decimals: number, token1Decimals: number): { price0: number, price1: number } {
                const sqrtPriceX96BI = JSBI.BigInt(sqrtPriceX96.toString());
                const Q96 = JSBI.exponentiate(JSBI.BigInt(2), JSBI.BigInt(96));
                const sqrtPrice = JSBI.divide(sqrtPriceX96BI, Q96);

                const price = JSBI.divide(
                    JSBI.multiply(sqrtPrice, sqrtPrice),
                    JSBI.exponentiate(JSBI.BigInt(10), JSBI.BigInt(token0Decimals))
                );

                const decimalAdjustment = JSBI.exponentiate(
                    JSBI.BigInt(10),
                    JSBI.BigInt(token1Decimals - token0Decimals)
                );

                const priceAdjusted = JSBI.divide(price, decimalAdjustment);

                const priceNumber = Number(priceAdjusted.toString()) / (10 ** token1Decimals);

                return {
                    price0: priceNumber,
                    price1: 1 / priceNumber
                };
            }


            const slot0_ = await poolContract.slot0();
            console.log("this is the slot0:", slot0_);
            const sqrtPriceX96 = slot0_.sqrtPriceX96;
            console.log("this is the sqrtPriceX96:", sqrtPriceX96);

            const prices = calculatePrice(sqrtPriceX96, token0Decimals, token1Decimals);

            console.log(`Current pool price:`);
            console.log(`1 ${token0Symbol} = ${prices.price1.toFixed(6)} ${token1Symbol}`);
            console.log(`1 ${token1Symbol} = ${prices.price0.toFixed(6)} ${token0Symbol}`);

            const ethPrice = 1000; // Assuming 1 ETH = $1000
            console.log(`\nAssuming 1 ETH = $${ethPrice}:`);

            if (token1Address === wethAddress) {
                console.log(`1 ${token0Symbol} = $${(prices.price1 * ethPrice).toFixed(2)}`);
                console.log(`$1 = ${(1 / (prices.price1 * ethPrice)).toFixed(6)} ${token0Symbol}`);
            } else {
                console.log(`1 ${token1Symbol} = $${(prices.price0 * ethPrice).toFixed(2)}`);
                console.log(`$1 = ${(1 / (prices.price0 * ethPrice)).toFixed(6)} ${token1Symbol}`);
            }

            console.log("Pool Setup Test - Completed successfully");
        } catch (error) {
            console.error("Error in pool setup test:", error);
            throw error;
        }
    });

    after(async function () {
        console.log("tearDown - Cleaning up");
        // Any cleanup code if needed
    });

    async function logBalance(address: string) {
        const balance = await ethers.provider.getBalance(address);
        console.log(`Balance of ${address}: ${ethers.utils.formatEther(balance)} ETH`);
    }
});