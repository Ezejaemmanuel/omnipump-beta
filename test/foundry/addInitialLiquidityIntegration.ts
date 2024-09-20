// import { expect } from "chai";
// import { ethers } from "hardhat";
// import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
// import {
//     MainEngine,
//     CustomToken,
//     IUniswapV3Pool,
//     INonfungiblePositionManager
// } from "../typechain-types";

// describe("MainEngine Integration Test", function () {
//     let mainEngine: MainEngine;
//     let deployer: SignerWithAddress;
//     let user: SignerWithAddress;
//     const INITIAL_SUPPLY = ethers.utils.parseEther("1000000000000");
//     const ETH_AMOUNT = ethers.utils.parseEther("1000");

//     before(async function () {
//         console.log("Setting up test environment");
//         [deployer, user] = await ethers.getSigners();

//         // Deploy MainEngine
//         const MainEngineFactory = await ethers.getContractFactory("MainEngine");
//         mainEngine = await MainEngineFactory.deploy(
//             // Add constructor parameters here
//         );
//         await mainEngine.deployed();

//         console.log("MainEngine deployed at:", mainEngine.address);
//     });

//     it("should create token, setup pool, and add initial liquidity", async function () {
//         console.log("Starting integration test");

//         // Step 1: Create Token
//         console.log("Step 1: Creating token");
//         const tokenAddress = await createAndVerifyToken();

//         // Step 2: Setup Pool
//         console.log("Step 2: Setting up pool");
//         const poolAddress = await setupAndVerifyPool(tokenAddress);

//         // Step 3: Add Initial Liquidity
//         console.log("Step 3: Adding initial liquidity");
//         await addAndVerifyInitialLiquidity(tokenAddress, poolAddress);

//         console.log("Integration test completed successfully");
//     });

//     async function createAndVerifyToken(): Promise<string> {
//         console.log("Starting token creation");
//         const name = "Test Token";
//         const symbol = "TST";
//         const description = "A test token";
//         const imageUrl = "https://example.com/image.png";

//         const tx = await mainEngine.connect(user).createTokenForTest(
//             name, symbol, description, imageUrl, INITIAL_SUPPLY
//         );
//         const receipt = await tx.wait();
//         const tokenCreatedEvent = receipt.events?.find(e => e.event === "TokenCreated");
//         const tokenAddress = tokenCreatedEvent?.args?.tokenAddress;

//         console.log("Token created at address:", tokenAddress);

//         const token = await ethers.getContractAt("CustomToken", tokenAddress);

//         // Verify token creation
//         expect(await token.name()).to.equal(name);
//         expect(await token.symbol()).to.equal(symbol);
//         expect(await token.getDescription()).to.equal(description);
//         expect(await token.getImageUrl()).to.equal(imageUrl);
//         expect(await token.totalSupply()).to.equal(INITIAL_SUPPLY);
//         expect(await token.owner()).to.equal(mainEngine.address);

//         console.log("Token properties verified");
//         return tokenAddress;
//     }

//     async function setupAndVerifyPool(tokenAddress: string): Promise<string> {
//         console.log("Starting pool setup");
//         const ethAmount = ethers.utils.parseEther("1");

//         await mainEngine.connect(user).testSetupPool(tokenAddress, { value: ethAmount });

//         const tokenInfo = await mainEngine.tokenInfo(tokenAddress);
//         const poolAddress = tokenInfo.pool;

//         console.log("Pool created at address:", poolAddress);

//         expect(tokenInfo.creator).to.equal(user.address);
//         expect(tokenInfo.isCreated).to.be.true;
//         expect(poolAddress).to.not.equal(ethers.constants.AddressZero);

//         const pool = await ethers.getContractAt("IUniswapV3Pool", poolAddress);

//         console.log("Verifying pool properties");
//         const token0 = await pool.token0();
//         const token1 = await pool.token1();
//         const fee = await pool.fee();

//         console.log("Pool token0:", token0);
//         console.log("Pool token1:", token1);
//         console.log("Pool fee:", fee);

