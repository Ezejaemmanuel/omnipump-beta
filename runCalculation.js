"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var jsbi_1 = require("jsbi");
var sdk_core_1 = require("@uniswap/sdk-core");
var newTickCalculator_1 = require("./test/hardhat/newTickCalculator");
var chainId = 11155111;
var token0Address = "0xD49eD460D1cbe46168A59a83a6146c630568f2B4";
var token1Address = "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14";
var decimals0 = 18;
var decimals1 = 18;
var token0 = new sdk_core_1.Token(chainId, token0Address, decimals0);
var token1 = new sdk_core_1.Token(chainId, token1Address, decimals1);
// Example usage
var sqrtPriceX96 = jsbi_1.default.BigInt("890102030748");
var price = (0, newTickCalculator_1.calculatePrice)(sqrtPriceX96, token0, token1);
console.log("Calculated price:", price);
