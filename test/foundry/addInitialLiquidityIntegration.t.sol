// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
 
        deployer = makeAddr("deployer");
        user = makeAddr("user");

        vm.deal(user, 100000000000 ether);
        DeployMainEngine deployScript = new DeployMainEngine();

        (mainEngine,) = deployScript.run();
 
    }

    function testcreateTokenAndAddLiquidity() public {

        vm.startPrank(user);
     

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
       
        CustomToken token = CustomToken(tokenAddress);
        assertEq(token.name(), name, "Token name mismatch");
        assertEq(token.symbol(), symbol, "Token symbol mismatch");
        assertEq(token.totalSupply(), initialSupply, "Initial supply mismatch");

      
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


        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        assertEq(pool.fee(), fee, "Pool fee mismatch");


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

     
        assertTrue(token0 < token1, "Tokens not sorted");
        assertTrue(token0 == tokenAddress || token1 == tokenAddress, "Token not in position");
        assertEq(positionFee, fee, "Position fee mismatch");
        assertGt(positionLiquidity, 0, "No liquidity in position");

        vm.stopPrank();
       
    }
}
