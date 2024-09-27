// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test} from "forge-std/Test.sol";
// import {KannonV1} from "../../../src/solving-overflow-and-underflow-error.sol";
// import {CustomToken} from "../../../src/customToken.sol";
// import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
// contract KannonV1Handler is Test {
//     KannonV1 public KannonV1;
//     address public user;
//     address[] public createdTokens;

//     // Define constants for bounds
//     uint256 constant MIN_ETH_AMOUNT = 1e12;      // 0.000001 ETH in wei
//     uint256 constant MAX_ETH_AMOUNT = 1e27;      // 1 billion ETH in wei
//     uint256 constant MIN_INITIAL_SUPPLY = 1e18;  // 1 token (assuming 18 decimals)
//     uint256 constant MAX_INITIAL_SUPPLY = 1e27;  // 1e9 tokens (1 billion)

//     constructor(KannonV1 _KannonV1, address _user) {
//         KannonV1 = _KannonV1;
//         user = _user;
//         vm.deal(user, 1e30); // Provide ample ETH for testing
//     }

//     /**
//      * @dev Creates a token and adds liquidity with randomized parameters within specified bounds.
//      */
//     function createTokenAndAddLiquidity() external {
//         // Generate random initialSupply and ethAmount within bounds
//         uint256 initialSupply = bound(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number))), MIN_INITIAL_SUPPLY, MAX_INITIAL_SUPPLY);
//         uint256 ethAmount = bound(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number))), MIN_ETH_AMOUNT, MAX_ETH_AMOUNT);

//         // Define token parameters
//         string memory name = string(abi.encodePacked("TestToken", Strings.toString(initialSupply)));
//         string memory symbol = string(abi.encodePacked("TTK", Strings.toString(initialSupply % 1000)));
//         string memory description = "A test token for invariant testing";
//         string memory imageUrl = "https://example.com/image.png";
//         string memory twitter = "@invarianttest";
//         string memory telegram = "@invarianttest";
//         string memory website = "https://invarianttest.com";
//         uint256 lockedLiquidityPercentage = bound(uint256(keccak256(abi.encodePacked(block.timestamp))), 1, 100); // 1-100%

//         // Start pretending to be the user
//         vm.startPrank(user);

//         // Call createTokenAndAddLiquidity
//         address tokenAddress = KannonV1.createTokenAndAddLiquidity{value: ethAmount}(
//             user,
//             name,
//             symbol,
//             description,
//             imageUrl,
//             twitter,
//             telegram,
//             website,
//             initialSupply,
//             lockedLiquidityPercentage
//         );

//         // Record the created token
//         createdTokens.push(tokenAddress);

//         // Stop pretending to be the user
//         vm.stopPrank();
//     }

//     /**
//      * @dev Retrieves all created tokens.
//      */
//     function getCreatedTokens() external view returns (address[] memory) {
//         return createdTokens;
//     }
// }
