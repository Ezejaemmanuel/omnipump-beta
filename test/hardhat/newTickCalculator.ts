import { Token } from "@uniswap/sdk-core";
import { encodeSqrtRatioX96, TickMath, nearestUsableTick } from "@uniswap/v3-sdk";
import { ethers } from "hardhat";
import JSBI from "jsbi";
import { abi as IUniswapV3PoolABI } from '@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json';
import { MainEngine } from "../../typechain-types";
import bn from 'bignumber.js';

interface PoolInfo {
    SqrtX96: string;
    Decimal0: number;
    Decimal1: number;
}

interface PriceResult {
    buyOneOfToken0: string;
    buyOneOfToken1: string;
    buyOneOfToken0Wei: string;
    buyOneOfToken1Wei: string;
}

export async function calculateWideTicks(
    mainEngine: MainEngine,
    token0Address: string,
    token1Address: string,
    poolAddress: string,
    decimals0: number,
    decimals1: number,
    fee: number,
    chainId: number
) {
    console.log(`Starting calculateWideTicks function with inputs:
    token0Address: ${token0Address}
    token1Address: ${token1Address}
    poolAddress: ${poolAddress}
    decimals0: ${decimals0}
    decimals1: ${decimals1}
    fee: ${fee}
    chainId: ${chainId}`);

    console.log("Creating Token objects");
    const token0 = new Token(chainId, token0Address, decimals0);
    const token1 = new Token(chainId, token1Address, decimals1);
    console.log(`Created Token objects:
    token0: ${token0.name} (${token0.address})
    token1: ${token1.name} (${token1.address})`);

    console.log("Getting pool contract instance");
    const poolContract = new ethers.Contract(poolAddress, IUniswapV3PoolABI, ethers.provider);

    console.log("Getting current sqrtPriceX96 from the pool");
    const slot0 = await poolContract.slot0();
    const sqrtPriceX96 = slot0.sqrtPriceX96;
    console.log(`Retrieved sqrtPriceX96 from pool: ${sqrtPriceX96.toString()}`);

    console.log("Calculating current price using GetPrice function");
    const poolInfo: PoolInfo = {
        SqrtX96: sqrtPriceX96.toString(),
        Decimal0: decimals0,
        Decimal1: decimals1
    };
    const {
        buyOneOfToken0,
        buyOneOfToken1,
        buyOneOfToken0Wei,
        buyOneOfToken1Wei
    } = GetPrice(poolInfo);
    console.log("this is the buyoneoftoken0", buyOneOfToken0);

    console.log("Setting price range: 90% below and 90% above current price");
    const currentPriceWei = JSBI.BigInt(buyOneOfToken0Wei);

    const lowerPriceLimit = JSBI.divide(JSBI.multiply(currentPriceWei, JSBI.BigInt(10)), JSBI.BigInt(100)); // 10% of current price
    const upperPriceLimit = JSBI.divide(JSBI.multiply(currentPriceWei, JSBI.BigInt(190)), JSBI.BigInt(100)); // 190% of current price
    console.log(`Set price limits:
    Lower price limit: ${lowerPriceLimit.toString()} ${token1.name} per ${token0.name}
    Upper price limit: ${upperPriceLimit.toString()} ${token1.name} per ${token0.name}`);

    console.log("Converting price limits to sqrt ratios");
    const sqrtLowerPrice = encodeSqrtRatioX96(
        lowerPriceLimit,
        JSBI.exponentiate(JSBI.BigInt(10), JSBI.BigInt(decimals0))
    );
    const sqrtUpperPrice = encodeSqrtRatioX96(
        upperPriceLimit,
        JSBI.exponentiate(JSBI.BigInt(10), JSBI.BigInt(decimals0))
    );
    console.log(`Converted price limits to sqrt ratios:
    sqrtLowerPrice: ${sqrtLowerPrice.toString()}
    sqrtUpperPrice: ${sqrtUpperPrice.toString()}`);

    console.log("Converting sqrt ratios to ticks");
    let lowerTick = TickMath.getTickAtSqrtRatio(sqrtLowerPrice);
    let upperTick = TickMath.getTickAtSqrtRatio(sqrtUpperPrice);
    console.log(`Converted sqrt ratios to ticks:
    lowerTick: ${lowerTick}
    upperTick: ${upperTick}`);

    console.log("Adjusting ticks based on tick spacing");
    const tickSpacing = getTickSpacing(fee);
    lowerTick = nearestUsableTick(lowerTick, tickSpacing);
    upperTick = nearestUsableTick(upperTick, tickSpacing);
    console.log(`Adjusted ticks based on tick spacing (${tickSpacing}):
    lowerTick: ${lowerTick}
    upperTick: ${upperTick}`);

    console.log("Ensuring ticks are within allowed range");
    lowerTick = Math.max(lowerTick, TickMath.MIN_TICK);
    upperTick = Math.min(upperTick, TickMath.MAX_TICK);
    console.log(`Final tick range after ensuring within allowed range:
    lowerTick: ${lowerTick}
    upperTick: ${upperTick}`);

    return { lowerTick, upperTick };
}

