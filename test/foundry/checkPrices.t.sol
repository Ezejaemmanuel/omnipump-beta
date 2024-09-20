// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
// import {MainEngine} from "../../src/solving-overflow-and-underflow-error.sol";
import {MainEngine} from "../../src/mainEngine.sol";

import {CustomToken} from "../../src/customToken.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {DeployMainEngine} from "../../script/deployMainEngine.s.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

contract MainEngineTest is Test {
    MainEngine public mainEngine;
    address public user;
    // uint256 constant INITIAL_ETH = 0.1 ether;
    address public deployer;
    uint256 constant INITIAL_TOKEN_AMOUNT = 4397843283 ether ; // 1 billz
    uint256 constant ETH_AMOUNT = 107889 ether ;

    function setUp() public {
        //console.log("setUp - Starting setup");

        //console.log("setUp - Forked Sepolia at block:", block.number);

        deployer = makeAddr("deployer");
        user = makeAddr("user");
        //console.log("setUp - Created deployer address:", deployer);
        //console.log("setUp - Created user address:", user);
        vm.deal(user, 100000000000 ether);
        DeployMainEngine deployScript = new DeployMainEngine();

        (mainEngine,) = deployScript.run();
    }

    function testcreateTokenAndAddLiquidityAndCheckPricing() public {
        vm.startPrank(user);

        uint256 numTokens = 20; // Number of tokens to create
        uint256[] memory expectedPrices = new uint256[](numTokens);
        address[] memory tokenAddresses = new address[](numTokens);

        for (uint256 i = 1; i < numTokens; i++) {
            string memory name = string(abi.encodePacked("Test Token ", bytes1(uint8(i + 65))));
            string memory symbol = string(abi.encodePacked("TST", bytes1(uint8(i + 65))));
            string memory description = "A test token";
            string memory imageUrl = "https://example.com/image.png";
            string memory twitter = "https://example.com/image.png";
            string memory telegram = "https://example.com/image.png";
            string memory website = "https://example.com/image.png";

            uint256 initialSupply = INITIAL_TOKEN_AMOUNT * (i );
            uint256 ethAmount = ETH_AMOUNT * (i + 2);
            uint256 lockedLiquidityPercentage = 50; // 50%

            // Calculate expected price (ETH/token)
            expectedPrices[i] = (ethAmount * 1e8 ) / initialSupply;

            address tokenAddress = mainEngine.createTokenAndAddLiquidity{value: ethAmount}(
                user,
                name,
                symbol,
                description,
                imageUrl,
                twitter,
                telegram,
                website,
                initialSupply,
                lockedLiquidityPercentage
            );

            tokenAddresses[i] = tokenAddress;

            // Verify token creation
            CustomToken token = CustomToken(tokenAddress);
            assertEq(token.name(), name, "Token name mismatch");
            assertEq(token.symbol(), symbol, "Token symbol mismatch");
            assertEq(token.totalSupply(), initialSupply, "Initial supply mismatch");

            // Verify token info
            (
                address creator,
                bool initialLiquidityAdded,
                uint256 positionId,
                uint256 storedLockedLiquidityPercentage,
                uint256 withdrawableLiquidity,
                uint256 creationTime,
                address poolAddress,
                uint128 liquidity
            ) = mainEngine.tokenInfo(tokenAddress);

            assertEq(creator, user, "Creator mismatch");
            assertTrue(initialLiquidityAdded, "Initial liquidity not added");
            assertGt(positionId, 0, "Invalid position ID");
            assertEq(storedLockedLiquidityPercentage, lockedLiquidityPercentage, "Locked liquidity percentage mismatch");
            assertGt(withdrawableLiquidity, 0, "No withdrawable liquidity");
            assertEq(creationTime, block.timestamp, "Creation time mismatch");
            assertTrue(poolAddress != address(0), "Pool not created");
            assertGt(liquidity, 0, "No liquidity added");

            // Check current price
            uint256 currentPrice = mainEngine.getCurrentPrice(tokenAddress);
            console.log("Token", i, "- Expected price:", expectedPrices[i]);
            console.log("Token", i, "- Actual price:", currentPrice);

            // Assert that the current price is within 1% of the expected price
            assertEq(currentPrice, expectedPrices[i],  "Price mismatch");
        }

        // Additional checks after all tokens have been created
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 finalPrice = mainEngine.getCurrentPrice(tokenAddresses[i]);
            console.log("Final check - Token", i, "price:", finalPrice);
            assertEq(finalPrice, expectedPrices[i],  "Final price mismatch");
        }

        vm.stopPrank();
    }
}
