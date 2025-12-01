# PRD Analysis & Understanding Guide
## FHE-Protected IL Insurance Hook for Uniswap v4

---

## 🎯 What Problem Does This Solve?

### The Core Problem: Impermanent Loss (IL)

**What is Impermanent Loss?**

Imagine you're a liquidity provider (LP) on Uniswap. You deposit $10,000 worth of ETH and USDC into a pool:
- 5 ETH @ $1,000 each = $5,000
- 5,000 USDC = $5,000
- **Total:** $10,000

Now, ETH price doubles to $2,000. If you had just held (HODL) your tokens:
- 5 ETH @ $2,000 = $10,000
- 5,000 USDC = $5,000
- **Total:** $15,000

But because you're an LP, the Automated Market Maker (AMM) rebalances your position:
- ~3.54 ETH @ $2,000 = $7,080
- ~7,080 USDC = $7,080
- **Total:** $14,160

**You lost $840 compared to just holding!** This is impermanent loss.

### Current Pain Points

1. **No Automated Protection:** LPs must manually monitor positions 24/7
2. **Public Risk Parameters:** If you set a stop-loss, MEV bots can front-run your exit
3. **Lack of Granular Control:** Can't set sophisticated risk management rules
4. **Privacy Issues:** Your trading strategy is visible to competitors

---

## 🔐 The Solution: FHE-Protected Hooks

### What is FHE (Fully Homomorphic Encryption)?

**Traditional Encryption:**
- Encrypt data → Store/transmit → Decrypt to use
- **Problem:** Must decrypt to perform calculations

**Fully Homomorphic Encryption:**
- Encrypt data → **Compute on encrypted data** → Decrypt result
- **Benefit:** Never expose the original data, even during computation

**Example:**
```
Traditional: Encrypt(5) → Decrypt → 5 > 3? → True
FHE:         Encrypt(5) → Encrypt(3) → Encrypt(5) > Encrypt(3)? → Encrypt(True)
```

### How This Applies to IL Protection

1. **LP sets IL threshold:** "Exit if IL > 5%"
2. **Client-side encryption:** 5% → Encrypt(500 basis points) → euint32
3. **On-chain storage:** Encrypted threshold stored on blockchain
4. **After each swap:** 
   - Calculate current IL → Encrypt(current IL)
   - Compare: Encrypt(current IL) > Encrypt(threshold)?
   - Result: Encrypt(True/False)
5. **Conditional execution:** If Encrypt(True), withdraw liquidity
6. **Privacy preserved:** No one knows your 5% threshold, not even the blockchain!

---

## 🏗️ Architecture Breakdown

### Component 1: Uniswap v4 Hooks

**What are Hooks?**

Uniswap v4 introduced "hooks" - custom code that runs at specific points in the swap lifecycle:

- `beforeSwap()` - Runs before a swap executes
- `afterSwap()` - Runs after a swap executes
- `beforeAddLiquidity()` - Runs before liquidity is added
- `afterAddLiquidity()` - Runs after liquidity is added
- `beforeRemoveLiquidity()` - Runs before liquidity is removed
- `afterRemoveLiquidity()` - Runs after liquidity is removed

**This PRD uses:**

1. **`beforeAddLiquidity()`** - Register LP's encrypted protection parameters
2. **`afterSwap()`** - Check if IL threshold breached, trigger withdrawal if needed

### Component 2: IL Protection Hook

**Flow Diagram:**

```
┌─────────────────────────────────────────────────────────────┐
│ 1. LP Deposits Liquidity                                    │
│    - Input: 10 ETH + 25,000 USDC                           │
│    - Set IL threshold: 5% (encrypted client-side)          │
│    - beforeAddLiquidity() stores encrypted params          │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Trader Swaps in Pool                                     │
│    - Someone swaps 1 ETH for USDC                          │
│    - Pool price changes                                     │
│    - afterSwap() hook triggers                             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. IL Calculation (afterSwap)                               │
│    - Get new pool price                                     │
│    - Calculate current IL for each LP position             │
│    - IL = 2*sqrt(priceRatio)/(1+priceRatio) - 1           │
│    - Example: IL = 2.4% (in basis points: 240)            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. FHE Comparison                                           │
│    - Encrypt current IL: Encrypt(240)                      │
│    - Compare: Encrypt(240) > Encrypt(500)?                │
│    - Result: Encrypt(False) - threshold not breached       │
│    - No action taken                                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Later: IL Exceeds Threshold                              │
│    - Price moves more, IL now 6% (600 basis points)       │
│    - Encrypt(600) > Encrypt(500)?                          │
│    - Result: Encrypt(True) - THRESHOLD BREACHED!           │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Automated Withdrawal                                     │
│    - FHE.req(shouldExit) enforces condition                │
│    - Call PoolManager.removeLiquidity()                    │
│    - Return ETH + USDC to LP's wallet                      │
│    - Mark position as inactive                             │
│    - Emit event (without revealing threshold)              │
└─────────────────────────────────────────────────────────────┘
```

