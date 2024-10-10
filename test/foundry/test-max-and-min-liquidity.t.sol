// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {KannonV1} from "../../src/kannon_v1.sol";
// import {CustomToken} from "../../src/customToken.sol";
// import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
// import {DeployKannonV1} from "../../script/deployKannonV1.s.sol";

// contract KannonV1TestMaxMin is Test {
//     KannonV1 public kannonV1;
//     address public user;
//     address public deployer;
//     uint256 constant ETH_AMOUNT = 1 ether;

//     function setUp() public {
//         deployer = makeAddr("deployer");
//         user = makeAddr("user");

//         vm.deal(user, 100000000000 ether);
//         DeployKannonV1 deployScript = new DeployKannonV1();

//         (kannonV1,) = deployScript.run();
//     }

//     function testMaxTokenSupplyRatio() public {
//         vm.startPrank(user);

//         string memory name = "Test Token";
//         string memory symbol = "TST";
//         string memory description = "A test token";
//         string memory imageUrl = "https://example.com/image.png";
//         string memory twitter = "https://twitter.com/example";
//         string memory telegram = "https://t.me/example";
//         string memory website = "https://example.com";

//         uint256 initialSupply = 1e18;
//         uint256 lockedLiquidityPercentage = 50;
//         uint24 fee = 3000;

//         while (initialSupply <= 1e27) {
//             uint256 ratio = initialSupply / ETH_AMOUNT;
//             console.log("Testing with Initial Supply:", initialSupply);
//             console.log("ETH Amount:", ETH_AMOUNT);
//             console.log("Current Ratio (InitialSupply / ETH_AMOUNT):", ratio);

//             try kannonV1.createTokenAndAddLiquidity{value: ETH_AMOUNT}(
//                 name,
//                 symbol,
//                 description,
//                 imageUrl,
//                 twitter,
//                 telegram,
//                 website,
//                 initialSupply,
//                 lockedLiquidityPercentage
//             ) returns (address tokenAddress) {
//                 CustomToken token = CustomToken(tokenAddress);
//                 assertEq(token.name(), name, "Token name mismatch");
//                 assertEq(token.symbol(), symbol, "Token symbol mismatch");
//                 assertEq(token.totalSupply(), initialSupply, "Initial supply mismatch");

//                 (
//                     address creator,
//                     bool initialLiquidityAdded,
//                     uint256 positionId,
//                     uint256 storedLockedLiquidityPercentage,
//                     uint256 withdrawableLiquidity,
//                     uint256 creationTime,
//                     address poolAddress,
//                     uint128 liquidity
//                 ) = kannonV1.tokenInfo(tokenAddress);

//                 assertEq(creator, user, "Creator mismatch");
//                 assertTrue(initialLiquidityAdded, "Initial liquidity not added");
//                 assertGt(positionId, 0, "Invalid position ID");
//                 assertEq(
//                     storedLockedLiquidityPercentage, lockedLiquidityPercentage, "Locked liquidity percentage mismatch"
//                 );
//                 assertGt(withdrawableLiquidity, 0, "No withdrawable liquidity");
//                 assertEq(creationTime, block.timestamp, "Creation time mismatch");
//                 assertTrue(poolAddress != address(0), "Pool not created");
//                 assertGt(liquidity, 0, "No liquidity added");

//                 IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
//                 assertEq(pool.fee(), fee, "Pool fee mismatch");

//                 INonfungiblePositionManager positionManager = kannonV1.nonfungiblePositionManager();
//                 (
//                     ,
//                     ,
//                     address token0,
//                     address token1,
//                     uint24 positionFee,
//                     int24 positionTickLower,
//                     int24 positionTickUpper,
//                     uint128 positionLiquidity,
//                     ,
//                     ,
//                     ,
//                 ) = positionManager.positions(positionId);

//                 assertTrue(token0 < token1, "Tokens not sorted");
//                 assertTrue(token0 == tokenAddress || token1 == tokenAddress, "Token not in position");
//                 assertEq(positionFee, fee, "Position fee mismatch");
//                 assertGt(positionLiquidity, 0, "No liquidity in position");

