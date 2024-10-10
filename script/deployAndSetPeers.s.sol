// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {KannonV1} from "../src/kannon_v1.sol";
import {KannonV1CrossChainSender} from "../src/kannon_v1_crosschain_sender.sol";

contract DeployKannonV1CrossChainSender is Script {
    struct DeploymentInfo {
        uint256 chainId;
        address endpointV2;
    }

    DeploymentInfo public info;
    mapping(uint32 => address) public crossChainSenders;
    address payable public kannonV1Address;

    function run() external {
        info.chainId = block.chainid;
        console.log("Chain ID:", info.chainId);

        uint256 deployerPrivateKey = getPrivateKey();
        setAddressesFromEnv();

        // Set the KannonV1 address (replace with actual address from first script)
        kannonV1Address = payable(0xfd08d522f777333E9dE811a40deDcDC3f6E07f5F);

        vm.startBroadcast(deployerPrivateKey);
        address deployedContract = deployKannonV1CrossChainSender();
        setPeersNow(deployedContract);
        vm.stopBroadcast();
    }

    function deployKannonV1CrossChainSender() internal returns (address) {
        KannonV1CrossChainSender sender = new KannonV1CrossChainSender(info.endpointV2, 1);
        console.log("KannonV1CrossChainSender deployed at:", address(sender));
        return address(sender);
    }

    function setPeersNow(address crossChainSender) internal {
        // require(kannonV1Address != address(0), "KannonV1 address not set");
        // require(crossChainSender != address(0), "CrossChainSender not deployed");

        KannonV1 kannonV1 = KannonV1(kannonV1Address);
        uint32 eid = getEidForChainId(uint32(info.chainId));
        bytes32 peerAddressBytes32 = bytes32(uint256(uint160(crossChainSender)));

        try kannonV1.setPeer(eid, peerAddressBytes32) {
            console.log("Set peer for Chain ID:");
        } catch Error(string memory reason) {
            console.log("Failed to set peer for Chain ID:- Reason:");
        } catch (bytes memory lowLevelData) {
            console.log("Failed to set peer for Chain ID:- Low level error");
        }
    }

    function getEidForChainId(uint32 chainId) internal pure returns (uint32) {
        if (chainId == 11155111) return 40161; // Sepolia Testnet
        if (chainId == 11155420) return 40232; // Optimism Sepolia (assuming same as Goerli for now)
        revert("Unsupported chain ID");
    }

    function getPrivateKey() internal view returns (uint256) {
        if (info.chainId == 31337) {
            return vm.envUint("PRIVATE_KEY");
        } else if (info.chainId == 11155111) {
            return vm.envUint("SEPOLIA_PRIVATE_KEY");
        } else if (info.chainId == 11155420) {
            return vm.envUint("OPTIMISM_SEPOLIA_PRIVATE_KEY");
        } else {
            revert("Unsupported chain ID");
        }
    }

    function setAddressesFromEnv() internal {
        if (info.chainId == 11155111) {
            // Sepolia testnet
            info.endpointV2 = vm.envAddress("SEPOLIA_STARGATE_ENDPOINT_V2");
        } else if (info.chainId == 11155420) {
            // Optimism Sepolia testnet
            info.endpointV2 = vm.envAddress("OPTIMISM_SEPOLIA_STARGATE_ENDPOINT_V2");
        } else {
            revert("Unsupported chain ID");
        }
    }

    function getSupportedChainIds() internal pure returns (uint32[] memory) {
        uint32[] memory chainIds = new uint32[](2);
        chainIds[0] = 11155111; // Sepolia
        chainIds[1] = 11155420; // Optimism Sepolia
        return chainIds;
    }
}
