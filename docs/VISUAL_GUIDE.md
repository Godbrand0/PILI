# Visual Guide: FHE-Protected IL Insurance Hook
## Quick Reference & Diagrams

---

## 🎯 One-Minute Summary

**What:** Automated protection for Uniswap liquidity providers against impermanent loss  
**How:** Smart contracts that monitor your position and auto-exit when losses exceed your private threshold  
**Why:** Privacy-preserving (using FHE encryption) so MEV bots can't front-run your exits  

---

## 📊 System Architecture Diagram

```mermaid
graph TB
    subgraph "Client Side (Browser/Wallet)"
        A[LP User Interface] --> B[Input IL Threshold: 5%]
        B --> C[Fhenix.js Encryption]
        C --> D[euint32: Encrypt 500 bp]
    end
    
    subgraph "Blockchain (Uniswap v4)"
        D --> E[beforeAddLiquidity Hook]
        E --> F[Store LPPosition]
        F --> G[Position Storage]
        
        H[Trader Swaps] --> I[afterSwap Hook]
        I --> J[Calculate Current IL]
        J --> K[Encrypt Current IL]
        K --> L[FHE Comparison]
        L --> M{Threshold Breached?}
        M -->|Yes| N[Withdraw Liquidity]
        M -->|No| O[Continue Monitoring]
        
        G -.->|Read Position Data| J
    end
    
    subgraph "Fhenix FHE Layer"
        L --> P[FHE.gt Operation]
        P --> Q[Return ebool]
    end
    
    N --> R[Return Tokens to LP]
    
    style A fill:#e1f5ff
    style D fill:#ffe1e1
    style F fill:#e1ffe1
    style M fill:#fff4e1
    style N fill:#ffe1f5
    style P fill:#f5e1ff
```

---

## 🔄 User Journey Flow

```mermaid
sequenceDiagram
    participant LP as Liquidity Provider
    participant UI as Frontend dApp
    participant FHE as Fhenix.js
    participant Hook as IL Protection Hook
    participant Pool as Uniswap v4 Pool
    participant Trader as Other Traders
    
    LP->>UI: 1. Connect wallet & select pool
    LP->>UI: 2. Input amounts & IL threshold (5%)
    UI->>FHE: 3. Encrypt threshold client-side
    FHE-->>UI: 4. Return euint32(encrypted)
    UI->>Hook: 5. Submit transaction with encrypted data
    Hook->>Hook: 6. beforeAddLiquidity() stores position
    Hook-->>LP: 7. Position created, LP tokens issued
    
    Note over LP,Trader: Time passes, trading occurs...
    
    Trader->>Pool: 8. Execute swap
    Pool->>Hook: 9. Trigger afterSwap()
    Hook->>Hook: 10. Calculate current IL
    Hook->>Hook: 11. Encrypt current IL
    Hook->>Hook: 12. FHE compare: currentIL > threshold?
    
    alt IL below threshold
        Hook-->>Pool: 13a. No action, continue
    else IL exceeds threshold
        Hook->>Pool: 13b. Remove liquidity
        Pool-->>LP: 14. Return tokens to wallet
        Hook-->>LP: 15. Send notification
    end
```

---

## 💡 Impermanent Loss Visualization

```mermaid
graph LR
    subgraph "Scenario: ETH Price Doubles"
        A[Initial State] --> B[HODL Strategy]
        A --> C[LP Strategy]
        
        B --> D[Value: $15,000]
        C --> E[Value: $14,160]
        
        E -.->|Impermanent Loss| F[$840 loss vs HODL]
    end
    
    subgraph "Initial Deposit"
        A1[5 ETH @ $1,000 = $5,000]
        A2[5,000 USDC = $5,000]
        A1 --> A
        A2 --> A
    end
    
    subgraph "After Price Doubles"
        B1[5 ETH @ $2,000 = $10,000]
        B2[5,000 USDC = $5,000]
        B1 --> D
        B2 --> D
        
        C1[3.54 ETH @ $2,000 = $7,080]
        C2[7,080 USDC = $7,080]
        C1 --> E
        C2 --> E
    end
    
    style F fill:#ffcccc
    style D fill:#ccffcc
    style E fill:#ffffcc
```

---

## 🔐 Privacy Comparison

```mermaid
graph TB
    subgraph "Without FHE (Public Thresholds)"
        A1[LP sets threshold: 5%] --> B1[Stored on-chain in plaintext]
        B1 --> C1[MEV bot reads: Alice exits at 5%]
        C1 --> D1[IL approaches 5%]
        D1 --> E1[MEV bot front-runs exit]
        E1 --> F1[Alice loses more money]
    end
    
    subgraph "With FHE (Encrypted Thresholds)"
        A2[LP sets threshold: 5%] --> B2[Encrypted client-side]
        B2 --> C2[Stored as euint32 encrypted]
        C2 --> D2[MEV bot sees: ???]
        D2 --> E2[IL exceeds unknown threshold]
        E2 --> F2[Alice exits at fair price]
    end
    
    style F1 fill:#ffcccc
    style F2 fill:#ccffcc
    style C2 fill:#e1e1ff
```