//                 console.log("Test passed for Initial Supply:", initialSupply);
//             } catch Error(string memory reason) {
//                 console.log("Test failed for Initial Supply:", initialSupply, "Reason:", reason);
//                 break;
//             }

//             initialSupply = initialSupply * 10;
//         }

//         vm.stopPrank();
//     }

//     function testMinTokenSupplyRatio() public {
//         vm.startPrank(user);

//         string memory name = "Test Token";
//         string memory symbol = "TST";
//         string memory description = "A test token";
//         string memory imageUrl = "https://example.com/image.png";
//         string memory twitter = "https://twitter.com/example";
//         string memory telegram = "https://t.me/example";
//         string memory website = "https://example.com";

//         uint256 initialSupply = 1e18;
//         uint256 lockedLiquidityPercentage = 50;
//         uint24 fee = 3000;
//         uint256 minSupply = 1e15;

//         while (initialSupply >= minSupply) {
//             uint256 ratio = initialSupply / ETH_AMOUNT;
//             console.log("Testing with Initial Supply:", initialSupply);
//             console.log("ETH Amount:", ETH_AMOUNT);
//             console.log("Current Ratio (InitialSupply / ETH_AMOUNT):", ratio);

//             try kannonV1.createTokenAndAddLiquidity{value: ETH_AMOUNT}(
//                 name,
//                 symbol,
//                 description,
//                 imageUrl,
//                 twitter,
//                 telegram,
//                 website,
//                 initialSupply,
//                 lockedLiquidityPercentage
//             ) returns (address tokenAddress) {
//                 CustomToken token = CustomToken(tokenAddress);
//                 assertEq(token.name(), name, "Token name mismatch");
//                 assertEq(token.symbol(), symbol, "Token symbol mismatch");
//                 assertEq(token.totalSupply(), initialSupply, "Initial supply mismatch");

//                 (
//                     address creator,
//                     bool initialLiquidityAdded,
//                     uint256 positionId,
//                     uint256 storedLockedLiquidityPercentage,
//                     uint256 withdrawableLiquidity,
//                     uint256 creationTime,
//                     address poolAddress,
//                     uint128 liquidity
//                 ) = kannonV1.tokenInfo(tokenAddress);

//                 assertEq(creator, user, "Creator mismatch");
//                 assertTrue(initialLiquidityAdded, "Initial liquidity not added");
//                 assertGt(positionId, 0, "Invalid position ID");
//                 assertEq(
//                     storedLockedLiquidityPercentage, lockedLiquidityPercentage, "Locked liquidity percentage mismatch"
//                 );
//                 assertGt(withdrawableLiquidity, 0, "No withdrawable liquidity");
//                 assertEq(creationTime, block.timestamp, "Creation time mismatch");
//                 assertTrue(poolAddress != address(0), "Pool not created");
//                 assertGt(liquidity, 0, "No liquidity added");

//                 IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
//                 assertEq(pool.fee(), fee, "Pool fee mismatch");

//                 INonfungiblePositionManager positionManager = kannonV1.nonfungiblePositionManager();
//                 (
//                     ,
//                     ,
//                     address token0,
//                     address token1,
//                     uint24 positionFee,
//                     int24 positionTickLower,
//                     int24 positionTickUpper,
//                     uint128 positionLiquidity,
//                     ,
//                     ,
//                     ,
//                 ) = positionManager.positions(positionId);

//                 assertTrue(token0 < token1, "Tokens not sorted");
//                 assertTrue(token0 == tokenAddress || token1 == tokenAddress, "Token not in position");
//                 assertEq(positionFee, fee, "Position fee mismatch");
//                 assertGt(positionLiquidity, 0, "No liquidity in position");

//                 console.log("Test passed for Initial Supply:", initialSupply);
//             } catch Error(string memory reason) {
//                 console.log("Test failed for Initial Supply:", initialSupply, "Reason:", reason);
//                 break;
//             }

