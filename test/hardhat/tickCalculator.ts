
// import { Token, CurrencyAmount } from "@uniswap/sdk-core";
// import { encodeSqrtRatioX96, TickMath, nearestUsableTick, tickToPrice } from "@uniswap/v3-sdk";
// import { Address } from "cluster";
// import JSBI from "jsbi";
// import { MainEngine } from "../../typechain-types";

import { Token } from "@uniswap/sdk-core";
import { encodeSqrtRatioX96, nearestUsableTick, TickMath } from "@uniswap/v3-sdk";
import BigNumber from "bignumber.js";
import { ethers } from "hardhat";
import JSBI from "jsbi";
import { abi as IUniswapV3PoolABI } from '@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json';
import { MainEngine } from "../../typechain-types";


// export async function calculateWideTicks(
//     mainEngine: MainEngine,
//     token0Address: string,
//     token1Address: string,
//     amount0: string,
//     amount1: string,
//     decimals0: number,
//     decimals1: number,
//     fee: number,
//     chainId: number
// ) {
//     console.log(`Starting calculateWideTicks function with inputs:
//     token0Address: ${token0Address}
//     token1Address: ${token1Address}
//     amount0: ${amount0}
//     amount1: ${amount1}
//     decimals0: ${decimals0}
//     decimals1: ${decimals1}
//     fee: ${fee}
//     chainId: ${chainId}`);

//     const token0 = new Token(chainId, token0Address, decimals0);
//     const token1 = new Token(chainId, token1Address, decimals1);
//     console.log(`Created Token objects:
//     token0: ${token0.name} (${token0.address})
//     token1: ${token1.name} (${token1.address})`);

//     const tokenAmount0 = CurrencyAmount.fromRawAmount(token0, JSBI.BigInt(amount0));
//     const tokenAmount1 = CurrencyAmount.fromRawAmount(token1, JSBI.BigInt(amount1));
//     console.log(`Created CurrencyAmount objects:
//     tokenAmount0: ${tokenAmount0.toExact()} ${token0.name}
//     tokenAmount1: ${tokenAmount1.toExact()} ${token1.name}`);

//     const priceRatio = tokenAmount1.divide(tokenAmount0);
//     const currentPrice = parseFloat(priceRatio.toSignificant(30));
//     console.log(`Calculated current price: ${currentPrice} ${token1.name} per ${token0.name}`);

//     // Set range: 1000% below and 1000% above current price
//     const lowerPriceLimit = currentPrice * 0.1; // 10% below (0.1 times the current price)
//     const upperPriceLimit = currentPrice * 10;  // 100% above (10 times the current price)
//     console.log(`Set price limits:
//     Lower price limit: ${lowerPriceLimit} ${token1.name} per ${token0.name}
//     Upper price limit: ${upperPriceLimit} ${token1.name} per ${token0.name}`);

//     const sqrtPriceX96 = encodeSqrtRatioX96(tokenAmount1.quotient, tokenAmount0.quotient);
//     const currentTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
//     console.log(`Calculated sqrtPriceX96: ${sqrtPriceX96.toString()}
//     Current tick: ${currentTick}`);

//     const tickSpacing = getTickSpacing(fee);
//     console.log(`Tick spacing for fee ${fee}: ${tickSpacing}`);

//     // Convert price limits to ticks
//     let lowerTick = Math.floor(TickMath.getTickAtSqrtRatio(encodeSqrtRatioX96(
//         JSBI.BigInt(Math.floor(lowerPriceLimit * (10 ** decimals1))),
//         JSBI.BigInt(10 ** decimals0)
//     )));
//     let upperTick = Math.ceil(TickMath.getTickAtSqrtRatio(encodeSqrtRatioX96(
//         JSBI.BigInt(Math.ceil(upperPriceLimit * (10 ** decimals1))),
//         JSBI.BigInt(10 ** decimals0)
//     )));
//     console.log(`Initial tick range:
//     Lower tick: ${lowerTick}
//     Upper tick: ${upperTick}`);

//     // Adjust to nearest usable ticks
//     lowerTick = nearestUsableTick(lowerTick, tickSpacing);
//     upperTick = nearestUsableTick(upperTick, tickSpacing);
//     console.log(`Adjusted to nearest usable ticks:
//     Lower tick: ${lowerTick}
//     Upper tick: ${upperTick}`);

//     // Ensure ticks are within allowed range
//     lowerTick = Math.max(lowerTick, TickMath.MIN_TICK);
//     upperTick = Math.min(upperTick, TickMath.MAX_TICK);
//     console.log(`Final tick range after ensuring within allowed range:
//     Lower tick: ${lowerTick}
//     Upper tick: ${upperTick}`);