---

## 📈 IL Protection in Action

### Example Timeline

```mermaid
gantt
    title LP Position Lifecycle with IL Protection
    dateFormat YYYY-MM-DD
    section Position
    Deposit Liquidity (ETH=$2,000)           :a1, 2025-01-01, 1d
    Active Monitoring (IL < 5%)              :a2, 2025-01-02, 14d
    section Market Events
    ETH rises to $2,200 (IL: 1.2%)          :milestone, 2025-01-05, 0d
    ETH rises to $2,400 (IL: 2.8%)          :milestone, 2025-01-10, 0d
    ETH rises to $2,600 (IL: 5.3%)          :crit, 2025-01-15, 0d
    section Hook Actions
    Threshold Breached - Auto Withdraw       :crit, 2025-01-15, 1d
    Tokens Returned to Wallet                :milestone, 2025-01-16, 0d
```

---

## 🏗️ Smart Contract Structure

```mermaid
classDiagram
    class ILProtectionHook {
        +mapping positions
        +beforeAddLiquidity()
        +afterSwap()
        -calculateIL()
        -compareThreshold()
        -withdrawLiquidity()
    }
    
    class LPPosition {
        +address lpAddress
        +uint256 positionId
        +uint256 entryPrice
        +uint256 token0Amount
        +uint256 token1Amount
        +euint32 encryptedILThreshold
        +uint256 depositTime
        +bool isActive
    }
    
    class PriceBoundsHook {
        +mapping boundsPositions
        +beforeAddLiquidity()
        +afterSwap()
        -checkPriceBounds()
        -withdrawLiquidity()
    }
    
    class PriceBoundsPosition {
        +address lpAddress
        +uint256 positionId
        +euint256 encryptedUpperBound
        +euint256 encryptedLowerBound
        +uint256 depositTime
        +bool isActive
    }
    
    class FHELibrary {
        +encrypt()
        +compare()
        +enforceCondition()
    }
    
    ILProtectionHook --> LPPosition : stores
    PriceBoundsHook --> PriceBoundsPosition : stores
    ILProtectionHook --> FHELibrary : uses
    PriceBoundsHook --> FHELibrary : uses
```

---

## 🎯 Feature Comparison Matrix

| Feature | Traditional LP | Stop-Loss Bot | **FHE Hook** |
|---------|---------------|---------------|--------------|
| **Automated Protection** | ❌ Manual only | ✅ Yes | ✅ Yes |
| **24/7 Monitoring** | ❌ Self-monitor | ✅ Yes | ✅ Yes |
| **Privacy** | N/A | ❌ Public params | ✅ Encrypted |
| **MEV Resistance** | N/A | ❌ Vulnerable | ✅ Protected |
| **Gas Efficiency** | ✅ No overhead | ⚠️ Moderate | ✅ Optimized |
| **Trustless** | ✅ Yes | ❌ Centralized | ✅ Yes |
| **Granular Control** | ❌ Limited | ⚠️ Basic | ✅ Advanced |
| **Setup Complexity** | ✅ Simple | ⚠️ Moderate | ✅ Simple UI |

---

## 💰 Economic Model

```mermaid
graph TD
    subgraph "Revenue Streams"
        A[Hook Fees] --> D[Protocol Revenue]
        B[Subscriptions] --> D
        C[Performance Fees] --> D
    end
    
    subgraph "Cost Structure"
        D --> E[Development]
        D --> F[Audits]
        D --> G[Operations]
        D --> H[Marketing]
    end
    
    subgraph "Value Distribution"
        D --> I[Treasury]
        I --> J[Governance Token Holders]
        I --> K[Team]
        I --> L[Development Fund]
    end
    
    style D fill:#ccffcc
```

---

## 🚦 Risk Matrix

```mermaid
quadrantChart
    title Risk Assessment Matrix
    x-axis Low Impact --> High Impact
    y-axis Low Probability --> High Probability
    quadrant-1 Monitor Closely
    quadrant-2 Immediate Action
    quadrant-3 Low Priority
    quadrant-4 Mitigation Plan
    
    FHE Performance Issues: [0.7, 0.5]
    Smart Contract Bugs: [0.9, 0.2]
    Uniswap v4 Changes: [0.5, 0.3]
    Gas Cost Overruns: [0.6, 0.5]
    Low Adoption: [0.7, 0.4]
    Regulatory Issues: [0.8, 0.2]
    MEV Attacks: [0.6, 0.3]
    Fhenix Dependency: [0.8, 0.2]
```

---

## 📊 Success Metrics Dashboard

