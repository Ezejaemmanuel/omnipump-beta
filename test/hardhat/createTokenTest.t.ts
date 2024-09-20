import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MainEngine, CustomToken } from "../../typechain-types";
import { DeployMainEngine } from "../../script/deployMainEngine.s";
import dotenv from "dotenv";
import { TOKEN_AMOUNT } from "./constants";

dotenv.config();

describe("MainEngineCreateTokenTest", function () {
    this.timeout(60000); 
    let mainEngine: MainEngine;
    let deployer: SignerWithAddress;
    let user: SignerWithAddress;

    before(async function () {
        try {
            console.log("setUp - Starting setup");

            // Log current network and block
            const network = await ethers.provider.getNetwork();
            console.log("Current network:", network);
            console.log("Current block number:", await ethers.provider.getBlockNumber());

            // Get deployer signer
            [deployer] = await ethers.getSigners();
            console.log("setUp - Deployer address:", deployer.address);

            // Get the Sepolia wallet address from the environment variable
            const sepoliaWalletAddress = process.env.SEPOLIA_TEST_WALLET;
            if (!sepoliaWalletAddress) {
                throw new Error("SEPOLIA_TEST_WALLET not set in .env file");
            }

            // Get the signer for the Sepolia wallet address
            user = await ethers.getSigner(sepoliaWalletAddress);
            console.log("setUp - User address:", user.address);

            // Verify balances
            await logBalance(deployer.address);
            await logBalance(user.address);

            // Deploy MainEngine
            mainEngine = await DeployMainEngine(network);
            console.log("setUp - MainEngine deployed at:", mainEngine.address);

            // Log MainEngine details
            console.log("setUp - MainEngine factory address:", await mainEngine.factory());
            console.log("setUp - MainEngine nonfungiblePositionManager address:", await mainEngine.nonfungiblePositionManager());
            console.log("setUp - MainEngine swapRouter address:", await mainEngine.swapRouter());
            console.log("setUp - MainEngine WETH9 address:", await mainEngine.WETH9());

            console.log("setUp - Setup completed");
        } catch (error) {
            console.error("Error in setUp:", error);
            throw error;
        }
    });

    it("should create a token", async function () {
        try {
            console.log("createTestToken - Starting token creation");

            const name = "Test Token";
            const symbol = "TST";
            const description = "A test token";
            const imageUrl = "https://example.com/image.png";
            const initialSupply = TOKEN_AMOUNT; // 1 million tokens

            console.log("createTestToken - Creating token");
            const tx = await mainEngine.connect(user).createTokenForTest(name, symbol, description, imageUrl, initialSupply);
            console.log("createTestToken - Transaction hash:", tx.hash);

            const receipt = await tx.wait();
            console.log("createTestToken - Transaction mined. Gas used:", receipt.gasUsed.toString());

            const tokenCreatedEvent = receipt.events?.find(e => e.event === "TokenCreated");
            if (!tokenCreatedEvent || !tokenCreatedEvent.args) {
                throw new Error("TokenCreated event not found in transaction receipt");
            }

            const tokenAddress = tokenCreatedEvent.args.tokenAddress;
            console.log("createTestToken - Token created at address:", tokenAddress);

            const testToken = await ethers.getContractAt("CustomToken", tokenAddress) as CustomToken;

            // Verify token creation
            console.log("createTestToken - Verifying token details");
            expect(await testToken.name()).to.equal(name, "Token name mismatch");
            expect(await testToken.symbol()).to.equal(symbol, "Token symbol mismatch");
            expect(await testToken.getDescription()).to.equal(description, "Token description mismatch");
            expect(await testToken.getImageUrl()).to.equal(imageUrl, "Token image URL mismatch");
            expect(await testToken.totalSupply()).to.equal(initialSupply, "Token initial supply mismatch");
            expect(await testToken.owner()).to.equal(mainEngine.address, "Token owner should be the MainEngine");

            console.log("createTestToken - Token creation verified");
        } catch (error) {
            console.error("Error in createTestToken:", error);
            throw error;
        }
    });

    after(async function () {
        console.log("tearDown - Cleaning up");
        // Any cleanup code if needed
    });

    // Helper function to log balance
    async function logBalance(address: string) {
        const balance = await ethers.provider.getBalance(address);
        console.log(`Balance of ${address}: ${ethers.utils.formatEther(balance)} ETH`);
    }
});