//     const lowerPrice = tickToPrice(token0, token1, lowerTick);
//     const upperPrice = tickToPrice(token0, token1, upperTick);
//     console.log(`Calculated price range:
//     Lower price: ${lowerPrice.toSignificant(30)} ${token1.name} per ${token0.name}
//     Upper price: ${upperPrice.toSignificant(30)} ${token1.name} per ${token0.name}`);

//     return { lowerTick, upperTick };
// }
// function getTickSpacing(fee: number): number {
//     console.log(`Getting tick spacing for fee: ${fee}`);
//     let tickSpacing: number;
//     switch (fee) {
//         case 100:
//             tickSpacing = 1;
//             break;
//         case 500:
//             tickSpacing = 10;
//             break;
//         case 3000:
//             tickSpacing = 60;
//             break;
//         case 10000:
//             tickSpacing = 200;
//             break;
//         default:
//             throw new Error(`Invalid fee: ${fee}`);
//     }
//     console.log(`Tick spacing for fee ${fee}: ${tickSpacing}`);
//     return tickSpacing;
// }


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

    const token0 = new Token(chainId, token0Address, decimals0);
    const token1 = new Token(chainId, token1Address, decimals1);
    console.log(`Created Token objects:
    token0: ${token0.name} (${token0.address})
    token1: ${token1.name} (${token1.address})`);

    // Get the pool contract instance
    const poolContract = new ethers.Contract(poolAddress, IUniswapV3PoolABI, ethers.provider);

    // Get the current sqrtPriceX96 from the pool
    const slot0 = await poolContract.slot0();
    const sqrtPriceX96 = slot0.sqrtPriceX96;
    console.log(`Retrieved sqrtPriceX96 from pool: ${sqrtPriceX96.toString()}`);

    // Calculate the current price from sqrtPriceX96
    const currentPrice = calculatePrice(sqrtPriceX96, token0, token1);
    console.log(`Calculated current price: ${currentPrice.toFixed(18)} ${token1.symbol} per ${token0.symbol}`);

    // Set range: 90% below and 90% above current price
    const lowerPriceLimit = currentPrice * 0.1; // 90% below (0.1 times the current price)
    const upperPriceLimit = currentPrice * 1.9; // 90% above (1.9 times the current price)
    console.log(`Set price limits:
    Lower price limit: ${lowerPriceLimit.toFixed(18)} ${token1.symbol} per ${token0.symbol}
    Upper price limit: ${upperPriceLimit.toFixed(18)} ${token1.symbol} per ${token0.symbol}`);

    const currentTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    console.log(`Current tick: ${currentTick}`);

    const tickSpacing = getTickSpacing(fee);
    console.log(`Tick spacing for fee ${fee}: ${tickSpacing}`);

    // Convert price limits to ticks
    let lowerTick = Math.floor(TickMath.getTickAtSqrtRatio(encodeSqrtRatioX96(
        JSBI.BigInt(Math.floor(lowerPriceLimit * (10 ** token1.decimals))),
        JSBI.BigInt(10 ** token0.decimals)
    )));
    let upperTick = Math.ceil(TickMath.getTickAtSqrtRatio(encodeSqrtRatioX96(
        JSBI.BigInt(Math.ceil(upperPriceLimit * (10 ** token1.decimals))),
        JSBI.BigInt(10 ** token0.decimals)
    )));
    console.log(`Initial tick range:
    Lower tick: ${lowerTick}
    Upper tick: ${upperTick}`);

    // Adjust to nearest usable ticks
    lowerTick = nearestUsableTick(lowerTick, tickSpacing);
    upperTick = nearestUsableTick(upperTick, tickSpacing);
    console.log(`Adjusted to nearest usable ticks:
    Lower tick: ${lowerTick}
    Upper tick: ${upperTick}`);

    // Ensure ticks are within allowed range
    lowerTick = Math.max(lowerTick, TickMath.MIN_TICK);
    upperTick = Math.min(upperTick, TickMath.MAX_TICK);
    console.log(`Final tick range after ensuring within allowed range:
    Lower tick: ${lowerTick}
    Upper tick: ${upperTick}`);

    return { lowerTick, upperTick };
}

function calculatePrice(sqrtPriceX96: BigNumber, token0: Token, token1: Token): number {
    const Q96 = JSBI.exponentiate(JSBI.BigInt(2), JSBI.BigInt(96));
    const sqrtPrice = JSBI.divide(sqrtPriceX96.toString(), Q96);
    const price = JSBI.divide(
        JSBI.multiply(sqrtPrice, sqrtPrice),
        JSBI.exponentiate(JSBI.BigInt(10), JSBI.BigInt(token0.decimals))
    );
    const decimalAdjustment = JSBI.exponentiate(
        JSBI.BigInt(10),
        JSBI.BigInt(token1.decimals - token0.decimals)
    );
    const priceAdjusted = JSBI.divide(price, decimalAdjustment);
    return Number(priceAdjusted.toString()) / (10 ** token1.decimals);
}

function getTickSpacing(fee: number): number {
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