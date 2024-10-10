// pragma solidity ^0.8.19;

// import {SD59x18, sd} from "@prb/math/src/SD59x18.sol";
// import {UD60x18, ud, unwrap} from "@prb/math/src/UD60x18.sol";

// library BondingCurveLib {
//     /// @notice Calculate the amount of tokens to be received for a given ETH amount
//     /// @param totalEthCollected The total amount of ETH collected so far
//     /// @param tradeableTokens The amount of tokens left for sale
//     /// @param ethAmount The amount of ETH being provided
//     /// @param k The constant product
//     /// @return tokenAmount The amount of tokens to be received
//     function calculateTokenAmount(uint256 totalEthCollected, uint256 tradeableTokens, uint256 ethAmount, uint256 k)
//         internal
//         pure
//         returns (uint256 tokenAmount)
//     {
//         UD60x18 currentEthReserve = ud(totalEthCollected);
//         UD60x18 currentTokenSupply = ud(tradeableTokens);
//         UD60x18 newEthReserve = currentEthReserve.add(ud(ethAmount));
//         UD60x18 newTokenSupply = ud(k).div(newEthReserve);
//         return unwrap(currentTokenSupply.sub(newTokenSupply));
//     }

//     /// @notice Calculate the current token price in ETH
//     /// @param totalEthCollected The total amount of ETH collected so far
//     /// @param tradeableTokens The amount of tokens left for sale
//     /// @return price The current token price in ETH (with 18 decimals precision)
//     function calculateTokenPrice(uint256 totalEthCollected, uint256 tradeableTokens)
//         internal
//         pure
//         returns (uint256 price)
//     {
//         return unwrap(ud(totalEthCollected).div(ud(tradeableTokens)));
//     }

//     /// @notice Calculate the ETH amount needed to purchase a specific amount of tokens
//     /// @param totalEthCollected The total amount of ETH collected so far
//     /// @param tradeableTokens The amount of tokens left for sale
//     /// @param tokenAmount The amount of tokens to purchase
//     /// @param k The constant product
//     /// @return ethAmount The amount of ETH needed

//     function calculateEthAmount(uint256 totalEthCollected, uint256 tradeableTokens, uint256 tokenAmount, uint256 k)
//         internal
//         pure
//         returns (uint256 ethAmount)
//     {
//         UD60x18 currentEthReserve = ud(totalEthCollected);
//         UD60x18 currentTokenSupply = ud(tradeableTokens);
//         UD60x18 newTokenSupply = currentTokenSupply.sub(ud(tokenAmount));
//         UD60x18 newEthReserve = ud(k).div(newTokenSupply);
//         return unwrap(newEthReserve.sub(currentEthReserve));
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

error InsufficientLiquidity();

library BondingCurveLib {
    // Precision constant
    uint256 public constant PRECISION = 1e8;

    /// @notice Calculate the amount of tokens to be received for a given ETH amount
    /// @param totalEthCollected The total amount of ETH collected so far (in wei)
    /// @param tradeableTokens The amount of tokens left for sale (in smallest token units)
    /// @param ethAmount The amount of ETH being provided (in wei)
    /// @param k The constant product
    /// @return tokenAmount The amount of tokens to be received (in smallest token units)
    // function calculateTokenAmount(uint256 totalEthCollected, uint256 tradeableTokens, uint256 ethAmount, uint256 k)
    //     internal
    //     view
    //     returns (uint256 tokenAmount)
    // {
    //     uint256 newEthReserve = totalEthCollected + ethAmount;
    //     uint256 newTokenSupply = (k * PRECISION) / newEthReserve;
    //     tokenAmount = tradeableTokens - (newTokenSupply / PRECISION);
    // }

    function calculateTokenAmount(uint256 totalEthCollected, uint256 tradeableTokens, uint256 ethAmount, uint256 k)
        external
        view
        returns (uint256 tokenAmount)
    {
        // Calculate the maximum ETH that can be accepted
        uint256 maxEthAccepted = (k * PRECISION / tradeableTokens) - totalEthCollected;

        // If the provided ETH amount is greater than what can be accepted, revert
        if (ethAmount > maxEthAccepted) {
            revert InsufficientLiquidity();
        }

        // Calculate the token amount if the check passes
        uint256 newEthReserve = totalEthCollected + ethAmount;
        uint256 newTokenSupply = (k * PRECISION) / newEthReserve;
        tokenAmount = tradeableTokens - (newTokenSupply / PRECISION);
    }

    /// @notice Calculate the ETH amount needed to purchase a specific amount of tokens
    /// @param totalEthCollected The total amount of ETH collected so far (in wei)
    /// @param tradeableTokens The amount of tokens left for sale (in smallest token units)
    /// @param tokenAmount The amount of tokens to purchase (in smallest token units)
    /// @param k The constant product
    /// @return ethAmount The amount of ETH needed (in wei)
    function calculateEthAmountForTokens(
        uint256 totalEthCollected,
        uint256 tradeableTokens,
        uint256 tokenAmount,
        uint256 k
    ) external view returns (uint256 ethAmount) {
        if (tokenAmount >= tradeableTokens) {
            revert InsufficientLiquidity();
        }
        uint256 newTokenSupply = tradeableTokens - tokenAmount;
        uint256 newEthReserve = (k * PRECISION) / newTokenSupply;

        uint256 scaledTotalEthCollected = totalEthCollected * PRECISION;

        if (newEthReserve <= scaledTotalEthCollected) {
            revert InsufficientLiquidity();
        }
        ethAmount = (newEthReserve - scaledTotalEthCollected) / PRECISION;
    }

    function getTokenPrice(uint256 ethReserve, uint256 tokenReserve) internal pure returns (uint256 price) {
        price = (ethReserve * PRECISION) / tokenReserve;
    }
}
