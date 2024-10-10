// pragma solidity ^0.8.19;

// import {Script} from "forge-std/Script.sol";
// import {console} from "forge-std/console.sol";
// // import {MainEngine} from "../src/solving-overflow-and-underflow-error.sol";
// import {KannonV1} from "../src/kannon_v1.sol";
// // import {KannonV1} from "../src/aside-store-kannon_v1.sol";

// import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
// import {ISwapRouter02} from "@uniswap/v3-swap-routers/contracts/interfaces/ISwapRouter02.sol";

// import {IWETH9} from "../test/mocks/IWETH.sol";

// contract DeployKannonV1 is Script {
//     struct DeploymentInfo {
//         address factory;
//         address nonfungiblePositionManager;
//         address swapRouter02;
//         address WETH9;
//         uint256 chainId;
//         address stargatePoolNative;
//         address endpointV2;
//     }

//     DeploymentInfo public info;

//     function run() external returns (KannonV1, DeploymentInfo memory) {
//         info.chainId = block.chainid;
//         console.log("Chain ID:", info.chainId);

//         uint256 deployerPrivateKey;
//         if (info.chainId == 31337) {
//             // Anvil (local development network)
//             deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         } else if (info.chainId == 11155111) {
//             // Sepolia testnet
//             deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
//         } else if (info.chainId == 421614) {
//             // Arbitrum Sepolia testnet
//             deployerPrivateKey = vm.envUint("ARBITRUM_SEPOLIA_PRIVATE_KEY");
//         } else if (info.chainId == 11155420) {
//             // Optimism Sepolia testnet
//             deployerPrivateKey = vm.envUint("OPTIMISM_SEPOLIA_PRIVATE_KEY");
//         } else {
//             revert("Unsupported chain ID");
//         }
//         console.log("Using private key from .env file");

//         setAddressesFromEnv();
//         vm.startBroadcast(deployerPrivateKey);

//         KannonV1 kannonV1 = new KannonV1(
//             IUniswapV3Factory(info.factory),
//             INonfungiblePositionManager(info.nonfungiblePositionManager),
//             ISwapRouter02(info.swapRouter02),
//             info.WETH9,
//             info.stargatePoolNative,
//             info.endpointV2,
//             msg.sender,
//             1
//         );
//         vm.stopBroadcast();

//         return (kannonV1, info);
//     }

//     function setAddressesFromEnv() internal {
//         if (info.chainId == 11155111) {
//             // Sepolia testnet
//             info.factory = vm.envAddress("SEPOLIA_UNISWAP_V3_FACTORY");
//             info.nonfungiblePositionManager = vm.envAddress("SEPOLIA_NONFUNGIBLE_POSITION_MANAGER");
//             info.swapRouter02 = vm.envAddress("SEPOLIA_SWAP_ROUTER");
//             info.WETH9 = vm.envAddress("SEPOLIA_WETH9");
//             info.stargatePoolNative = vm.envAddress("SEPOLIA_STARGATE_POOL_NATIVE");
//             info.endpointV2 = vm.envAddress("SEPOLIA_STARGATE_ENDPOINT_V2");
//         } else if (info.chainId == 421614) {
//             // Arbitrum Sepolia testnet
//             info.factory = vm.envAddress("ARBITRUM_SEPOLIA_UNISWAP_V3_FACTORY");
//             info.nonfungiblePositionManager = vm.envAddress("ARBITRUM_SEPOLIA_NONFUNGIBLE_POSITION_MANAGER");
//             info.swapRouter02 = vm.envAddress("ARBITRUM_SEPOLIA_SWAP_ROUTER");
//             info.WETH9 = vm.envAddress("ARBITRUM_SEPOLIA_WETH9");
//             info.stargatePoolNative = vm.envAddress("ARBITRUM_SEPOLIA_STARGATE_POOL_NATIVE");
//             info.endpointV2 = vm.envAddress("ARBITRUM_SEPOLIA_STARGATE_ENDPOINT_V2");
//         } else if (info.chainId == 11155420) {
//             // Optimism Sepolia testnet
//             info.factory = vm.envAddress("OPTIMISM_SEPOLIA_UNISWAP_V3_FACTORY");
//             info.nonfungiblePositionManager = vm.envAddress("OPTIMISM_SEPOLIA_NONFUNGIBLE_POSITION_MANAGER");
//             info.swapRouter02 = vm.envAddress("OPTIMISM_SEPOLIA_SWAP_ROUTER");
//             info.WETH9 = vm.envAddress("OPTIMISM_SEPOLIA_WETH9");
//             info.stargatePoolNative = vm.envAddress("OPTIMISM_SEPOLIA_STARGATE_POOL_NATIVE");
//             info.endpointV2 = vm.envAddress("OPTIMISM_SEPOLIA_STARGATE_ENDPOINT_V2");
//         } else {
//             // Default to original env variables (e.g., for local development)
//             info.factory = vm.envAddress("UNISWAP_V3_FACTORY");
//             info.nonfungiblePositionManager = vm.envAddress("NONFUNGIBLE_POSITION_MANAGER");
//             info.swapRouter02 = vm.envAddress("SWAP_ROUTER");
//             info.WETH9 = vm.envAddress("WETH9");
//             info.stargatePoolNative = vm.envAddress("STARGATE_POOL_NATIVE");
//             info.endpointV2 = vm.envAddress("STARGATE_ENDPOINT_V2");
//         }
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {KannonV1} from "../src/kannon_v1.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {ISwapRouter02} from "@uniswap/v3-swap-routers/contracts/interfaces/ISwapRouter02.sol";