### Component 3: Price Bounds Hook

**What it does:**

Instead of (or in addition to) IL protection, LPs can set price boundaries:

- **Upper Bound:** "Exit if ETH price > $3,000"
- **Lower Bound:** "Exit if ETH price < $1,500"

**Why it's useful:**

- Simpler to understand than IL
- Protects against specific price movements
- Can be combined with IL protection

**Example:**

```
LP deposits at ETH = $2,000
Sets bounds: $1,800 - $2,200 (±10%)

If ETH drops to $1,750:
  - Encrypt(1750) < Encrypt(1800)?
  - Result: Encrypt(True)
  - Automatic withdrawal triggered
```

---

## 🔢 Key Technical Concepts

### 1. Impermanent Loss Formula

```
IL = 2 * sqrt(priceRatio) / (1 + priceRatio) - 1

Where:
  priceRatio = currentPrice / entryPrice
```

**Example Calculation:**

```
Entry price: ETH = $2,000
Current price: ETH = $2,500
priceRatio = 2500 / 2000 = 1.25

IL = 2 * sqrt(1.25) / (1 + 1.25) - 1
   = 2 * 1.118 / 2.25 - 1
   = 2.236 / 2.25 - 1
   = 0.9938 - 1
   = -0.0062
   = -0.62% (negative means loss)
```

### 2. Basis Points

- **1 basis point (bp)** = 0.01%
- **100 bp** = 1%
- **500 bp** = 5%

**Why use basis points?**
- Avoid decimals in smart contracts (gas-efficient)
- Precision: Can represent 0.01% granularity

### 3. Uniswap v4 Price Format: sqrtPriceX96

Uniswap v4 stores prices as `sqrt(price) * 2^96` for precision and gas efficiency.

**Conversion:**

```solidity
// sqrtPriceX96 to regular price
uint256 sqrtPriceX96 = /* from pool */;
uint256 price = (sqrtPriceX96 * sqrtPriceX96) >> 192; // Divide by 2^192
```

### 4. FHE Data Types

| Type | Description | Use Case |
|------|-------------|----------|
| `euint32` | Encrypted 32-bit unsigned integer | IL threshold (0-4,294,967,295 bp) |
| `euint256` | Encrypted 256-bit unsigned integer | Price bounds (high precision) |
| `ebool` | Encrypted boolean | Comparison results |

### 5. FHE Operations

```solidity
// Encrypt a value
euint32 encrypted = FHE.asEuint32(500); // 5% in basis points

// Compare encrypted values
ebool isGreater = FHE.gt(encryptedCurrentIL, encryptedThreshold);

// Enforce condition (reverts if false)
FHE.req(isGreater);
```

---

## 💡 User Experience Flow

### Scenario: Alice Provides Liquidity with IL Protection

**Step 1: Connect Wallet**
```
Alice visits the dApp
Clicks "Connect Wallet"
MetaMask pops up → Approve connection
```

**Step 2: Select Pool & Amounts**
```
Pool: ETH/USDC (0.3% fee tier)
Amount ETH: 10 ETH
Amount USDC: 25,000 USDC
Current price: 1 ETH = 2,500 USDC
```

**Step 3: Set Protection Parameters**
```
Maximum IL Tolerance: [5]%

Explanation shown:
"Your liquidity will automatically exit if impermanent loss 
exceeds 5%. This threshold is encrypted and completely private."

Projected Returns:
• Estimated APR: 18.5%
• Protected against: >5% IL
• Gas cost: ~$3/month
```