```mermaid
graph LR
    subgraph "Primary KPIs"
        A[Active Positions] --> A1[Target: 1,000+]
        B[TVL Protected] --> B1[Target: $10M+]
        C[IL Prevented] --> C1[Target: 15% avg]
        D[Execution Accuracy] --> D1[Target: >99%]
    end
    
    subgraph "Secondary KPIs"
        E[Gas Cost] --> E1[Target: <$5/month]
        F[User Retention] --> F1[Target: >70%]
        G[Privacy Breaches] --> G1[Target: 0]
        H[Time Saved] --> H1[Target: >95%]
    end
    
    style A1 fill:#ccffcc
    style B1 fill:#ccffcc
    style C1 fill:#ccffcc
    style D1 fill:#ccffcc
```

---

## 🛠️ Technology Stack

```mermaid
graph TB
    subgraph "Frontend Layer"
        A[React/Next.js] --> B[Web3 Integration]
        B --> C[MetaMask/WalletConnect]
        B --> D[Fhenix.js SDK]
    end
    
    subgraph "Smart Contract Layer"
        E[Uniswap v4 Hooks] --> F[ILProtectionHook.sol]
        E --> G[PriceBoundsHook.sol]
        F --> H[FHELibrary.sol]
        G --> H
    end
    
    subgraph "Blockchain Layer"
        I[Ethereum Mainnet] --> J[Uniswap v4 PoolManager]
        K[Fhenix Network] --> L[FHE Computation]
    end
    
    subgraph "Infrastructure"
        M[RPC Nodes] --> N[Monitoring Service]
        N --> O[Notification System]
        O --> P[Email/Push Alerts]
    end
    
    D --> H
    J --> F
    J --> G
    H --> L
    
    style D fill:#e1f5ff
    style H fill:#ffe1e1
    style L fill:#f5e1ff
```

---

## 📅 Development Roadmap

```mermaid
timeline
    title Project Timeline (9 Months)
    section Phase 1: Foundation
        Month 1-2 : Smart contract design
                  : FHE proof-of-concept
                  : IL calculation engine
    section Phase 2: Core Dev
        Month 3-4 : Hook implementation
                  : FHE integration
                  : Gas optimization
                  : Unit tests
    section Phase 3: Frontend
        Month 5-6 : React UI development
                  : Wallet integration
                  : Monitoring dashboard
                  : Notifications
    section Phase 4: Testing
        Month 7-8 : Testnet deployment
                  : Beta testing
                  : Security audits
                  : Bug bounty
    section Phase 5: Launch
        Month 9   : Mainnet deployment
                  : Marketing campaign
                  : Community support
```

---

## 🎓 Key Concepts Cheat Sheet

### Impermanent Loss Formula
```
IL = 2 × √(priceRatio) / (1 + priceRatio) - 1

Example:
  Entry: ETH = $2,000
  Current: ETH = $2,500
  Ratio: 2500/2000 = 1.25
  IL = 2 × √1.25 / (1 + 1.25) - 1
     = 2 × 1.118 / 2.25 - 1
     = -0.62% (loss)
```

### Basis Points Conversion
```
Percentage → Basis Points
1% = 100 bp
5% = 500 bp
10% = 1,000 bp
0.01% = 1 bp

Basis Points → Percentage
500 bp = 5%
1,000 bp = 10%
```

### FHE Operations
```solidity
// Encrypt value
euint32 encrypted = FHE.asEuint32(500);

// Compare (greater than)
ebool result = FHE.gt(encryptedA, encryptedB);

// Enforce condition
FHE.req(result); // Reverts if false
```

### Uniswap v4 Price Conversion
```solidity
// sqrtPriceX96 → price
uint256 price = (sqrtPriceX96 ** 2) >> 192;

// price → sqrtPriceX96
uint160 sqrtPrice = uint160(sqrt(price) << 96);
```

---

## 🔗 Quick Links

### Documentation
- [Full PRD](./PRD.md)
- [Detailed Analysis](./PRD_ANALYSIS.md)
- [Uniswap v4 Docs](https://docs.uniswap.org/contracts/v4/overview)
- [Fhenix Docs](https://docs.fhenix.io/)

### Tools
- [IL Calculator](https://dailydefi.org/tools/impermanent-loss-calculator/)
- [Uniswap Analytics](https://info.uniswap.org/)
- [Gas Tracker](https://etherscan.io/gastracker)

### Community
- [Discord](#)
- [Telegram](#)
- [Twitter](#)
- [GitHub](#)

---

## ❓ Quick FAQ

**Q: How much does it cost?**  
A: ~$3-5/month in gas fees per protected position

**Q: Is my threshold really private?**  
A: Yes! Encrypted client-side, never decrypted on-chain

**Q: Can I change my threshold?**  
A: Not in v1. Withdraw and re-deposit with new threshold

**Q: What if I want to exit early?**  
A: Manual withdrawal anytime via Uniswap interface

**Q: Which pools are supported?**  
A: All Uniswap v4 pools (after v4 mainnet launch)

**Q: Is this audited?**  
A: Will be audited by 3 firms before mainnet launch

---

**Document Version:** 1.0  
**Last Updated:** November 26, 2025
