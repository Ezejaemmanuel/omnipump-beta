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
    uint256 constant INITIAL_TOKEN_AMOUNT = 0.001 ether; // 1 billz
    uint256 constant ETH_AMOUNT = 0.001 ether;

    function setUp() public {
        //console.log("setUp - Starting setup");

        //console.log("setUp - Forked Sepolia at block:", block.number);

        deployer = makeAddr("deployer");
        user = makeAddr("user");
        //console.log("setUp - Created deployer address:", deployer);
        //console.log("setUp - Created user address:", user);
        vm.deal(user, 100000000000 ether);
        DeployMainEngine deployScript = new DeployMainEngine();

        //console.log("setUp - Created DeployMainEngine instance at:", address(deployScript));

        (mainEngine,) = deployScript.run();
        //console.log("setUp - Ran DeployMainEngine script");
        //console.log("setUp - MainEngine deployed at:", address(mainEngine));

        //console.log("setUp - MainEngine factory address:", address(mainEngine.factory()));
        //console.log(
        // "setUp - MainEngine nonfungiblePositionManager address:", address(mainEngine.nonfungiblePositionManager())
        // );
        //console.log("setUp - MainEngine swapRouter address:", address(mainEngine.swapRouter02()));
        //console.log("setUp - MainEngine WETH9 address:", mainEngine.WETH9());

        //console.log("setUp - Setup completed");
    }

    function testcreateTokenAndAddLiquidity() public {
        //console.log("testcreateTokenAndAddLiquidity - Starting test");
        vm.startPrank(user);
        //console.log("testcreateTokenAndAddLiquidity - Started pranking as user:", user);

        string memory name = "Test Token";
        string memory symbol = "TST";
        string memory description = "A test token";
        string memory imageUrl = "https://example.com/image.png";
        string memory twitter = "https://example.com/image.png";
        string memory telegram = "https://example.com/image.png";
        string memory website = "https://example.com/image.png";

        uint256 initialSupply = INITIAL_TOKEN_AMOUNT;
        uint256 lockedLiquidityPercentage = 50; // 50%
        uint24 fee = 3000; // 0.3%

        //console.log("testcreateTokenAndAddLiquidity - Calling createTokenAndAddLiquidity");
        address tokenCreator = msg.sender;
        address tokenAddress = mainEngine.createTokenAndAddLiquidity{value: ETH_AMOUNT}(
            tokenCreator,
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
        //console.log("testcreateTokenAndAddLiquidity - Token created at address:", tokenAddress);

        //console.log("testcreateTokenAndAddLiquidity - Verifying token creation");
        CustomToken token = CustomToken(tokenAddress);
        assertEq(token.name(), name, "Token name mismatch");
        assertEq(token.symbol(), symbol, "Token symbol mismatch");
        assertEq(token.totalSupply(), initialSupply, "Initial supply mismatch");

        //console.log("testcreateTokenAndAddLiquidity - Verifying token info");
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

        //console.log("testcreateTokenAndAddLiquidity - Creator:", creator);

        //console.log("testcreateTokenAndAddLiquidity - Initial liquidity added:", initialLiquidityAdded);
        //console.log("testcreateTokenAndAddLiquidity - Position ID:", positionId);
        //console.log("testcreateTokenAndAddLiquidity - Locked liquidity percentage:", storedLockedLiquidityPercentage);
        //console.log("testcreateTokenAndAddLiquidity - Withdrawable liquidity:", withdrawableLiquidity);
        //console.log("testcreateTokenAndAddLiquidity - Creation time:", creationTime);
        //console.log("testcreateTokenAndAddLiquidity - Pool address:", poolAddress);
        //console.log("testcreateTokenAndAddLiquidity - Liquidity:", liquidity);

        assertEq(creator, user, "Creator mismatch");

        assertTrue(initialLiquidityAdded, "Initial liquidity not added");
        assertGt(positionId, 0, "Invalid position ID");
        assertEq(storedLockedLiquidityPercentage, lockedLiquidityPercentage, "Locked liquidity percentage mismatch");
        assertGt(withdrawableLiquidity, 0, "No withdrawable liquidity");
        assertEq(creationTime, block.timestamp, "Creation time mismatch");
        assertTrue(poolAddress != address(0), "Pool not created");
        assertGt(liquidity, 0, "No liquidity added");

        //console.log("testcreateTokenAndAddLiquidity - Verifying pool setup");
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        assertEq(pool.fee(), fee, "Pool fee mismatch");

        //console.log("testcreateTokenAndAddLiquidity - Verifying liquidity position");
        INonfungiblePositionManager positionManager = mainEngine.nonfungiblePositionManager();
        (
            ,
            ,
            address token0,
            address token1,
            uint24 positionFee,
            int24 positionTickLower,
            int24 positionTickUpper,
            uint128 positionLiquidity,
            ,
            ,
            ,
        ) = positionManager.positions(positionId);

        //console.log("testcreateTokenAndAddLiquidity - Token0:", token0);
        //console.log("testcreateTokenAndAddLiquidity - Token1:", token1);
        //console.log("testcreateTokenAndAddLiquidity - Position fee:", positionFee);
        //console.log("testcreateTokenAndAddLiquidity - Position liquidity:", positionLiquidity);

        assertTrue(token0 < token1, "Tokens not sorted");
        assertTrue(token0 == tokenAddress || token1 == tokenAddress, "Token not in position");
        assertEq(positionFee, fee, "Position fee mismatch");
        assertGt(positionLiquidity, 0, "No liquidity in position");

        vm.stopPrank();
        //console.log("testcreateTokenAndAddLiquidity - Test completed");
    }
}