**Step 4: Encrypt & Sign**
```
Client-side (in browser):
  1. Convert 5% → 500 basis points
  2. Fhenix.js encrypts: 500 → euint32(encrypted_data)
  3. Package into transaction hookData
  
MetaMask pops up:
  "Sign transaction to deposit liquidity with IL protection"
  Gas estimate: ~150,000 gas (~$5 at 50 gwei)
  
Alice clicks "Confirm"
```

**Step 5: On-Chain Execution**
```
Transaction submitted to blockchain
beforeAddLiquidity() hook executes:
  1. Decode encrypted IL threshold from hookData
  2. Create LPPosition struct:
     - lpAddress: 0xAlice...
     - positionId: 12345
     - entryPrice: 2500 (USDC per ETH)
     - token0Amount: 10 ETH
     - token1Amount: 25,000 USDC
     - encryptedILThreshold: euint32(encrypted_500)
     - depositTime: block.timestamp
     - isActive: true
  3. Store in mapping: positions[12345] = LPPosition{...}
  
Standard Uniswap v4 liquidity addition proceeds
Alice receives LP tokens
```

**Step 6: Monitoring (Automatic)**
```
Every time someone swaps in the ETH/USDC pool:
  
  afterSwap() hook executes:
    1. Get new pool price (e.g., 2,600 USDC per ETH)
    2. For each active LP position (including Alice's):
       a. Calculate current IL:
          priceRatio = 2600 / 2500 = 1.04
          IL = 2*sqrt(1.04)/(1+1.04) - 1 = -0.0098 = 0.98%
          IL in bp = 98
       
       b. Encrypt current IL:
          encryptedCurrentIL = FHE.asEuint32(98)
       
       c. FHE comparison:
          shouldExit = FHE.gt(encryptedCurrentIL, encryptedILThreshold)
          shouldExit = FHE.gt(Encrypt(98), Encrypt(500))
          shouldExit = Encrypt(False)
       
       d. Conditional execution:
          FHE.req(shouldExit) → Reverts (no-op, threshold not breached)
    
    3. Continue to next position...
```

**Step 7: Threshold Breached (Days Later)**
```
ETH price surges to $3,000
IL now exceeds 5%

afterSwap() hook executes:
  1. Calculate IL:
     priceRatio = 3000 / 2500 = 1.2
     IL = 2*sqrt(1.2)/(1+1.2) - 1 = -0.0528 = 5.28%
     IL in bp = 528
  
  2. FHE comparison:
     shouldExit = FHE.gt(Encrypt(528), Encrypt(500))
     shouldExit = Encrypt(True)
  
  3. Conditional execution:
     FHE.req(shouldExit) → Passes!
  
  4. Automated withdrawal:
     - Call PoolManager.removeLiquidity(positionId: 12345)
     - Calculate token amounts with slippage protection
     - Transfer tokens to Alice's wallet:
       → ~9.13 ETH
       → ~27,390 USDC
     - Mark position inactive: positions[12345].isActive = false
     - Emit event: LiquidityWithdrawn(positionId: 12345)
       (Note: Event does NOT reveal the 5% threshold)

Alice receives notification:
  "Your liquidity has been automatically withdrawn due to 
   IL protection trigger. Check your wallet."
```

---

## 🔒 Privacy & Security Deep Dive

### Why Privacy Matters

**Without FHE (Public Thresholds):**

```
Alice sets IL threshold: 5% (visible on-chain)

MEV Bot observes:
  "Alice will exit at 5% IL"
  
When IL approaches 5%:
  1. MEV bot front-runs Alice's exit
  2. Sells large amount, pushing price further
  3. Alice's exit executes at worse price
  4. MEV bot buys back at lower price
  5. Alice loses more money, MEV bot profits
```

**With FHE (Encrypted Thresholds):**

```
Alice sets IL threshold: Encrypt(5%)

MEV Bot observes:
  "Alice has some threshold, but we don't know what it is"
  
When IL approaches unknown threshold:
  1. MEV bot doesn't know when Alice will exit
  2. Can't front-run effectively
  3. Alice's exit executes at fair price
  4. Privacy preserved, MEV minimized
```

### Security Guarantees

**1. Threshold Privacy**
- ✅ Encrypted client-side (never plaintext on network)
- ✅ Stored encrypted on-chain
- ✅ Compared using FHE (never decrypted)
- ✅ Only LP has decryption key