//             initialSupply = initialSupply / 10;
//         }

//         vm.stopPrank();
//     }

//     function testMaxTokenSupplyAndETHRatio() public {
//         vm.startPrank(user);

//         string memory name = "Test Token";
//         string memory symbol = "TST";
//         string memory description = "A test token";
//         string memory imageUrl = "https://example.com/image.png";
//         string memory twitter = "https://twitter.com/example";
//         string memory telegram = "https://t.me/example";
//         string memory website = "https://example.com";

//         uint256 initialSupply = 1e18;
//         uint256 ethAmount = 1 ether;
//         uint256 lockedLiquidityPercentage = 50;
//         uint24 fee = 3000;

//         while (initialSupply <= 1e28 && ethAmount <= 1e15 ether) {
//             uint256 ratio = initialSupply / ethAmount;
//             console.log("Testing with Initial Supply:", initialSupply);
//             console.log("ETH Amount:", ethAmount);
//             console.log("Current Ratio (InitialSupply / ETH_AMOUNT):", ratio);

//             try kannonV1.createTokenAndAddLiquidity{value: ethAmount}(
//                 name,
//                 symbol,
//                 description,
//                 imageUrl,
//                 twitter,
//                 telegram,
//                 website,
//                 initialSupply,
//                 lockedLiquidityPercentage
//             ) returns (address tokenAddress) {
//                 CustomToken token = CustomToken(tokenAddress);
//                 assertEq(token.name(), name, "Token name mismatch");
//                 assertEq(token.symbol(), symbol, "Token symbol mismatch");
//                 assertEq(token.totalSupply(), initialSupply, "Initial supply mismatch");

//                 (
//                     address creator,
//                     bool initialLiquidityAdded,
//                     uint256 positionId,
//                     uint256 storedLockedLiquidityPercentage,
//                     uint256 withdrawableLiquidity,
//                     uint256 creationTime,
//                     address poolAddress,
//                     uint128 liquidity
//                 ) = kannonV1.tokenInfo(tokenAddress);

//                 assertEq(creator, user, "Creator mismatch");
//                 assertTrue(initialLiquidityAdded, "Initial liquidity not added");
//                 assertGt(positionId, 0, "Invalid position ID");
//                 assertEq(
//                     storedLockedLiquidityPercentage, lockedLiquidityPercentage, "Locked liquidity percentage mismatch"
//                 );
//                 assertGt(withdrawableLiquidity, 0, "No withdrawable liquidity");
//                 assertEq(creationTime, block.timestamp, "Creation time mismatch");
//                 assertTrue(poolAddress != address(0), "Pool not created");
//                 assertGt(liquidity, 0, "No liquidity added");

//                 IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
//                 assertEq(pool.fee(), fee, "Pool fee mismatch");

//                 INonfungiblePositionManager positionManager = kannonV1.nonfungiblePositionManager();
//                 (
//                     ,
//                     ,
//                     address token0,
//                     address token1,
//                     uint24 positionFee,
//                     int24 positionTickLower,
//                     int24 positionTickUpper,
//                     uint128 positionLiquidity,
//                     ,
//                     ,
//                     ,
//                 ) = positionManager.positions(positionId);

//                 assertTrue(token0 < token1, "Tokens not sorted");
//                 assertTrue(token0 == tokenAddress || token1 == tokenAddress, "Token not in position");
//                 assertEq(positionFee, fee, "Position fee mismatch");
//                 assertGt(positionLiquidity, 0, "No liquidity in position");

//                 console.log("Test passed for Initial Supply:", initialSupply, "and ETH Amount:", ethAmount);
//             } catch Error(string memory reason) {
//                 // console.log("Test failed for Initial Supply:", initialSupply, "and ETH Amount:", ethAmount, "Reason:", reason);
//                 break;
//             }

//             initialSupply = initialSupply * 10;
//             ethAmount = ethAmount * 2;
//         }

