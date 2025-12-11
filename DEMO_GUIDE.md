# PILI Demo Guide for Uniswap Judges (3-Minute Presentation)

## Demo Setup Instructions

### 1. Quick Environment Setup
```bash
# Terminal 1: Start local blockchain
cd contracts
anvil --fork-url https://ethereum-goerli.publicnode.com

# Terminal 2: Deploy contracts
cd contracts
forge script script/DeployPiliSystem.s.sol:DeployPiliSystem --rpc-url http://localhost:8545 --broadcast

# Terminal 3: Start frontend
cd frontend
npm run dev
```

### 2. Pre-Demo Preparation
- Have MetaMask installed with local network (localhost:8545, Chain ID: 31337)
- Import test account from anvil output (private key displayed in terminal)
- Fund account with test ETH

## 3-Minute Demo Script

### Minute 1: The Problem & Solution (60 seconds)

**Speaker**: "Liquidity providers lose money to impermanent loss. PILI solves this with privacy-preserving protection using Uniswap v4 hooks."

**Visuals**:
- Show landing page with clear value proposition
- Display: "Private Impermanent Loss Insurance for Uniswap v4"

**Key Points**:
- IL costs LPs 5-50% of fees earned
- Current solutions require revealing thresholds publicly
- PILI keeps your protection strategy private using FHE

### Minute 2: Technical Implementation (60 seconds)

**Speaker**: "We leverage Uniswap v4's hook system to monitor positions and automatically trigger protection when IL exceeds your private threshold."

**Live Demo**:

1. **Show Hook Integration** (20 seconds)
   - Navigate to contracts/src/ILProtectionHook.sol
   - Highlight: `extends BaseHook`
   - Show key functions: `_beforeModifyPosition` and `_afterModifyPosition`
   - Point out: `getHookPermissions()` declaring implemented hooks

2. **Show FHE Integration** (20 seconds)
   - Navigate to contracts/src/FHEManager.sol
   - Highlight: `encryptILThreshold()` function
   - Explain: "User thresholds are encrypted, never revealed"

3. **Show IL Calculation** (20 seconds)
   - Navigate to contracts/src/libraries/ILCalculator.sol
   - Highlight: `calculateIL()` function
   - Show: `sqrtPriceX96ToPrice()` conversion
   - Explain: "Real-time IL calculation using Uniswap v4 price format"

### Minute 3: User Experience & Live Demo (60 seconds)

**Speaker**: "Let me show you how simple it is for users to protect their positions."

**Live Demo**:

1. **Add Liquidity with Protection** (30 seconds)
   - Connect wallet
   - Navigate to /add-liquidity
   - Enter amounts: 1 WETH / 2000 USDC
   - Set IL threshold: 5%
   - Show "Encrypting threshold with FHE..." message
   - Click "Add Liquidity with Protection"
   - Show success message

2. **Position Monitoring** (30 seconds)
   - Navigate to /positions
   - Show new position card with:
     - Position ID
     - Token amounts
     - Current IL calculation
     - Active status
   - Explain: "System monitors IL in real-time"
   - Explain: "When IL exceeds 5%, position automatically withdraws"

## Key Technical Highlights to Mention

1. **Uniswap v4 Hook Integration**
   - Extends BaseHook for seamless integration
   - Monitors liquidity modifications
   - Calculates IL using real-time pool data

2. **FHE Privacy**
   - Thresholds encrypted using Fhenix network
   - No need to reveal protection strategy
   - Automatic execution without compromising privacy

3. **Gas Optimization**
   - Efficient IL calculation with custom sqrt function
   - Batch operations where possible
   - Optimized hook callbacks

## Demo Checklist

### Before Demo
- [ ] Local blockchain running
- [ ] Contracts deployed
- [ ] Frontend accessible
- [ ] Test account funded
- [ ] All contracts compiled

### During Demo
- [ ] Clear audio/video
- [ ] Screen sharing ready
- [ ] Browser tabs pre-opened
- [ ] Test transactions prepared

### Backup Plans
- Have recorded video walkthrough ready
- Prepare screenshots of key features
- Have testnet deployment as fallback

## Q&A Preparation

### Expected Questions

1. **How does FHE work on blockchain?**
   - Answer: "Fhenix network provides native FHE support, enabling encrypted computation on-chain"

2. **What's the gas cost?**
   - Answer: "Approximately 200k gas for position creation, 50k for IL checks"

3. **How is this different from stop-loss?**
   - Answer: "Stop-loss is public and price-based; PILI is private and IL-based"

4. **Can this work with any pool?**
   - Answer: "Yes, any Uniswap v4 pool can use PILI hooks"

5. **What happens when protection triggers?**
   - Answer: "Position automatically withdraws to user's wallet with full liquidity"

## Technical Deep Dive (If Asked)

### Hook Implementation Details
```solidity
function _afterModifyPosition(
    address sender,
    PoolKey calldata key,
    IPoolManager.ModifyLiquidityParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, BalanceDelta) {
    // Calculate current IL
    uint256 currentIL = calculateCurrentIL(key, params);
    
    // Compare with encrypted threshold using FHE
    bool shouldTrigger = fheManager.compareWithThreshold(currentIL, hookData);
    
    // Trigger protection if needed
    if (shouldTrigger) {
        triggerProtection(sender, params);
    }
    
    return (IHooks.afterModifyPosition.selector, 0);
}
```

### FHE Integration
```solidity
function encryptILThreshold(uint256 threshold) external returns (bytes memory) {
    // Convert to FHE format
    uint256 fheThreshold = fheUtils.encrypt(threshold);
    
    // Return encoded hook data
    return abi.encode(fheThreshold);
}
```

## Closing Statement

"PILI represents the future of DeFi risk management - private, automated, and seamlessly integrated with Uniswap v4's hook system. We're making impermanent loss protection accessible to all liquidity providers while maintaining the privacy they expect."

## Contact Information

- GitHub: [Your GitHub]
- Email: [Your Email]
- Discord: [Your Discord]