## 3. Hook #2: Price Bounds Hook

### 3.1 Feature Description

Allows LPs to set encrypted upper and lower price bounds for their positions. Automatically withdraws liquidity when the pool price moves outside these bounds.

### 3.2 User Stories

**As an LP, I want to:**

- Set private price boundaries for my position
- Automatically exit when price moves outside my comfort zone
- Combine price protection with IL protection
- Avoid revealing my price targets to other traders

**As a protocol, I want to:**

- Offer flexible risk management options
- Support multiple protection strategies simultaneously
- Maintain privacy across all protection mechanisms

### 3.3 Functional Requirements

#### 3.3.1 Price Bounds Setup

**FR-PB-001: Bounds Input Interface**

- **Priority:** P0 (Critical)
- **Description:** Frontend for setting upper/lower price bounds
- **Acceptance Criteria:**
  - User inputs upper and lower price limits
  - Validation ensures upper > lower
  - Current price displayed for reference
  - Preview shows trigger conditions
  - Support for percentage-based bounds (e.g., ±10% from current)

**FR-PB-002: FHE Encryption of Bounds**

- **Priority:** P0 (Critical)
- **Description:** Encrypt price bounds client-side
- **Acceptance Criteria:**
  - Both bounds encrypted as euint256
  - Encryption before blockchain transmission
  - Support for high-precision price values
  - Error handling for encryption failures

**FR-PB-003: Bounds Storage**

- **Priority:** P0 (Critical)
- **Description:** Store encrypted bounds on-chain
- **Acceptance Criteria:**
  - PriceBoundsPosition struct stores all data
  - Encrypted upper/lower bounds stored
  - Link to corresponding IL protection position (if exists)
  - Gas-optimized storage

#### 3.3.2 Price Monitoring

**FR-PB-004: Price Comparison**

- **Priority:** P0 (Critical)
- **Description:** Check if current price exceeds bounds
- **Acceptance Criteria:**
  - Retrieves current pool price after swaps
  - FHE comparison: `currentPrice > upperBound OR currentPrice < lowerBound`
  - Returns encrypted boolean result
  - No decryption of bounds or comparison result

**FR-PB-005: Automated Exit**

- **Priority:** P0 (Critical)
- **Description:** Withdraw liquidity when bounds breached
- **Acceptance Criteria:**
  - Triggers withdrawal on bound breach
  - Coordinates with IL protection if both active
  - Returns tokens to LP address
  - Emits event without revealing bounds

#### 3.3.3 Hook Integration

**FR-PB-006: afterSwap Hook**

- **Priority:** P0 (Critical)
- **Description:** Monitor price bounds after swaps
- **Acceptance Criteria:**
  - Implements afterSwap() hook function
  - Checks all active price-bounded positions
  - Executes withdrawals for breached positions
  - Gas-efficient implementation

**FR-PB-007: beforeAddLiquidity Hook**

- **Priority:** P0 (Critical)
- **Description:** Register price bounds for new positions
- **Acceptance Criteria:**
  - Decodes encrypted bounds from hookData
  - Creates PriceBoundsPosition struct
  - Links to IL protection if applicable
  - Validates bounds (upper > lower)

### 3.4 Combined Protection Strategy

**FR-COMBINED-001: Dual Protection**

- **Priority:** P1 (High)
- **Description:** Support simultaneous IL and price protection
- **Acceptance Criteria:**
  - LPs can enable both hooks on same position
  - Withdrawal triggers on first breach (IL or price)
  - Coordinated cleanup of both position records
  - Single withdrawal transaction

---

## 4. Technical Specifications

### 4.1 Smart Contract Architecture

#### 4.1.1 Core Contracts

**ILProtectionHook.sol**
- Inherits from Uniswap v4 BaseHook
- Implements beforeAddLiquidity and afterSwap
- Manages LPPosition storage
- Handles FHE operations for IL comparison

**PriceBoundsHook.sol**
- Inherits from Uniswap v4 BaseHook
- Implements beforeAddLiquidity and afterSwap
- Manages PriceBoundsPosition storage
- Handles FHE operations for price comparison

**FHELibrary.sol**
- Wrapper for Fhenix FHE operations
- Utility functions for encryption/comparison
- Gas optimization helpers

#### 4.1.2 Data Structures

