// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IUniswapLiquidityManager {
    function setupPool(address tokenAddress) external;
    function addInitialLiquidity(address tokenAddress, uint256 tokenAmount) external payable;
    function addLiquidity(address tokenAddress, uint256 tokenAmount) external payable;
    function removeLiquidity(address tokenAddress, uint256 liquidity) external;
    function swapExactTokensForETH(address tokenAddress, uint256 tokenAmount, uint256 minETHOut) external;
    function swapExactETHForTokens(address tokenAddress, uint256 minTokensOut) external payable;
    function getTokenPrice(address tokenAddress) external view returns (uint256);
}
