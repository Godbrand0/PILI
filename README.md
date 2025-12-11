# PILI: FHE-Protected Impermanent Loss Insurance Hook for Uniswap v4

## Overview

PILI (Privacy-preserving Impermanent Loss Insurance) is a Uniswap v4 hook designed to provide liquidity providers (LPs) with automated, privacy-preserving protection against impermanent loss (IL) and adverse price movements. By leveraging Fully Homomorphic Encryption (FHE), PILI allows LPs to set encrypted risk parameters that trigger automatic position management without revealing strategies to market participants, MEV bots, or competitors.

This repository serves as the central hub for PILI's product requirements, technical specifications, and visual guides. It outlines two interconnected Uniswap v4 hooks:

1. **IL Protection Hook**: Monitors IL and withdraws liquidity when encrypted thresholds are breached.
2. **Price Bounds Hook**: Enforces upper/lower price limits with automatic exits.

The project addresses key DeFi pain points like IL exposure, manual monitoring, and strategy exploitation, aiming to increase TVL and LP participation through secure, automated risk management.

## Problem Statement

Liquidity providers in Uniswap pools face significant risks:

- **Impermanent Loss (IL)**: Capital erosion due to price volatility.
- **Manual Oversight**: Constant monitoring required, which is inefficient.
- **Privacy Risks**: Public risk parameters enable front-running and MEV extraction.
- **Lack of Granularity**: Limited tools for sophisticated, private risk strategies.

These issues deter LPs, reducing overall DeFi liquidity. PILI solves this with FHE-enabled privacy and automation.

## Solution

PILI introduces two hooks integrated into Uniswap v4's architecture:

- **IL Protection**: Calculates IL post-swap using the formula `2 * sqrt(priceRatio) / (1 + priceRatio) - 1`, compares it homomorphically to an encrypted threshold, and withdraws liquidity if breached.
- **Price Bounds**: Monitors pool price against encrypted upper/lower bounds and triggers exits on violations.

Key benefits:

- **Privacy**: Parameters encrypted client-side; computations occur on encrypted data.
- **Automation**: Triggers execute in the `afterSwap` hook without user intervention.
- **Efficiency**: Gas-optimized for low costs (<$5/month per position).
- **Combinability**: LPs can use both hooks simultaneously for layered protection.

## Features

### Core Features

- **Encrypted IL Thresholds**: Set private max IL tolerance (e.g., 5%) with 0.01% granularity.
- **Real-Time IL Monitoring**: Post-swap calculations compare current position value vs. HODL value.
- **Automated Withdrawals**: Remove liquidity and return tokens to LP on threshold breach, with slippage protection (default 0.5%).
- **Price Bound Enforcement**: Set encrypted upper/lower price limits; exit on breaches.
- **Dual Protection**: Combine IL and price hooks for comprehensive risk management.
- **Event Emissions**: Log withdrawals without revealing triggers.

### Non-Functional Highlights

- **Performance**: <100ms IL calculations; <50,000 gas increase per swap.
- **Security**: Resistant to MEV, front-running, and timing attacks; zero plaintext storage.
- **Privacy**: No decryption on-chain; statistical inference mitigation.
- **Scalability**: Supports 10,000+ positions per pool.
- **Reliability**: 99.9% uptime; no missed breaches.

## Technical Architecture

PILI builds on Uniswap v4's hook system and FHE for private computations.

### System Diagram

```
┌────────────────────┐
│ LP Frontend        │
│ - Input Parameters │
│ - Client-side FHE  │
│   Encryption       │
└──────────┬─────────┘
           │
           ▼
┌────────────────────┐
│ Uniswap v4         │
│ PoolManager        │
│                    │
│ ┌────────────────┐ │
│ │ IL/Price Hooks│ │
│ │ - beforeAddLiq │ │
│ │ - afterSwap    │ │
│ └────────────────┘ │
│                    │
│ ┌────────────────┐ │
│ │ Position       │ │
│ │ Storage        │ │
│ └────────────────┘ │
└──────────┬─────────┘
           │
           ▼
┌────────────────────┐
│ FHE Protocol Layer │
│ - Comparisons     │
│ - Conditional Exec│
└────────────────────┘
```

### Smart Contracts

- **ILProtectionHook.sol**: Handles IL calculations, FHE comparisons, and withdrawals.
- **PriceBoundsHook.sol**: Manages price checks and bounds enforcement.
- **Data Structures**:

  ```solidity
  struct LPPosition {
      address lpAddress;
      uint256 positionId;
      uint256 entryPrice;
      uint256 token0Amount;
      uint256 token1Amount;
      euint32 encryptedILThreshold;
      uint256 depositTime;
      bool isActive;
  }

  struct PriceBoundsPosition {
      address lpAddress;
      uint256 positionId;
      euint256 encryptedUpperBound;
      euint256 encryptedLowerBound;
      uint256 depositTime;
      bool isActive;
  }
  ```

### FHE Integration

- Client-side encryption using Fhenix.js.
- On-chain operations: `FHE.asEuint32()`, `FHE.gt()`, `FHE.req()` for comparisons and enforcement.

### Gas Estimates

- Add Liquidity: ~150,000 gas
- AfterSwap Check: ~50,000 gas per position
- Withdrawal: ~100,000 gas

## Partner Integrations

No partner integrations.

## Installation and Setup

As this repository is documentation-only, no installation is required. For development:

1. Clone the repo: `git clone https://github.com/Godbrand0/PILI.git`
2. Review `docs/PRD.md` for specifications.
3. Implement contracts using Foundry or Hardhat (planned dependencies: Uniswap v4 libraries, Fhenix FHE).

Future code will include:

- `forge install` for dependencies.
- Testnet deployment scripts.

## Usage

### LP Onboarding

1. Connect wallet to frontend.
2. Select pool and deposit amounts.
3. Set IL threshold/price bounds (encrypted client-side).
4. Sign transaction to add liquidity via hook.

### Monitoring

- Dashboard shows current IL, price, and status (decrypted client-side).
- Automatic triggers handle exits.

### Example UI

```
┌────────────────────────────────────────────────────────┐
│ 🛡️ Deposit with IL Protection                         │
├────────────────────────────────────────────────────────┤
│ Token Pair: ETH/USDC                                   │
│ Amount ETH: [10.0]   Amount USDC: [25,000]             │
│ Max IL Tolerance: [5]%                                 │
│ [Deposit & Protect]                                    │
└────────────────────────────────────────────────────────┘
```

## Risks and Mitigations

| Risk                | Impact   | Probability | Mitigation                 |
| ------------------- | -------- | ----------- | -------------------------- |
| FHE Performance     | High     | Medium      | Benchmarking, optimization |
| Smart Contract Bugs | Critical | Low         | Audits, bug bounties       |
| Low Adoption        | High     | Medium      | Marketing, incentives      |

## Contributing

Contributions welcome! See `CONTRIBUTING.md` (forthcoming) for guidelines. Focus on documentation updates, diagrams, or implementation proposals.

## License

MIT License. See for details.

## References

- [Uniswap v4 Docs](https://docs.uniswap.org/contracts/v4/overview)
- [Fhenix Docs](https://docs.fhenix.io/)
- Repository Docs: `docs/PRD.md`, `docs/PRD_ANALYSIS.md`, `docs/VISUAL_GUIDE.md`

For questions, open an issue or contact the team.