```solidity
struct LPPosition {
    address lpAddress;
    uint256 positionId;
    uint256 entryPrice;        // Price when LP deposited
    uint256 token0Amount;      // Initial token0 amount
    uint256 token1Amount;      // Initial token1 amount
    euint32 encryptedILThreshold;  // Encrypted IL threshold (basis points)
    uint256 depositTime;
    bool isActive;
}

struct PriceBoundsPosition {
    address lpAddress;
    uint256 positionId;
    euint256 encryptedUpperBound;  // Encrypted upper price limit
    euint256 encryptedLowerBound;  // Encrypted lower price limit
    uint256 depositTime;
    bool isActive;
}
```

### 4.2 FHE Integration

#### 4.2.1 Fhenix Protocol

- **Network:** Fhenix testnet/mainnet
- **FHE Library:** Fhenix.js for client-side encryption
- **Supported Types:** euint32, euint256, ebool
- **Operations:** FHE.gt(), FHE.lt(), FHE.asEuint32(), FHE.req()

#### 4.2.2 Encryption Flow

1. **Client-side:** LP inputs threshold → Fhenix.js encrypts → euint32
2. **Transaction:** Encrypted value sent in hookData
3. **On-chain:** Hook stores encrypted value
4. **Comparison:** Current IL encrypted → FHE.gt() comparison → ebool result
5. **Execution:** FHE.req(ebool) enforces condition

### 4.3 Gas Optimization

**Strategies:**

- Batch position checks in single loop
- Early exit for inactive positions
- Packed storage for position metadata
- Lazy deletion (mark inactive vs. delete)
- Efficient FHE operation ordering

**Gas Estimates:**

- Add liquidity with protection: ~150,000 gas
- afterSwap check (per position): ~50,000 gas
- Withdrawal execution: ~100,000 gas

### 4.4 Security Considerations

#### 4.4.1 Attack Vectors

**MEV Attacks:**
- **Risk:** Sandwich attacks around withdrawals
- **Mitigation:** Slippage protection, private mempool options

**Front-running:**
- **Risk:** Observers predict exits based on price movements
- **Mitigation:** FHE ensures thresholds remain private

**Timing Attacks:**
- **Risk:** Inferring thresholds from withdrawal timing
- **Mitigation:** Random delays, batch processing

#### 4.4.2 Audit Requirements

- Full smart contract security audit
- FHE implementation review
- Economic attack vector analysis
- Gas optimization verification

---

## 5. User Experience

### 5.1 Onboarding Flow

1. **Connect Wallet** → LP connects Web3 wallet
2. **Select Pool** → Choose Uniswap v4 pool (e.g., ETH/USDC)
3. **Input Amounts** → Specify token amounts to deposit
4. **Set Protection** → Configure IL threshold and/or price bounds
5. **Encrypt Parameters** → Client-side FHE encryption
6. **Review & Sign** → Preview protection settings, sign transaction
7. **Confirmation** → Position created with encrypted protection

### 5.2 Monitoring Dashboard

**Features:**

- Current IL percentage (decrypted client-side)
- Current pool price
- Position value vs. HODL value
- Time since deposit
- Estimated APR
- Protection status (active/triggered)

**Privacy:**

- Thresholds never displayed on public dashboards
- Only LP can decrypt their own parameters
- No public leaderboard or position rankings

### 5.3 Withdrawal Experience

**Automatic Withdrawal:**

1. Swap occurs in pool
2. Hook calculates IL/checks price
3. FHE comparison triggers withdrawal
4. Tokens returned to LP wallet
5. Notification sent to LP (email/push)

**Manual Withdrawal:**

- LP can withdraw anytime before threshold breach
- Standard Uniswap v4 withdrawal process
- Position marked inactive

---

## 6. Development Roadmap

### Phase 1: Foundation (Months 1-2)

- [ ] Smart contract architecture design
- [ ] FHE integration proof-of-concept
- [ ] IL calculation engine implementation
- [ ] Basic hook structure (beforeAddLiquidity, afterSwap)
- [ ] Local testing environment setup

### Phase 2: Core Development (Months 3-4)

- [ ] Complete ILProtectionHook implementation
- [ ] Complete PriceBoundsHook implementation
- [ ] FHE encryption/comparison logic
- [ ] Gas optimization pass
- [ ] Unit test suite (>90% coverage)

### Phase 3: Frontend & Integration (Months 5-6)