contract DeployKannonV1 is Script {
    struct DeploymentInfo {
        address factory;
        address nonfungiblePositionManager;
        address swapRouter02;
        address WETH9;
        uint256 chainId;
        address stargatePoolNative;
        address endpointV2;
    }

    DeploymentInfo public info;

    function run() external {
        info.chainId = block.chainid;
        console.log("Chain ID:", info.chainId);

        uint256 deployerPrivateKey = getPrivateKey();
        setAddressesFromEnv();

        vm.startBroadcast(deployerPrivateKey);

        address kannonV1Address = deployKannonV1();

        vm.stopBroadcast();

        console.log("KannonV1 deployed at:", kannonV1Address);
        console.log("Copy this address for use in the second script.");
    }

    function deployKannonV1() internal returns (address) {
        KannonV1 kannonV1 = new KannonV1(
            IUniswapV3Factory(info.factory),
            INonfungiblePositionManager(info.nonfungiblePositionManager),
            ISwapRouter02(info.swapRouter02),
            info.WETH9,
            info.stargatePoolNative,
            info.endpointV2,
            1,
            500,
            250,
            250
        );
        return address(kannonV1);
    }

    function getPrivateKey() internal view returns (uint256) {
        if (info.chainId == 31337) {
            return vm.envUint("PRIVATE_KEY");
        } else if (info.chainId == 11155111) {
            return vm.envUint("SEPOLIA_PRIVATE_KEY");
        } else if (info.chainId == 421614) {
            return vm.envUint("ARBITRUM_SEPOLIA_PRIVATE_KEY");
        } else if (info.chainId == 11155420) {
            return vm.envUint("OPTIMISM_SEPOLIA_PRIVATE_KEY");
        } else {
            revert("Unsupported chain ID");
        }
    }

    function setAddressesFromEnv() internal {
        if (info.chainId == 11155111) {
            // Sepolia testnet
            info.factory = vm.envAddress("SEPOLIA_UNISWAP_V3_FACTORY");
            info.nonfungiblePositionManager = vm.envAddress("SEPOLIA_NONFUNGIBLE_POSITION_MANAGER");
            info.swapRouter02 = vm.envAddress("SEPOLIA_SWAP_ROUTER");
            info.WETH9 = vm.envAddress("SEPOLIA_WETH9");
            info.stargatePoolNative = vm.envAddress("SEPOLIA_STARGATE_POOL_NATIVE");
            info.endpointV2 = vm.envAddress("SEPOLIA_STARGATE_ENDPOINT_V2");
        } else if (info.chainId == 421614) {
            // Arbitrum Sepolia testnet
            info.factory = vm.envAddress("ARBITRUM_SEPOLIA_UNISWAP_V3_FACTORY");
            info.nonfungiblePositionManager = vm.envAddress("ARBITRUM_SEPOLIA_NONFUNGIBLE_POSITION_MANAGER");
            info.swapRouter02 = vm.envAddress("ARBITRUM_SEPOLIA_SWAP_ROUTER");
            info.WETH9 = vm.envAddress("ARBITRUM_SEPOLIA_WETH9");
            info.stargatePoolNative = vm.envAddress("ARBITRUM_SEPOLIA_STARGATE_POOL_NATIVE");
            info.endpointV2 = vm.envAddress("ARBITRUM_SEPOLIA_STARGATE_ENDPOINT_V2");
        } else if (info.chainId == 11155420) {
            // Optimism Sepolia testnet
            info.factory = vm.envAddress("OPTIMISM_SEPOLIA_UNISWAP_V3_FACTORY");
            info.nonfungiblePositionManager = vm.envAddress("OPTIMISM_SEPOLIA_NONFUNGIBLE_POSITION_MANAGER");
            info.swapRouter02 = vm.envAddress("OPTIMISM_SEPOLIA_SWAP_ROUTER");
            info.WETH9 = vm.envAddress("OPTIMISM_SEPOLIA_WETH9");
            info.stargatePoolNative = vm.envAddress("OPTIMISM_SEPOLIA_STARGATE_POOL_NATIVE");
            info.endpointV2 = vm.envAddress("OPTIMISM_SEPOLIA_STARGATE_ENDPOINT_V2");
        } else {
            revert("Unsupported chain ID");
        }
    }
}
