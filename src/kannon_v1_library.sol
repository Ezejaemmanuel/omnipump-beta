// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {BondingCurveLib} from "./kannon_v1_bonding_curve.sol";

library KannonV1Library {
    uint256 constant PRECISION = 1e14;
    uint256 constant PRECISION_2 = 1e11;
    int24 constant TICK_SPACING = 60;

    enum LaunchPhase {
        InitialPresale,
        IntermediatePresale,
        FinalLaunch
    }

    error KannonV1_InvalidPhase();
    error KannonV1_DeadlineReached();
    error KannonV1_PresaleNotComplete();
    error KannonV1_InsufficientFunds();
    error KannonV1_Unauthorized();
    error KannonV1_InvalidInput();
    error KannonV1_InvalidOperation();
    error KannonV1_TimingConstraint();
    error KannonV1_TransferFailed();
    error KannonV1_InvalidParameters();
    error KannonV1_LiquidityError();
    error KannonV1_InsufficientFundsForCrossMessage();
    error KannonV1_WETH9Failed();
    error KannonV1_PoolNotInitialized();
    error KannonV1_ExceedsAvailableTokens();
    error InvalidTokenOrder();
    error ZeroAmount();
    error SqrtPriceOutOfBounds();
    error InvalidToken();
    error KannonV1_AmountMustBe21e14();

    function orderTokens(address tokenAddress, address WETH9) external pure returns (address token0, address token1) {
        return _orderTokens(tokenAddress, WETH9);
    }

    function _orderTokens(address tokenAddress, address WETH9) internal pure returns (address token0, address token1) {
        if (tokenAddress < WETH9) {
            token0 = tokenAddress;
            token1 = WETH9;
        } else {
            token0 = WETH9;
            token1 = tokenAddress;
        }
    }

    function getCurrentPrice(address tokenAddress, address WETH9, address pool) external view returns (uint256) {
        (uint160 sqrtPriceX96,) = _getPoolSlot0(pool);
        uint256 currentPrice = _calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress, WETH9);
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

    function getPoolReserves(address tokenAddress, address WETH9, address pool)
        external
        view
        returns (uint256 tokenReserve, uint256 ethReserve)
    {
        return _getPoolReserves(tokenAddress, WETH9, pool);
    }

    function _getPoolReserves(address tokenAddress, address WETH9, address pool)
        internal
        view
        returns (uint256 tokenReserve, uint256 ethReserve)
    {
        (address token0, address token1) = _orderTokens(tokenAddress, WETH9);

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

    uint256 constant PRECISION_13 = 1e13;

    struct PresaleInfo {
        uint256 distributableSupply;
        uint256 k;
        uint256 initialPresaleDistributable;
        uint256 initialPrice;
    }

    struct PresaleRatios {
        uint256 phase1Ratio;
        uint256 phase2Ratio;
        uint256 launchRatio;
    }
    // function calculatePresaleInfo(uint256 initialSupply, uint256 ethTarget, PresaleRatios memory presaleRatios)
    //     external
    //     pure
    //     returns (PresaleInfo memory)
    // {
    //     uint256 phaseIand2 = presaleRatios.phase1Ratio + presaleRatios.phase2Ratio;
    //     uint256 distributableSupply = initialSupply * 95 / 100;
    //     uint256 k = (distributableSupply * phaseIand2) * ethTarget;
    //     uint256 initialPresaleDistributable = distributableSupply / presaleRatios.phase1Ratio;
    //     uint256 initialPrice = ethTarget * PRECISION_13 / initialPresaleDistributable;

    //     return PresaleInfo({
    //         distributableSupply: distributableSupply,
    //         k: k,
    //         initialPresaleDistributable: initialPresaleDistributable,
    //         initialPrice: initialPrice
    //     });
    // }

    function calculatePresaleInfo(uint256 initialSupply, uint256 ethTarget, PresaleRatios memory presaleRatios)
        external
        pure
        returns (PresaleInfo memory)
    {
        uint256 phaseIand2 = presaleRatios.phase1Ratio + presaleRatios.phase2Ratio;
        uint256 distributableSupply = initialSupply * 95 / 100;
        uint256 k = (distributableSupply * phaseIand2) * ethTarget / 1000;
        uint256 initialPresaleDistributable = distributableSupply * presaleRatios.phase1Ratio / 1000;
        uint256 initialPrice = ethTarget * PRECISION_13 / initialPresaleDistributable;

        return PresaleInfo({
            distributableSupply: distributableSupply,
            k: k,
            initialPresaleDistributable: initialPresaleDistributable,
            initialPrice: initialPrice
        });
    }

    struct LiquidityAfterPresaleData {
        uint256 ethAmount;
        uint256 tokenAmount;
        uint160 sqrtPriceX96;
        int24 tick;
        uint256 currentPrice;
        int24 lower;
        int24 upper;
    }

    function getLiquidityAfterPresaleData(
        address tokenAddress,
        address WETH9,
        uint256 ethCollected,
        uint256 distributableSupply,
        uint256 totalPresoldTokens,
        address pool
    ) external view returns (LiquidityAfterPresaleData memory) {
        uint256 ethAmount = ethCollected;
        uint256 tokenAmount = distributableSupply - totalPresoldTokens;

        (uint160 sqrtPriceX96, int24 tick) = _getPoolSlot0(pool);
        uint256 currentPrice = _calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress, WETH9);
        (int24 lower, int24 upper) = _calculateTickRange(tick, currentPrice);

        return LiquidityAfterPresaleData({
            ethAmount: ethAmount,
            tokenAmount: tokenAmount,
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            currentPrice: currentPrice,
            lower: lower,
            upper: upper
        });
    }

    struct PresaleParticipationResult {
        uint256 tokenAmount;
        uint256 ethToUse;
        uint256 refund;
    }

    // function calculatePresaleParticipation(
    //     LaunchPhase currentPhase,
    //     uint256 distributableSupply,
    //     uint256 ethTarget,
    //     uint256 totalPresoldTokens,
    //     uint256 ethCollected,
    //     uint256 k,
    //     uint256 msgValue,
    //     PresaleRatios memory presaleRatios
    // ) external view returns (PresaleParticipationResult memory) {
    //     uint256 tokenAmount;
    //     uint256 ethToUse = msgValue;
    //     uint256 refund;

    //     if (currentPhase == LaunchPhase.InitialPresale) {
    //         uint256 initialPresaleDistributable = distributableSupply / presaleRatios.phase1Ratio;
    //         tokenAmount = msgValue * initialPresaleDistributable / ethTarget;
    //         uint256 remainingTokens = initialPresaleDistributable - totalPresoldTokens;

    //         if (tokenAmount > remainingTokens) {
    //             tokenAmount = remainingTokens;
    //             ethToUse = tokenAmount * ethTarget / initialPresaleDistributable;
    //             refund = msgValue - ethToUse;
    //         }
    //     } else if (currentPhase == LaunchPhase.IntermediatePresale) {
    //         uint256 remainingTokensDistributable = distributableSupply - totalPresoldTokens - distributableSupply / presaleRatios.phase1Ratio;
    //         uint256 totalUnPresoldTokens = distributableSupply - totalPresoldTokens;

    //         tokenAmount = BondingCurveLib.calculateTokenAmount(ethCollected, totalUnPresoldTokens, msgValue, k);
    //         if (tokenAmount > remainingTokensDistributable) {
    //             tokenAmount = remainingTokensDistributable;
    //             ethToUse =
    //                 BondingCurveLib.calculateEthAmountForTokens(ethCollected, totalUnPresoldTokens, tokenAmount, k);
    //             refund = msgValue - ethToUse;
    //         }
    //     }

    //     return PresaleParticipationResult({tokenAmount: tokenAmount, ethToUse: ethToUse, refund: refund});
    // }

    function calculatePresaleParticipation(
        LaunchPhase currentPhase,
        uint256 distributableSupply,
        uint256 ethTarget,
        uint256 totalPresoldTokens,
        uint256 ethCollected,
        uint256 k,
        uint256 msgValue,
        PresaleRatios memory presaleRatios
    ) external view returns (PresaleParticipationResult memory) {
        uint256 tokenAmount;
        uint256 ethToUse = msgValue;
        uint256 refund;

        if (currentPhase == LaunchPhase.InitialPresale) {
            uint256 initialPresaleDistributable = distributableSupply * presaleRatios.phase1Ratio / 1000;
            tokenAmount = msgValue * initialPresaleDistributable / ethTarget;
            uint256 remainingTokens = initialPresaleDistributable - totalPresoldTokens;

            if (tokenAmount > remainingTokens) {
                tokenAmount = remainingTokens;
                ethToUse = tokenAmount * ethTarget / initialPresaleDistributable;
                refund = msgValue - ethToUse;
            }
        } else if (currentPhase == LaunchPhase.IntermediatePresale) {
            uint256 remainingTokensDistributable =
                distributableSupply - totalPresoldTokens - (distributableSupply * presaleRatios.phase1Ratio / 1000);
            uint256 totalUnPresoldTokens = distributableSupply - totalPresoldTokens;

            tokenAmount = BondingCurveLib.calculateTokenAmount(ethCollected, totalUnPresoldTokens, msgValue, k);
            if (tokenAmount > remainingTokensDistributable) {
                tokenAmount = remainingTokensDistributable;
                ethToUse =
                    BondingCurveLib.calculateEthAmountForTokens(ethCollected, totalUnPresoldTokens, tokenAmount, k);
                refund = msgValue - ethToUse;
            }
        }

        return PresaleParticipationResult({tokenAmount: tokenAmount, ethToUse: ethToUse, refund: refund});
    }

    struct TokenUpdateData {
        uint160 sqrtPriceX96;
        uint256 tokenPrice;
        uint256 ethReserve;
        uint256 tokenReserve;
        uint256 totalSupply;
    }

    function getTokenUpdateData(address tokenAddress, address WETH9, address pool)
        external
        view
        returns (TokenUpdateData memory)
    {
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();

        (uint256 tokenReserve, uint256 ethReserve) = _getPoolReserves(tokenAddress, WETH9, pool);

        uint256 totalSupply = IERC20Metadata(tokenAddress).totalSupply();
        uint256 tokenPrice = _calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress, WETH9);

        return TokenUpdateData({
            sqrtPriceX96: sqrtPriceX96,
            tokenPrice: tokenPrice,
            ethReserve: ethReserve,
            tokenReserve: tokenReserve,
            totalSupply: totalSupply
        });
    }
    // struct PresaleParticipationResult {
    //         uint256 tokenAmount;
    //         uint256 ethToUse;
    //         uint256 refund;
    //     }

    // function calculatePresaleParticipation(
    //     LaunchPhase currentPhase,
    //     uint256 distributableSupply,
    //     uint256 ethTarget,
    //     uint256 totalPresoldTokens,
    //     uint256 ethCollected,
    //     uint256 k,
    //     uint256 msgValue
    // ) external pure returns (PresaleParticipationResult memory) {
    //     uint256 tokenAmount;
    //     uint256 ethToUse = msgValue;
    //     uint256 refund;

    //     if (currentPhase == LaunchPhase.InitialPresale) {
    //         uint256 initialPresaleDistributable = distributableSupply / 3;
    //         tokenAmount = msgValue * initialPresaleDistributable / ethTarget;
    //         uint256 remainingTokens = initialPresaleDistributable - totalPresoldTokens;

    //         if (tokenAmount > remainingTokens) {
    //             tokenAmount = remainingTokens;
    //             ethToUse = tokenAmount * ethTarget / initialPresaleDistributable;
    //             refund = msgValue - ethToUse;
    //         }
    //     } else if (currentPhase == LaunchPhase.IntermediatePresale) {
    //         uint256 remainingTokensDistributable = distributableSupply - totalPresoldTokens - distributableSupply / 3;
    //         uint256 totalUnPresoldTokens = distributableSupply - totalPresoldTokens;

    //         tokenAmount = BondingCurveLib.calculateTokenAmount(ethCollected, totalUnPresoldTokens, msgValue, k);
    //         if (tokenAmount > remainingTokensDistributable) {
    //             tokenAmount = remainingTokensDistributable;
    //             ethToUse = BondingCurveLib.calculateEthAmountForTokens(ethCollected, totalUnPresoldTokens, tokenAmount, k);
    //             refund = msgValue - ethToUse;
    //         }
    //     }

    //     return PresaleParticipationResult({
    //         tokenAmount: tokenAmount,
    //         ethToUse: ethToUse,
    //         refund: refund
    //     });
    // }

    function getPoolLiquidity(address pool) external view returns (uint128) {
        return IUniswapV3Pool(pool).liquidity();
    }

    function getTokenBalance(address tokenAddress, address account) external view returns (uint256) {
        return IERC20Metadata(tokenAddress).balanceOf(account);
    }

    function getPoolSlot0(address pool) external view returns (uint160, int24) {
        return _getPoolSlot0(pool);
    }

    function _getPoolSlot0(address pool) internal view returns (uint160, int24) {
        uint160 sqrtPriceX96;
        int24 tick;
        (sqrtPriceX96, tick,,,,,) = IUniswapV3Pool(pool).slot0();
        return (sqrtPriceX96, tick);
    }

    function calculateTickRange(int24 currentTick, uint256 currentPrice)
        external
        pure
        returns (int24 tickLower, int24 tickUpper)
    {
        return _calculateTickRange(currentTick, currentPrice);
    }

    function _calculateTickRange(int24 currentTick, uint256 currentPrice)
        internal
        pure
        returns (int24 tickLower, int24 tickUpper)
    {
        uint256 priceRange = (currentPrice * 10) / 100;
        int24 tickRange = int24(int256((priceRange * uint256(int256(TICK_SPACING))) / currentPrice)) * 1000;
        tickLower = ((currentTick - tickRange) / TICK_SPACING) * TICK_SPACING;
        tickUpper = ((currentTick + tickRange) / TICK_SPACING) * TICK_SPACING;
        return (tickLower, tickUpper);
    }

    function calculatePriceFromSqrtPriceX96(uint160 sqrtPriceX96, address tokenAddress, address WETH9)
        external
        pure
        returns (uint256)
    {
        return _calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress, WETH9);
    }

    function _calculatePriceFromSqrtPriceX96(uint160 sqrtPriceX96, address tokenAddress, address WETH9)
        internal
        pure
        returns (uint256)
    {
        if (tokenAddress == WETH9) {
            revert InvalidToken();
        }

        (, address token1) = _orderTokens(tokenAddress, WETH9);
        uint256 q = 2 ** 96;
        uint256 price = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * PRECISION_2) / (q * q);

        if (token1 == WETH9) {
            return price;
        } else {
            return (PRECISION_2 * PRECISION_2) / price;
        }
    }

    function calculateInitialSqrtPrice(address token0, address token1, uint256 amount0, uint256 amount1)
        external
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

        uint256 sqrtPrice = sqrt(priceRatio);

        uint256 q = 2 ** 96;
        uint160 sqrtPriceX96 = uint160((sqrtPrice * q) / sqrt(PRECISION));
        if (sqrtPriceX96 < TickMath.MIN_SQRT_RATIO || sqrtPriceX96 > TickMath.MAX_SQRT_RATIO) {
            revert SqrtPriceOutOfBounds();
        }
        return sqrtPriceX96;
    }
}