function GetPrice(PoolInfo: PoolInfo): PriceResult {
    console.log("Starting GetPrice function");
    console.log(`Input PoolInfo: ${JSON.stringify(PoolInfo)}`);

    console.log("Extracting values from PoolInfo");
    let sqrtPriceX96 = BigInt(PoolInfo.SqrtX96);
    let Decimal0 = PoolInfo.Decimal0;
    let Decimal1 = PoolInfo.Decimal1;

    console.log("Calculating buyOneOfToken0");
    const buyOneOfToken0 = Number((sqrtPriceX96 * sqrtPriceX96 * BigInt(10 ** Decimal0)) / (BigInt(2 ** 192) * BigInt(10 ** Decimal1)));
    console.log(`buyOneOfToken0 (before toFixed): ${buyOneOfToken0}`);
    const buyOneOfToken0Fixed = buyOneOfToken0.toFixed(Decimal1);
    console.log(`buyOneOfToken0 (after toFixed): ${buyOneOfToken0Fixed}`);

    console.log("Calculating buyOneOfToken1");
    const buyOneOfToken1 = (1 / buyOneOfToken0).toFixed(Decimal0);
    console.log(`buyOneOfToken1: ${buyOneOfToken1}`);

    console.log("price of token0 in value of token1 : " + buyOneOfToken0Fixed);
    console.log("price of token1 in value of token0 : " + buyOneOfToken1);
    console.log("");

    console.log("Converting to wei");
    const buyOneOfToken0Wei = Math.floor(buyOneOfToken0 * (10 ** Decimal1)).toLocaleString('fullwide', { useGrouping: false });
    console.log(`buyOneOfToken0Wei: ${buyOneOfToken0Wei}`);
    const buyOneOfToken1Wei = Math.floor(Number(buyOneOfToken1) * (10 ** Decimal0)).toLocaleString('fullwide', { useGrouping: false });
    console.log(`buyOneOfToken1Wei: ${buyOneOfToken1Wei}`);

    console.log("price of token0 in value of token1 in lowest decimal : " + buyOneOfToken0Wei);
    console.log("price of token1 in value of token0 in lowest decimal : " + buyOneOfToken1Wei);
    console.log("");

    console.log("Returning calculated values");
    return {
        buyOneOfToken0: buyOneOfToken0Fixed,
        buyOneOfToken1: buyOneOfToken1,
        buyOneOfToken0Wei: buyOneOfToken0Wei,
        buyOneOfToken1Wei: buyOneOfToken1Wei
    };
}
export function getTickSpacing(fee: number): number {
    console.log(`Getting tick spacing for fee: ${fee}`);
    let tickSpacing: number;
    switch (fee) {
        case 100:
            tickSpacing = 1;
            break;
        case 500:
            tickSpacing = 10;
            break;
        case 3000:
            tickSpacing = 60;
            break;
        case 10000:
            tickSpacing = 200;
            break;
        default:
            throw new Error(`Invalid fee: ${fee}`);
    }
    console.log(`Tick spacing for fee ${fee}: ${tickSpacing}`);
    return tickSpacing;
}