- [ ] React frontend for LP interface
- [ ] Fhenix.js client-side encryption
- [ ] Wallet integration (MetaMask, WalletConnect)
- [ ] Monitoring dashboard
- [ ] Notification system

### Phase 4: Testing & Audit (Months 7-8)

- [ ] Testnet deployment (Sepolia/Goerli)
- [ ] Public beta testing
- [ ] Security audit (2-3 firms)
- [ ] Bug bounty program
- [ ] Performance optimization

### Phase 5: Mainnet Launch (Month 9)

- [ ] Mainnet deployment
- [ ] Liquidity mining incentives
- [ ] Marketing campaign
- [ ] Documentation & tutorials
- [ ] Community support channels

---

## 7. Success Criteria

### 7.1 Technical Success

- ✅ >99% uptime for hook monitoring
- ✅ <0.01% error rate in IL calculations
- ✅ Zero privacy breaches
- ✅ Gas costs within budget (<$5/month per position)
- ✅ Passes all security audits

### 7.2 Product Success

- ✅ 1,000+ protected LP positions
- ✅ $10M+ TVL under protection
- ✅ 15% average IL reduction
- ✅ 70%+ user retention after 3 months
- ✅ Positive user feedback (>4.5/5 rating)

### 7.3 Business Success

- ✅ Sustainable revenue model (hook fees)
- ✅ Partnership with major DeFi protocols
- ✅ Media coverage in crypto publications
- ✅ Community growth (Discord/Telegram)

---

## 8. Risks & Mitigations

### 8.1 Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| FHE performance issues | High | Medium | Extensive benchmarking, gas optimization |
| Smart contract bugs | Critical | Low | Multiple audits, bug bounty, formal verification |
| Uniswap v4 API changes | Medium | Low | Monitor v4 development, maintain compatibility layer |
| Gas cost exceeds budget | Medium | Medium | Optimize storage, batch operations, L2 deployment |

### 8.2 Market Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Low LP adoption | High | Medium | Marketing, liquidity mining, partnerships |
| Competitor launches first | Medium | Medium | Accelerate development, focus on UX differentiation |
| Regulatory concerns | High | Low | Legal review, compliance framework |
| Market downturn | Medium | Medium | Focus on value proposition, reduce costs |

### 8.3 Operational Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Team capacity constraints | Medium | Medium | Hire additional developers, outsource non-core tasks |
| Dependency on Fhenix | High | Low | Maintain relationship, explore backup FHE solutions |
| Support burden | Medium | High | Comprehensive docs, community moderators, chatbot |

---

## 9. Open Questions

1. **FHE Performance:** Can FHE operations complete within acceptable gas limits for 100+ positions?
2. **Uniswap v4 Timeline:** When will Uniswap v4 launch on mainnet?
3. **Fhenix Maturity:** Is Fhenix production-ready for mainnet deployment?
4. **Fee Structure:** What hook fee (if any) should we charge LPs?
5. **L2 Strategy:** Should we prioritize L2 deployment (Arbitrum, Optimism) for lower gas costs?
6. **Insurance Fund:** Should we create an insurance fund for edge cases where hook fails?
7. **Governance:** How should protocol parameters (e.g., max positions per pool) be governed?

---

## 10. Appendix

### 10.1 Glossary

- **IL (Impermanent Loss):** Loss incurred by LPs due to price divergence between deposited tokens
- **FHE (Fully Homomorphic Encryption):** Encryption allowing computation on encrypted data
- **Hook:** Uniswap v4 plugin that executes custom logic during pool operations
- **euint32/euint256:** Encrypted unsigned integers (32-bit/256-bit)
- **ebool:** Encrypted boolean
- **Basis Points:** 1/100th of a percent (500 bp = 5%)
- **sqrtPriceX96:** Uniswap v4's price representation (sqrt(price) * 2^96)

### 10.2 References

- [Uniswap v4 Documentation](https://docs.uniswap.org/contracts/v4/overview)
- [Fhenix Documentation](https://docs.fhenix.io/)
- [Impermanent Loss Explained](https://uniswap.org/docs/v2/concepts/advanced-topics/understanding-returns/)
- [FHE in DeFi Research Paper](https://eprint.iacr.org/2023/xxx)

### 10.3 Contact Information

- **Product Lead:** [Name] - [email]
- **Tech Lead:** [Name] - [email]
- **Security Lead:** [Name] - [email]
- **Community Manager:** [Name] - [email]

---

**Document Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-26 | Product Team | Initial draft |

