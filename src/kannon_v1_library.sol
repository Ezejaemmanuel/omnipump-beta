// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

library KannonV1Library {
    uint256 constant PRECISION = 1e14;
    uint256 constant PRECISION_2 = 1e11;
    int24 constant TICK_SPACING = 60;

    error InvalidTokenOrder();
    error ZeroAmount();
    error SqrtPriceOutOfBounds();
    error InvalidToken();

   

    function orderTokens(address tokenAddress, address WETH9) internal pure returns (address token0, address token1) {
        if (tokenAddress < WETH9) {
            token0 = tokenAddress;
            token1 = WETH9;
        } else {
            token0 = WETH9;
            token1 = tokenAddress;
        }
    }

    function getCurrentPrice(address tokenAddress, address WETH9, address pool) internal view returns (uint256) {
        (uint160 sqrtPriceX96,) = getPoolSlot0(pool);
        uint256 currentPrice = calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress, WETH9);
        return currentPrice;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function getPoolReserves(address tokenAddress, address WETH9, address pool) internal view returns (uint256 tokenReserve, uint256 ethReserve) {
        (address token0, address token1) = orderTokens(tokenAddress, WETH9);

        uint256 balance0 = IERC20Metadata(token0).balanceOf(pool);
        uint256 balance1 = IERC20Metadata(token1).balanceOf(pool);

        if (token0 == tokenAddress) {
            tokenReserve = balance0;
            ethReserve = balance1;
        } else {
            tokenReserve = balance1;
            ethReserve = balance0;
        }
    }

    function getPoolLiquidity(address pool) internal view returns (uint128) {
        return IUniswapV3Pool(pool).liquidity();
    }

    function getTokenBalance(address tokenAddress, address account) internal view returns (uint256) {
        return IERC20Metadata(tokenAddress).balanceOf(account);
    }

    function getPoolSlot0(address pool) internal view returns (uint160, int24) {
        uint160 sqrtPriceX96;
        int24 tick;
        (sqrtPriceX96, tick,,,,,) = IUniswapV3Pool(pool).slot0();
        return (sqrtPriceX96, tick);
    }

    function calculateTickRange(int24 currentTick, uint256 currentPrice) internal pure returns (int24 tickLower, int24 tickUpper) {
        uint256 priceRange = (currentPrice * 10) / 100;
        int24 tickRange = int24(int256((priceRange * uint256(int256(TICK_SPACING))) / currentPrice)) * 1000;
        tickLower = ((currentTick - tickRange) / TICK_SPACING) * TICK_SPACING;
        tickUpper = ((currentTick + tickRange) / TICK_SPACING) * TICK_SPACING;
        return (tickLower, tickUpper);
    }



    function calculatePriceFromSqrtPriceX96(uint160 sqrtPriceX96, address tokenAddress, address WETH9) internal pure returns (uint256) {
        if (tokenAddress == WETH9) {
            revert InvalidToken();
        }

        (, address token1) = orderTokens(tokenAddress, WETH9);
        uint256 q = 2 ** 96;
        uint256 price = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * PRECISION_2) / (q * q);

        if (token1 == WETH9) {
            return price;
        } else {
            return (PRECISION_2 * PRECISION_2) / price;
        }
    }
    function calculateInitialSqrtPrice(address token0, address token1, uint256 amount0, uint256 amount1)
        public
        view
        returns (uint160)
    {
        if (token0 >= token1) {
            revert InvalidTokenOrder();
        }
        if (amount0 == 0 || amount1 == 0) {
            revert ZeroAmount();
        }

        // Calculate the price ratio
        uint256 priceRatio = (amount1 * PRECISION) / amount0;

        uint256 sqrtPrice = KannonV1Library.sqrt(priceRatio);

        uint256 q = 2 ** 96;
        uint160 sqrtPriceX96 = uint160((sqrtPrice * q) / KannonV1Library.sqrt(PRECISION));
        if (sqrtPriceX96 < TickMath.MIN_SQRT_RATIO || sqrtPriceX96 > TickMath.MAX_SQRT_RATIO) {
            revert SqrtPriceOutOfBounds();
        }
        return sqrtPriceX96;
    }



  
}