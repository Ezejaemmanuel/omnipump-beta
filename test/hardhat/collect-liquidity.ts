import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MainEngine } from "../../typechain-types/src/newMainEngine-2.sol";
import { ethers } from "hardhat";

export async function collectingBackEth(user: SignerWithAddress, mainEngine: MainEngine, tokenAddress: string) {
    console.log("Starting cleanup process...");

    try {
        // Get the token info
        const tokenInfo = await mainEngine.tokenInfo(tokenAddress);
        console.log("Token info:", tokenInfo);

        // Remove liquidity
        if (tokenInfo.liquidity.gt(0)) {
            console.log("Removing liquidity...");
            try {
                const tx = await mainEngine.connect(user).withdrawLiquidity(tokenAddress, tokenInfo.liquidity);
                await tx.wait();
                console.log("Liquidity removed successfully");
            } catch (error) {
                console.error("Error removing liquidity:", error);
            }
        } else {
            console.log("No liquidity to remove");
        }

        // Collect any remaining fees
        console.log("Collecting fees...");
        try {
            const [amount0, amount1] = await mainEngine.connect(user).collectFees(tokenAddress);
            console.log("Fees collected:", amount0.toString(), amount1.toString());
        } catch (error) {
            console.error("Error collecting fees:", error);
        }

        // Swap any remaining tokens for ETH
        try {
            const tokenContract = await ethers.getContractAt("CustomToken", tokenAddress);
            const tokenBalance = await tokenContract.balanceOf(user.address);
            console.log("Token balance:", tokenBalance.toString());
            if (tokenBalance.gt(0)) {
                console.log("Swapping remaining tokens for ETH...");
                const tx = await mainEngine.connect(user).swapExactTokensForETH(tokenAddress, tokenBalance, 0);
                await tx.wait();
                console.log("Tokens swapped for ETH");
            } else {
                console.log("No tokens to swap");
            }
        } catch (error) {
            console.error("Error swapping tokens for ETH:", error);
        }

        // Get final ETH balance
        const finalBalance = await ethers.provider.getBalance(user.address);
        console.log("Final ETH balance:", ethers.utils.formatEther(finalBalance));

    } catch (error) {
        console.error("Error during cleanup process:", error);
    }

    console.log("Cleanup process completed");
}