**2. Comparison Privacy**
- ✅ Comparison result is encrypted (ebool)
- ✅ FHE.req() enforces without revealing result
- ✅ Transaction reverts if false (looks like any other failed tx)
- ✅ No timing attacks (constant-time operations)

**3. Withdrawal Privacy**
- ✅ Event emitted doesn't reveal threshold
- ✅ Observers can't distinguish IL exit from manual exit
- ✅ Statistical analysis can't infer thresholds

### Attack Vectors & Mitigations

| Attack | Description | Mitigation |
|--------|-------------|------------|
| **MEV Sandwich** | Front-run withdrawal with large trade | Slippage protection, private mempool |
| **Timing Analysis** | Infer threshold from withdrawal timing | Random delays, batch processing |
| **Gas Analysis** | Infer threshold from gas usage patterns | Constant gas usage regardless of threshold |
| **Statistical Inference** | Analyze many withdrawals to guess thresholds | FHE prevents any information leakage |
| **Smart Contract Bug** | Exploit vulnerability to drain funds | Multiple audits, formal verification, bug bounty |

---

## 📊 Business Model & Economics

### Revenue Streams

**Option 1: Hook Fee**
- Charge 0.1% of withdrawn liquidity
- Example: Alice withdraws $50,000 → $50 fee
- Pros: Aligns incentives (only charge when protection works)
- Cons: Unpredictable revenue

**Option 2: Subscription**
- Charge $5/month per protected position
- Pros: Predictable recurring revenue
- Cons: May deter small LPs

**Option 3: Performance Fee**
- Charge % of IL prevented
- Example: Alice would have lost $1,000 IL, but only lost $500 → Charge 10% of $500 saved = $50
- Pros: Directly tied to value provided
- Cons: Complex to calculate and explain

### Cost Structure

**Development Costs:**
- Smart contract development: $100k - $200k
- Security audits (3 firms): $150k - $300k
- Frontend development: $50k - $100k
- FHE integration: $50k - $100k
- **Total:** $350k - $700k

**Operational Costs:**
- Infrastructure (RPC nodes, monitoring): $2k/month
- Customer support: $5k/month
- Marketing: $10k/month
- **Total:** $17k/month = $204k/year

**Break-Even Analysis:**

Assuming $5/month subscription:
- Need 3,400 active positions to break even monthly
- At 1,000 positions (6-month target): $5k/month revenue
- At 10,000 positions (12-month target): $50k/month revenue

---

## 🚀 Go-to-Market Strategy

### Target Audience

**Primary:**
- **Retail LPs** ($10k - $100k positions)
  - Pain: Can't monitor 24/7
  - Value prop: "Set it and forget it" protection

**Secondary:**
- **Institutional LPs** ($100k - $1M+ positions)
  - Pain: Need sophisticated risk management
  - Value prop: Privacy-preserving automation

**Tertiary:**
- **DeFi Protocols** (integration partners)
  - Pain: LPs leaving due to IL fears
  - Value prop: Increase TVL with built-in protection

### Marketing Channels

1. **Crypto Twitter**
   - Educational threads on IL
   - Demo videos showing protection in action
   - Partnerships with DeFi influencers

2. **DeFi Communities**
   - Discord/Telegram presence
   - AMAs in Uniswap, Fhenix communities
   - Reddit posts in r/DeFi, r/UniSwap

3. **Content Marketing**
   - Blog: "The Complete Guide to Impermanent Loss"
   - YouTube: "How to Protect Your Uniswap Liquidity"
   - Podcast appearances

4. **Partnerships**
   - Integrate with DeFi dashboards (Zapper, DeBank)
   - Collaborate with wallet providers (MetaMask, Rainbow)
   - Co-marketing with Fhenix

### Launch Strategy

**Phase 1: Testnet Beta (Month 7-8)**
- Invite 100 beta testers
- Collect feedback, iterate
- Bug bounty program ($50k pool)

**Phase 2: Mainnet Soft Launch (Month 9)**
- Deploy to mainnet
- Limit to 1,000 positions initially
- Liquidity mining: Reward early adopters with governance tokens

**Phase 3: Public Launch (Month 10)**
- Remove position limits
- Major marketing push
- Partnerships announced

