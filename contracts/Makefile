# PILI Contract Deployment Makefile

# Variables
FHENIX_RPC_URL ?= https://helix.fhenix.zone
FHENIX_CHAIN_ID ?= 8008
ETHERSCAN_API_KEY ?= $(shell grep ETHERSCAN_API_KEY .env 2>/dev/null || echo "")
PRIVATE_KEY ?= $(shell grep PRIVATE_KEY .env 2>/dev/null || echo "")
POOL_MANAGER_ADDRESS ?= $(shell grep POOL_MANAGER_ADDRESS .env 2>/dev/null || echo "")

# Default target
.PHONY: help
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# Setup
.PHONY: setup
setup: ## Setup environment and install dependencies
	@if [ ! -f .env ]; then echo "Creating .env file..."; cp .env.example .env; fi
	@forge install
	@echo "Setup complete. Please edit .env with your values."

# Build
.PHONY: build
build: ## Build all contracts
	@forge build

# Test
.PHONY: test
test: ## Run all tests
	@forge test

# Test with gas report
.PHONY: test-gas
test-gas: ## Run tests with gas report
	@forge test --gas-report

# Deploy to testnet
.PHONY: deploy-testnet
deploy-testnet: ## Deploy contracts to Fhenix testnet
	@echo "Deploying to Fhenix testnet..."
	@forge script script/Deploy.s.sol \
		--rpc-url $(FHENIX_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY)

# Deploy without verification
.PHONY: deploy-no-verify
deploy-no-verify: ## Deploy without verification (for testing)
	@echo "Deploying without verification..."
	@forge script script/Deploy.s.sol \
		--rpc-url $(FHENIX_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast

# Verify contract
.PHONY: verify
verify: ## Verify deployed contract
	@echo "Verifying contract..."
	@forge verify-contract $(CONTRACT_ADDRESS) \
		src/ILProtectionHook.sol:ILProtectionHook \
		--chain-id $(FHENIX_CHAIN_ID) \
		--etherscan-api-key $(ETHERSCAN_API_KEY)

# Check deployment
.PHONY: check
check: ## Check deployment status
	@echo "Checking contract at $(CONTRACT_ADDRESS)..."
	@cast call \
		--rpc-url $(FHENIX_RPC_URL) \
		$(CONTRACT_ADDRESS) \
		"owner()(address)"

# Get active positions
.PHONY: positions
positions: ## Get active positions from contract
	@echo "Fetching active positions..."
	@cast call \
		--rpc-url $(FHENIX_RPC_URL) \
		$(CONTRACT_ADDRESS) \
		"getActivePositions(bytes32)(uint256[])" $(POOL_ID)

# Clean
.PHONY: clean
clean: ## Clean build artifacts
	@forge clean

# Format
.PHONY: fmt
fmt: ## Format Solidity code
	@forge fmt

# Lint
.PHONY: lint
lint: ## Lint Solidity code
	@forge fmt --check
	@forge --version

# Snapshot
.PHONY: snapshot
snapshot: ## Run gas snapshot
	@forge snapshot

# Anvil local node
.PHONY: anvil
anvil: ## Start local Anvil node
	@anvil --fork-url $(FHENIX_RPC_URL) --chain-id $(FHENIX_CHAIN_ID)

# Deploy to local
.PHONY: deploy-local
deploy-local: ## Deploy to local Anvil node
	@forge script script/Deploy.s.sol \
		--rpc-url http://localhost:8545 \
		--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
		--broadcast

# Generate ABI
.PHONY: abi
abi: ## Generate ABI for frontend
	@echo "Generating ABI..."
	@mkdir -p ../frontend/abis
	@cp out/ILProtectionHook.sol/ILProtectionHook.json ../frontend/abis/
	@echo "ABI copied to frontend/abis/"

# Full deployment workflow
.PHONY: deploy-all
deploy-all: build deploy-testnet abi ## Build, deploy, and copy ABI
	@echo "Deployment complete!"
	@echo "Contract deployed at: $(shell forge script script/Deploy.s.sol --rpc-url $(FHENIX_RPC_URL) --private-key $(PRIVATE_KEY) --json | jq -r '.returns[0].value')"

# Test FHE operations
.PHONY: test-fhe
test-fhe: ## Test FHE operations specifically
	@forge test --match-test testFHE -vv

# Gas estimate
.PHONY: gas-estimate
gas-estimate: ## Estimate gas for deployment
	@forge script script/Deploy.s.sol \
		--rpc-url $(FHENIX_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--dry-run

# Watch for changes
.PHONY: watch
watch: ## Watch for changes and rebuild
	@forge build --watch

# Documentation
.PHONY: docs
docs: ## Generate documentation
	@forge doc
	@echo "Documentation generated in docs/"