//         vm.stopPrank();
//     }

//     function testMinTokenSupplyAndETHRatio() public {
//         vm.startPrank(user);

//         string memory name = "Test Token";
//         string memory symbol = "TST";
//         string memory description = "A test token";
//         string memory imageUrl = "https://example.com/image.png";
//         string memory twitter = "https://twitter.com/example";
//         string memory telegram = "https://t.me/example";
//         string memory website = "https://example.com";

//         uint256 initialSupply = 1e18;
//         uint256 ethAmount = 1 ether;
//         uint256 lockedLiquidityPercentage = 50;
//         uint24 fee = 3000;
//         uint256 minSupply = 1e6;
//         uint256 minEthAmount = 1e15;

//         while (initialSupply >= minSupply && ethAmount >= minEthAmount) {
//             uint256 ratio = initialSupply / ethAmount;
//             console.log("Testing with Initial Supply:", initialSupply);
//             console.log("ETH Amount:", ethAmount);
//             console.log("Current Ratio (InitialSupply / ETH_AMOUNT):", ratio);

//             try kannonV1.createTokenAndAddLiquidity{value: ethAmount}(
//                 name,
//                 symbol,
//                 description,
//                 imageUrl,
//                 twitter,
//                 telegram,
//                 website,
//                 initialSupply,
//                 lockedLiquidityPercentage
//             ) returns (address tokenAddress) {
//                 CustomToken token = CustomToken(tokenAddress);
//                 assertEq(token.name(), name, "Token name mismatch");
//                 assertEq(token.symbol(), symbol, "Token symbol mismatch");
//                 assertEq(token.totalSupply(), initialSupply, "Initial supply mismatch");

//                 (
//                     address creator,
//                     bool initialLiquidityAdded,
//                     uint256 positionId,
//                     uint256 storedLockedLiquidityPercentage,
//                     uint256 withdrawableLiquidity,
//                     uint256 creationTime,
//                     address poolAddress,
//                     uint128 liquidity
//                 ) = kannonV1.tokenInfo(tokenAddress);

//                 assertEq(creator, user, "Creator mismatch");
//                 assertTrue(initialLiquidityAdded, "Initial liquidity not added");
//                 assertGt(positionId, 0, "Invalid position ID");
//                 assertEq(
//                     storedLockedLiquidityPercentage, lockedLiquidityPercentage, "Locked liquidity percentage mismatch"
//                 );
//                 assertGt(withdrawableLiquidity, 0, "No withdrawable liquidity");
//                 assertEq(creationTime, block.timestamp, "Creation time mismatch");
//                 assertTrue(poolAddress != address(0), "Pool not created");
//                 assertGt(liquidity, 0, "No liquidity added");

//                 IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
//                 assertEq(pool.fee(), fee, "Pool fee mismatch");

//                 INonfungiblePositionManager positionManager = kannonV1.nonfungiblePositionManager();
//                 (
//                     ,
//                     ,
//                     address token0,
//                     address token1,
//                     uint24 positionFee,
//                     int24 positionTickLower,
//                     int24 positionTickUpper,
//                     uint128 positionLiquidity,
//                     ,
//                     ,
//                     ,
//                 ) = positionManager.positions(positionId);

//                 assertTrue(token0 < token1, "Tokens not sorted");
//                 assertTrue(token0 == tokenAddress || token1 == tokenAddress, "Token not in position");
//                 assertEq(positionFee, fee, "Position fee mismatch");
//                 assertGt(positionLiquidity, 0, "No liquidity in position");

//                 console.log("Test passed for Initial Supply:", initialSupply, "and ETH Amount:", ethAmount);
//             } catch Error(string memory reason) {
//                 // console.log("Test failed for Initial Supply:", initialSupply, "and ETH Amount:", ethAmount, "Reason:", reason);
//                 break;
//             }

//             initialSupply = initialSupply / 10;
//             ethAmount = ethAmount / 2;
//         }

//         vm.stopPrank();
//     }
// }