---

## 🎓 Key Takeaways

### For Non-Technical Stakeholders

**What is this?**
- Insurance for Uniswap liquidity providers against impermanent loss
- Uses cutting-edge encryption to keep your risk settings private
- Automatically withdraws your liquidity when your loss limit is hit

**Why does it matter?**
- LPs lose billions to impermanent loss annually
- Current solutions require 24/7 monitoring or reveal your strategy
- This provides automated, private protection

**What's the business opportunity?**
- Large addressable market (millions of LPs)
- Recurring revenue model
- First-mover advantage in FHE-powered DeFi

### For Technical Stakeholders

**Technical Innovation:**
- First production use of FHE in DeFi risk management
- Novel application of Uniswap v4 hooks
- Gas-optimized encrypted computation

**Technical Challenges:**
- FHE performance at scale (100+ positions per pool)
- Gas cost optimization (<50k gas per position check)
- Integration with Uniswap v4 (still in development)

**Technical Risks:**
- Fhenix protocol maturity
- Uniswap v4 API stability
- Smart contract security

### For Investors

**Market Opportunity:**
- $50B+ TVL in Uniswap alone
- 10% penetration = $5B addressable market
- $5/month/position = $250M annual revenue potential

**Competitive Advantages:**
- Privacy through FHE (hard to replicate)
- First-mover in Uniswap v4 hooks
- Technical moat (requires deep expertise)

**Investment Risks:**
- Regulatory uncertainty around DeFi
- Dependency on Uniswap v4 and Fhenix
- Smart contract security risks

---

## 📚 Further Reading

### Impermanent Loss
- [Uniswap V2 Whitepaper](https://uniswap.org/whitepaper.pdf)
- [Understanding Impermanent Loss (Binance Academy)](https://academy.binance.com/en/articles/impermanent-loss-explained)
- [IL Calculator Tool](https://dailydefi.org/tools/impermanent-loss-calculator/)

### Fully Homomorphic Encryption
- [Fhenix Documentation](https://docs.fhenix.io/)
- [FHE Explained (Vitalik Buterin)](https://vitalik.ca/general/2020/07/20/homomorphic.html)
- [Practical FHE (Microsoft Research)](https://www.microsoft.com/en-us/research/project/homomorphic-encryption/)

### Uniswap v4
- [Uniswap v4 Announcement](https://blog.uniswap.org/uniswap-v4)
- [Hooks Documentation](https://docs.uniswap.org/contracts/v4/overview)
- [v4 Core Repository](https://github.com/Uniswap/v4-core)

### DeFi Risk Management
- [DeFi Risk Assessment Framework](https://defisafety.com/)
- [MEV and Frontrunning](https://ethereum.org/en/developers/docs/mev/)
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)

---

## ❓ FAQ

**Q: What happens if the FHE computation fails?**
A: The hook has fallback logic. If FHE fails, it logs an error and skips that position check. The LP can manually withdraw anytime.

**Q: Can I change my IL threshold after depositing?**
A: Not in v1. You'd need to withdraw and re-deposit with new parameters. v2 may support threshold updates.

**Q: What if Uniswap v4 changes their hook API?**
A: We maintain a compatibility layer and will upgrade contracts if needed. LPs would need to migrate positions.

**Q: How do I know my threshold is really private?**
A: The smart contracts will be open-source and audited. You can verify that FHE is used correctly and thresholds are never decrypted on-chain.

**Q: What's the gas cost per swap?**
A: The hook adds ~50k gas per protected position. With 10 positions in a pool, that's ~500k gas total. At 50 gwei and $2,500 ETH, that's ~$62.50 per swap. This cost is distributed among all swappers, not LPs.

**Q: Can I use this on other DEXs besides Uniswap?**
A: Not initially. The hook is specific to Uniswap v4. Future versions may support other AMMs.

**Q: What if I want to withdraw before hitting my threshold?**
A: You can manually withdraw anytime using standard Uniswap v4 interface. The hook only triggers automatic withdrawal.

**Q: Is my capital at risk?**
A: Yes, as with any DeFi protocol. Risks include smart contract bugs, FHE failures, and market volatility. Always DYOR and only invest what you can afford to lose.

---

**Last Updated:** November 26, 2025  
**Document Version:** 1.0
