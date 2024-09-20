import { ethers } from "hardhat";
import { MainEngine, MainEngine__factory } from "../typechain-types";
import { IUniswapV3Factory, INonfungiblePositionManager, ISwapRouter, IWETH9 } from "../typechain-types";
import * as dotenv from "dotenv";

dotenv.config();

interface DeploymentInfo {
    factory: string;
    nonfungiblePositionManager: string;
    swapRouter: string;
    WETH9: string;
    tokenDescriptor: string;
    chainId: number;
}

export async function DeployMainEngine(network: any): Promise<MainEngine> {
    console.log("Starting DeployMainEngine script");

    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const chainId = network.chainId;
    console.log("Chain ID:", chainId);

    const info: DeploymentInfo = {
        factory: process.env.UNISWAP_V3_FACTORY || "",
        nonfungiblePositionManager: process.env.NONFUNGIBLE_POSITION_MANAGER || "",
        swapRouter: process.env.SWAP_ROUTER || "",
        WETH9: process.env.WETH9 || "",
        tokenDescriptor: process.env.TOKEN_DESCRIPTOR || "",
        chainId: chainId
    };

    // Deploy MainEngine
    const MainEngineFactory: MainEngine__factory = await ethers.getContractFactory("MainEngine");
    const mainEngine: MainEngine = await MainEngineFactory.deploy(
        info.factory,
        info.nonfungiblePositionManager,
        info.swapRouter,
        info.WETH9
    );
    await mainEngine.deployed();


    //@ts-ignore
    console.log("MainEngine deployed to:", mainEngine.address);

    // Verify deployment
    await verifyDeployment(mainEngine, info);

    logDeploymentInfo(info);

    console.log("DeployMainEngine script completed");
    return mainEngine;
}

async function verifyDeployment(mainEngine: MainEngine, info: DeploymentInfo) {
    console.log("Verifying deployment...");

    // Verify UniswapV3Factory
    const factoryContract: IUniswapV3Factory = await ethers.getContractAt("IUniswapV3Factory", info.factory);
    console.log("UniswapV3Factory address:", info.factory);
    console.log("UniswapV3Factory owner:", await factoryContract.owner());

    // Verify NonfungiblePositionManager
    const npmContract: INonfungiblePositionManager = await ethers.getContractAt("INonfungiblePositionManager", info.nonfungiblePositionManager);
    console.log("NonfungiblePositionManager address:", info.nonfungiblePositionManager);
    console.log("NPM factory:", await npmContract.factory());
    console.log("NPM WETH9:", await npmContract.WETH9());

    // Verify SwapRouter
    console.log("SwapRouter address:", info.swapRouter);

    // Verify WETH9
    const weth: IWETH9 = await ethers.getContractAt("IWETH9", info.WETH9);
    const [deployer] = await ethers.getSigners();
    const wethBalance = await weth.balanceOf(deployer.address);
    console.log("WETH9 address:", info.WETH9);
    console.log("WETH9 balance of deployer:", wethBalance.toString());

    if (wethBalance.eq(0)) {
        console.log("Warning: WETH9 balance is zero. Consider depositing some ETH to WETH for testing.");
    } else {
        console.log("WETH9 balance is non-zero. Good for testing.");
    }

    const ethBalance = await ethers.provider.getBalance(deployer.address);
    console.log("ETH balance of deployer:", ethBalance.toString());

    if (ethBalance.eq(0)) {
        console.log("Warning: ETH balance is zero. Consider adding some ETH for testing.");
    } else {
        console.log("ETH balance is non-zero. Good for testing.");
    }

    // Verify MainEngine
    //@ts-ignore
    console.log("MainEngine address:", mainEngine.address);
    console.log("MainEngine factory:", await mainEngine.factory());
    console.log("MainEngine NPM:", await mainEngine.nonfungiblePositionManager());
    console.log("MainEngine router:", await mainEngine.swapRouter());
    console.log("MainEngine WETH9:", await mainEngine.WETH9());

    console.log("Deployment verification completed");
}

function logDeploymentInfo(info: DeploymentInfo) {
    console.log("Deployment Info:");
    console.log("- Factory:", info.factory);
    console.log("- NonfungiblePositionManager:", info.nonfungiblePositionManager);
    console.log("- SwapRouter:", info.swapRouter);
    console.log("- WETH9:", info.WETH9);
    console.log("- TokenDescriptor:", info.tokenDescriptor);
    console.log("- Chain ID:", info.chainId);
}

// This allows the script to be run directly from the command line
if (require.main === module) {
    ethers.provider.getNetwork().then(network => {
        DeployMainEngine(network)
            .then(() => process.exit(0))
            .catch((error) => {
                console.error(error);
                process.exit(1);
            });
    });
}
