"use strict";
// import { Token } from "@uniswap/sdk-core";
// import { encodeSqrtRatioX96, TickMath } from "@uniswap/v3-sdk";
// import { ethers } from "hardhat";
// import JSBI from "jsbi";
// import { abi as IUniswapV3PoolABI } from '@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json';
// import { MainEngine } from "../../typechain-types";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculatePrice = exports.calculateWideTicks = void 0;
// export async function calculateWideTicks(
//     mainEngine: MainEngine,
//     token0Address: string,
//     token1Address: string,
//     poolAddress: string,
//     decimals0: number,
//     decimals1: number,
//     fee: number,
//     chainId: number
// ) {
//     console.log(`Starting calculateWideTicks function with inputs:
//     token0Address: ${token0Address}
//     token1Address: ${token1Address}
//     poolAddress: ${poolAddress}
//     decimals0: ${decimals0}
//     decimals1: ${decimals1}
//     fee: ${fee}
//     chainId: ${chainId}`);
//     const token0 = new Token(chainId, token0Address, decimals0);
//     const token1 = new Token(chainId, token1Address, decimals1);
//     console.log(`Created Token objects:
//     token0: ${token0.name} (${token0.address})
//     token1: ${token1.name} (${token1.address})`);
//     // Get the pool contract instance
//     const poolContract = new ethers.Contract(poolAddress, IUniswapV3PoolABI, ethers.provider);
//     // Get the current sqrtPriceX96 from the pool
//     const slot0 = await poolContract.slot0();
//     const sqrtPriceX96 = slot0.sqrtPriceX96;
//     console.log(`Retrieved sqrtPriceX96 from pool: ${sqrtPriceX96.toString()}`);
//     // Calculate the current price from sqrtPriceX96
//     const currentPrice = calculatePrice(sqrtPriceX96, token0, token1);
//     console.log(`Calculated current price: ${currentPrice.toFixed(18)} ${token1.symbol} per ${token0.symbol}`);
//     // Set range: 90% below and 90% above current price
//     const lowerPriceLimit = currentPrice * 0.1; // 90% below (0.1 times the current price)
//     const upperPriceLimit = currentPrice * 1.9; // 90% above (1.9 times the current price)
//     console.log(`Set price limits:
//     Lower price limit: ${lowerPriceLimit.toFixed(18)} ${token1.symbol} per ${token0.symbol}
//     Upper price limit: ${upperPriceLimit.toFixed(18)} ${token1.symbol} per ${token0.symbol}`);
//     // Convert price limits to sqrt ratios
//     const sqrtLowerPrice = encodeSqrtRatioX96(
//         JSBI.BigInt(Math.floor(lowerPriceLimit * (10 ** token1.decimals))),
//         JSBI.BigInt(10 ** token0.decimals)
//     );
//     const sqrtUpperPrice = encodeSqrtRatioX96(
//         JSBI.BigInt(Math.ceil(upperPriceLimit * (10 ** token1.decimals))),
//         JSBI.BigInt(10 ** token0.decimals)
//     );
//     console.log(`Converted price limits to sqrt ratios:
//     sqrtLowerPrice: ${sqrtLowerPrice.toString()}
//     sqrtUpperPrice: ${sqrtUpperPrice.toString()}`);
//     // Convert sqrt ratios to ticks
//     let lowerTick = TickMath.getTickAtSqrtRatio(sqrtLowerPrice);
//     let upperTick = TickMath.getTickAtSqrtRatio(sqrtUpperPrice);
//     console.log(`Converted sqrt ratios to ticks:
//     lowerTick: ${lowerTick}
//     upperTick: ${upperTick}`);
//     // Adjust ticks based on tick spacing
//     const tickSpacing = getTickSpacing(fee);
//     lowerTick = Math.floor(lowerTick / tickSpacing) * tickSpacing;
//     upperTick = Math.ceil(upperTick / tickSpacing) * tickSpacing;
//     console.log(`Adjusted ticks based on tick spacing (${tickSpacing}):
//     lowerTick: ${lowerTick}
//     upperTick: ${upperTick}`);
//     // Ensure ticks are within allowed range
//     lowerTick = Math.max(lowerTick, TickMath.MIN_TICK);
//     upperTick = Math.min(upperTick, TickMath.MAX_TICK);
//     console.log(`Final tick range after ensuring within allowed range:
//     lowerTick: ${lowerTick}
//     upperTick: ${upperTick}`);
//     return { lowerTick, upperTick };
// }
// function calculatePrice(sqrtPriceX96: JSBI, token0: Token, token1: Token): number {
//     const Q96 = JSBI.exponentiate(JSBI.BigInt(2), JSBI.BigInt(96));
//     const sqrtPrice = JSBI.divide(sqrtPriceX96, Q96);
//     const price = JSBI.divide(
//         JSBI.multiply(sqrtPrice, sqrtPrice),
//         JSBI.exponentiate(JSBI.BigInt(10), JSBI.BigInt(token0.decimals))
//     );
//     const decimalAdjustment = JSBI.exponentiate(
//         JSBI.BigInt(10),
//         JSBI.BigInt(token1.decimals - token0.decimals)
//     );
//     const priceAdjusted = JSBI.divide(price, decimalAdjustment);
//     return JSBI.toNumber(priceAdjusted) / (10 ** token1.decimals);
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
var sdk_core_1 = require("@uniswap/sdk-core");
var v3_sdk_1 = require("@uniswap/v3-sdk");
var hardhat_1 = require("hardhat");
var jsbi_1 = require("jsbi");
var IUniswapV3Pool_json_1 = require("@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json");
var bignumber_js_1 = require("bignumber.js");
function calculateWideTicks(mainEngine, token0Address, token1Address, poolAddress, decimals0, decimals1, fee, chainId) {
    return __awaiter(this, void 0, void 0, function () {
        var token0, token1, poolContract, slot0, sqrtPriceX96, currentPrice, lowerPriceLimit, upperPriceLimit, sqrtLowerPrice, sqrtUpperPrice, lowerTick, upperTick, tickSpacing;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    console.log("Starting calculateWideTicks function with inputs:\n    token0Address: ".concat(token0Address, "\n    token1Address: ").concat(token1Address, "\n    poolAddress: ").concat(poolAddress, "\n    decimals0: ").concat(decimals0, "\n    decimals1: ").concat(decimals1, "\n    fee: ").concat(fee, "\n    chainId: ").concat(chainId));
                    token0 = new sdk_core_1.Token(chainId, token0Address, decimals0);
                    token1 = new sdk_core_1.Token(chainId, token1Address, decimals1);
                    console.log("Created Token objects:\n    token0: ".concat(token0.name, " (").concat(token0.address, ")\n    token1: ").concat(token1.name, " (").concat(token1.address, ")"));
                    poolContract = new hardhat_1.ethers.Contract(poolAddress, IUniswapV3Pool_json_1.abi, hardhat_1.ethers.provider);
                    return [4 /*yield*/, poolContract.slot0()];
                case 1:
                    slot0 = _a.sent();
                    sqrtPriceX96 = slot0.sqrtPriceX96;
                    console.log("Retrieved sqrtPriceX96 from pool: ".concat(sqrtPriceX96.toString()));
                    currentPrice = calculatePrice(sqrtPriceX96, token0, token1);
                    console.log("Calculated current price: ".concat(currentPrice.toFixed(50), " ").concat(token1.name, " per ").concat(token0.name));
                    lowerPriceLimit = currentPrice * 0.1;
                    upperPriceLimit = currentPrice * 1.9;
                    console.log("Set price limits:\n    Lower price limit: ".concat(lowerPriceLimit.toFixed(50), " ").concat(token1.name, " per ").concat(token0.name, "\n    Upper price limit: ").concat(upperPriceLimit.toFixed(50), " ").concat(token1.name, " per ").concat(token0.name));
                    sqrtLowerPrice = (0, v3_sdk_1.encodeSqrtRatioX96)(jsbi_1.default.BigInt(new bignumber_js_1.default(lowerPriceLimit).times(new bignumber_js_1.default(10).pow(token1.decimals)).integerValue().toString()), jsbi_1.default.BigInt(new bignumber_js_1.default(10).pow(token0.decimals).toString()));
                    sqrtUpperPrice = (0, v3_sdk_1.encodeSqrtRatioX96)(jsbi_1.default.BigInt(new bignumber_js_1.default(upperPriceLimit).times(new bignumber_js_1.default(10).pow(token1.decimals)).integerValue().toString()), jsbi_1.default.BigInt(new bignumber_js_1.default(10).pow(token0.decimals).toString()));
                    console.log("Converted price limits to sqrt ratios:\n    sqrtLowerPrice: ".concat(sqrtLowerPrice.toString(), "\n    sqrtUpperPrice: ").concat(sqrtUpperPrice.toString()));
                    lowerTick = v3_sdk_1.TickMath.getTickAtSqrtRatio(sqrtLowerPrice);
                    upperTick = v3_sdk_1.TickMath.getTickAtSqrtRatio(sqrtUpperPrice);
                    console.log("Converted sqrt ratios to ticks:\n    lowerTick: ".concat(lowerTick, "\n    upperTick: ").concat(upperTick));
                    tickSpacing = getTickSpacing(fee);
                    lowerTick = Math.floor(lowerTick / tickSpacing) * tickSpacing;
                    upperTick = Math.ceil(upperTick / tickSpacing) * tickSpacing;
                    console.log("Adjusted ticks based on tick spacing (".concat(tickSpacing, "):\n    lowerTick: ").concat(lowerTick, "\n    upperTick: ").concat(upperTick));
                    // Ensure ticks are within allowed range
                    lowerTick = Math.max(lowerTick, v3_sdk_1.TickMath.MIN_TICK);
                    upperTick = Math.min(upperTick, v3_sdk_1.TickMath.MAX_TICK);
                    console.log("Final tick range after ensuring within allowed range:\n    lowerTick: ".concat(lowerTick, "\n    upperTick: ").concat(upperTick));
                    return [2 /*return*/, { lowerTick: lowerTick, upperTick: upperTick }];
            }
        });
    });
}
exports.calculateWideTicks = calculateWideTicks;
function calculatePrice(sqrtPriceX96, token0, token1) {
    bignumber_js_1.default.config({ EXPONENTIAL_AT: 999999, DECIMAL_PLACES: 40 });
    var Q96 = jsbi_1.default.exponentiate(jsbi_1.default.BigInt(2), jsbi_1.default.BigInt(96));
    console.log("this is the q96 which is ", Q96);
    var sqrtPrice = new bignumber_js_1.default(sqrtPriceX96.toString()).div(new bignumber_js_1.default(Q96.toString()));
    console.log("this is the sqrt price oooo", sqrtPrice);
    var price = sqrtPrice.pow(2).div(new bignumber_js_1.default(10).pow(token0.decimals));
    console.log("this is the price ", price);
    var decimalAdjustment = new bignumber_js_1.default(10).pow(token1.decimals - token0.decimals);
    console.log("this is the decimal adjustment", decimalAdjustment);
    var priceAdjusted = price.div(decimalAdjustment);
    console.log("this is the price adjusted", priceAdjusted);
    var calculatedPrice = parseFloat(priceAdjusted.toFixed(50));
    console.log("this is the calculated price", calculatedPrice);
    return calculatedPrice;
}
exports.calculatePrice = calculatePrice;
function getTickSpacing(fee) {
    console.log("Getting tick spacing for fee: ".concat(fee));
    var tickSpacing;
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
            throw new Error("Invalid fee: ".concat(fee));
    }
    console.log("Tick spacing for fee ".concat(fee, ": ").concat(tickSpacing));
    return tickSpacing;
}
