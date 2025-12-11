#!/bin/bash

# PILI Demo Setup Script
# This script sets up the environment for a 3-minute demo to Uniswap judges

echo "🚀 Setting up PILI Demo Environment..."

# Check if required tools are installed
if ! command -v anvil &> /dev/null; then
    echo "❌ Anvil not found. Please install Foundry first."
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi

# Create demo directory
DEMO_DIR="pili_demo_$(date +%s)"
mkdir -p $DEMO_DIR
cd $DEMO_DIR

echo "📁 Created demo directory: $DEMO_DIR"

# Start anvil in background
echo "🔧 Starting local blockchain..."
anvil --fork-url https://ethereum-goerli.publicnode.com --accounts 10 > anvil.log 2>&1 &
ANVIL_PID=$!
sleep 5

# Extract private key from anvil output
PRIVATE_KEY=$(grep "Private Key" anvil.log | head -1 | awk '{print $3}')
echo "🔑 Test account private key: $PRIVATE_KEY"

# Deploy contracts
echo "📜 Deploying PILI contracts..."
cd ../contracts
forge script script/DeployPiliSystem.s.sol:DeployPiliSystem \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY \
  --broadcast > deploy.log 2>&1

# Extract deployed addresses
POOL_MANAGER=$(grep "PoolManager deployed at:" deploy.log | awk '{print $3}')
IL_HOOK=$(grep "ILProtectionHook deployed at:" deploy.log | awk '{print $3}')

echo "✅ Contracts deployed:"
echo "   PoolManager: $POOL_MANAGER"
echo "   ILProtectionHook: $IL_HOOK"

# Create .env for frontend
cd ../frontend
cat > .env.local << EOF
NEXT_PUBLIC_POOL_MANAGER_ADDRESS=$POOL_MANAGER
NEXT_PUBLIC_IL_PROTECTION_HOOK_ADDRESS=$IL_HOOK
NEXT_PUBLIC_RPC_URL=http://localhost:8545
NEXT_PUBLIC_CHAIN_ID=31337
EOF

echo "📝 Created frontend .env.local"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing frontend dependencies..."
    npm install
fi

# Start frontend
echo "🌐 Starting frontend application..."
npm run dev > frontend.log 2>&1 &
FRONTEND_PID=$!

sleep 10

echo ""
echo "🎉 Demo environment is ready!"
echo ""
echo "📋 Demo Instructions:"
echo "1. Open MetaMask and add local network:"
echo "   - Network Name: PILI Demo"
echo "   - RPC URL: http://localhost:8545"
echo "   - Chain ID: 31337"
echo "   - Currency Symbol: ETH"
echo ""
echo "2. Import test account in MetaMask:"
echo "   - Private Key: $PRIVATE_KEY"
echo ""
echo "3. Open browser to: http://localhost:3000"
echo ""
echo "4. Demo Script:"
echo "   - Minute 1: Explain problem & solution"
echo "   - Minute 2: Show technical implementation"
echo "   - Minute 3: Live user demo"
echo ""
echo "📝 Press Ctrl+C to stop all services"
echo ""

# Wait for user to stop
trap 'echo "🛑 Stopping demo services..."; kill $ANVIL_PID $FRONTEND_PID; exit' INT
wait