//         expect(token0.toLowerCase() === tokenAddress.toLowerCase() ||
//             token1.toLowerCase() === tokenAddress.toLowerCase()).to.be.true;
//         expect(token0.toLowerCase() === mainEngine.WETH9().toLowerCase() ||
//             token1.toLowerCase() === mainEngine.WETH9().toLowerCase()).to.be.true;
//         expect(fee).to.equal(await mainEngine.poolFee());

//         const factory = await ethers.getContractAt("IUniswapV3Factory", await mainEngine.factory());
//         const factoryPoolAddress = await factory.getPool(token0, token1, fee);
//         expect(factoryPoolAddress).to.equal(poolAddress);

//         console.log("Pool setup and verification completed");
//         return poolAddress;
//     }

//     async function addAndVerifyInitialLiquidity(tokenAddress: string, poolAddress: string) {
//         console.log("Starting initial liquidity addition");
//         const tokenAmount = ethers.utils.parseEther("100000");
//         const ethAmount = ethers.utils.parseEther("10");
//         const lockedLiquidityPercentage = 50;

//         const token = await ethers.getContractAt("CustomToken", tokenAddress);
//         await token.connect(user).approve(mainEngine.address, tokenAmount);

//         console.log("Adding initial liquidity");
//         await mainEngine.connect(user).testAddInitialLiquidity(tokenAddress, tokenAmount, ethAmount);

//         const tokenInfo = await mainEngine.tokenInfo(tokenAddress);

//         console.log("Verifying liquidity addition");
//         console.log("Initial liquidity added:", tokenInfo.initialLiquidityAdded);
//         console.log("Position ID:", tokenInfo.positionId.toString());
//         console.log("Locked percentage:", tokenInfo.lockedLiquidityPercentage.toString());
//         console.log("Withdrawable liquidity:", tokenInfo.withdrawableLiquidity.toString());
//         console.log("Total liquidity:", tokenInfo.liquidity.toString());

//         expect(tokenInfo.initialLiquidityAdded).to.be.true;
//         expect(tokenInfo.positionId).to.not.equal(0);
//         expect(tokenInfo.lockedLiquidityPercentage).to.equal(lockedLiquidityPercentage);
//         expect(tokenInfo.withdrawableLiquidity).to.be.gt(0);
//         expect(tokenInfo.liquidity).to.be.gt(0);

//         const pool = await ethers.getContractAt("IUniswapV3Pool", poolAddress);
//         const slot0 = await pool.slot0();
//         console.log("Pool sqrtPriceX96:", slot0.sqrtPriceX96.toString());
//         expect(slot0.sqrtPriceX96).to.be.gt(0);

//         const positionManager = await ethers.getContractAt("INonfungiblePositionManager", await mainEngine.nonfungiblePositionManager());
//         const position = await positionManager.positions(tokenInfo.positionId);

//         console.log("Verifying position in NonfungiblePositionManager");
//         console.log("Position token0:", position.token0);
//         console.log("Position token1:", position.token1);
//         console.log("Position fee:", position.fee.toString());
//         console.log("Position tickLower:", position.tickLower.toString());
//         console.log("Position tickUpper:", position.tickUpper.toString());
//         console.log("Position liquidity:", position.liquidity.toString());

//         expect(position.token0 < position.token1).to.be.true;
//         expect(position.token0.toLowerCase() === tokenAddress.toLowerCase() ||
//             position.token1.toLowerCase() === tokenAddress.toLowerCase()).to.be.true;
//         expect(position.token0.toLowerCase() === (await mainEngine.WETH9()).toLowerCase() ||
//             position.token1.toLowerCase() === (await mainEngine.WETH9()).toLowerCase()).to.be.true;
//         expect(position.fee).to.equal(await mainEngine.poolFee());
//         expect(position.tickLower).to.be.lt(position.tickUpper);
//         expect(position.liquidity).to.equal(tokenInfo.liquidity);

//         console.log("Initial liquidity addition and verification completed");
//     }
// });