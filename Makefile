include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy-anvil                 Deploy to local Anvil network"
	@echo "  make deploy-arbitrum-sepolia      Deploy to Arbitrum Sepolia testnet"
	@echo "  make deploy-sepolia               Deploy to Ethereum Sepolia testnet"
	@echo "  make deploy-optimism-sepolia      Deploy to Optimism Sepolia testnet"
	@echo "  make test-anvil                   Run tests on local Anvil network"
	@echo "  make test-arbitrum-sepolia        Run tests on Arbitrum Sepolia fork"
	@echo "  make test-sepolia                 Run tests on Ethereum Sepolia fork"
	@echo "  make test-optimism-sepolia        Run tests on Optimism Sepolia fork"
	@echo "  make anvil                        Start local Anvil network"
	@echo "  make anvil-arbitrum-sepolia       Start Anvil forked from Arbitrum Sepolia"
	@echo "  make anvil-sepolia                Start Anvil forked from Ethereum Sepolia"
	@echo "  make anvil-optimism-sepolia       Start Anvil forked from Optimism Sepolia"

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.1.0 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit && forge install foundry-rs/forge-std@v1.5.3 --no-commit && forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

coverage :; forge coverage --report debug > coverage-report.txt

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 12
anvil-arbitrum-sepolia :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1 --fork-url $(ARBITRUM_SEPOLIA_RPC_URL) --chain-id 421614 --host 0.0.0.0 
anvil-sepolia :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1 --fork-url $(SEPOLIA_RPC_URL) --chain-id 11155111 --host 0.0.0.0 
anvil-optimism-sepolia :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1 --fork-url $(OPTIMISM_SEPOLIA_RPC_URL) --chain-id 11155420 --host 0.0.0.0

# Deployment commands
deploy-anvil:
	@forge script script/deployKannonV1.s.sol:DeployKannonV1 --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

deploy-arbitrum-sepolia:
	@forge script script/deployKannonV1.s.sol:DeployKannonV1 --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --private-key $(ARBITRUM_SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ARBISCAN_API_KEY) -vvvv --use solc:0.8.19

deploy-sepolia:
	@forge script script/deployKannonV1.s.sol:DeployKannonV1 --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-optimism-sepolia:
	@forge script script/deployKannonV1.s.sol:DeployKannonV1 --rpc-url $(OPTIMISM_SEPOLIA_RPC_URL) --private-key $(OPTIMISM_SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(OPTIMISM_ETHERSCAN_API_KEY) -vvvv

deploy-all:
	@echo "Deploying to Sepolia..."
	@forge script script/deployAndSetPeers.s.sol:DeployKannonV1CrossChainSender --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv --use solc:0.8.19
	@echo "Deploying to Optimism Sepolia..."
	@forge script script/deployAndSetPeers.s.sol:DeployKannonV1CrossChainSender --rpc-url $(OPTIMISM_SEPOLIA_RPC_URL) --private-key $(OPTIMISM_SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(OPTIMISM_ETHERSCAN_API_KEY) -vvvv --use solc:0.8.19
	@echo "Setting peers on Arbitrum Sepolia..."
	@forge script script/deployAndSetPeers.s.sol:DeployKannonV1CrossChainSender --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --private-key $(ARBITRUM_SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ARBISCAN_API_KEY) -vvvv --use solc:0.8.19

deploy-contracts:
    @echo "Deploying to arbitrum sepolia"
	@forge script script/DeployKannonV1CrossChainSender.s.sol:DeployKannonV1CrossChainSender --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --private-key $(ARBITRUM_SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ARBISCAN_API_KEY) -vvvv --use solc:0.8.19
	@echo "Deploying KannonV1CrossChainSender to Sepolia..."
	@forge script script/DeployKannonV1CrossChainSender.s.sol:DeployKannonV1CrossChainSender --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv --use solc:0.8.19
	@echo "Deploying KannonV1CrossChainSender to Optimism Sepolia..."
	@forge script script/DeployKannonV1CrossChainSender.s.sol:DeployKannonV1CrossChainSender --rpc-url $(OPTIMISM_SEPOLIA_RPC_URL) --private-key $(OPTIMISM_SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(OPTIMISM_ETHERSCAN_API_KEY) -vvvv --use solc:0.8.19

set-peers:
	@echo "Setting peers on Arbitrum Sepolia..."
	@forge script script/SetPeers.s.sol:SetPeers --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --private-key $(ARBITRUM_SEPOLIA_PRIVATE_KEY) --broadcast -vvvv --use solc:0.8.19
	@echo "Setting peers on Sepolia..."
	@forge script script/SetPeers.s.sol:SetPeers --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --broadcast -vvvv --use solc:0.8.19
	@echo "Setting peers on Optimism Sepolia..."
	@forge script script/SetPeers.s.sol:SetPeers --rpc-url $(OPTIMISM_SEPOLIA_RPC_URL) --private-key $(OPTIMISM_SEPOLIA_PRIVATE_KEY) --broadcast -vvvv --use solc:0.8.19


build-19:
	@forge build --use solc:0.8.19
# Test commands
test-anvil:
	@forge test

test-arbitrum-sepolia:
	@forge test --fork-url $(ARBITRUM_SEPOLIA_RPC_URL) $(ARGS)

test-sepolia:
	@forge test --fork-url $(SEPOLIA_RPC_URL)

test-optimism-sepolia:
	@forge test --fork-url $(OPTIMISM_SEPOLIA_RPC_URL) $(ARGS)
	