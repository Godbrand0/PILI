# PILI Implementation Plan
## Privacy-preserving Impermanent Loss Insurance for Uniswap v4 Hookathon

**Project:** PILI (Privacy-preserving Impermanent Loss Insurance)
**Target:** Uniswap v4 Hookathon in Partnership with FHE
**Team Size:** 3 Developers
**Timeline:** Hackathon Duration (typically 2-4 weeks)
**Status:** Ready for Implementation

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Architecture Overview](#architecture-overview)
4. [Team Structure & Responsibilities](#team-structure--responsibilities)
5. [Developer 1: Smart Contracts & Uniswap v4 Integration](#developer-1-smart-contracts--uniswap-v4-integration)
6. [Developer 2: FHE Integration & Privacy Layer](#developer-2-fhe-integration--privacy-layer)
7. [Developer 3: Frontend & User Experience](#developer-3-frontend--user-experience)
8. [Development Phases](#development-phases)
9. [Integration Points](#integration-points)
10. [Testing Strategy](#testing-strategy)
11. [Deployment Plan](#deployment-plan)
12. [Hackathon Deliverables](#hackathon-deliverables)
13. [Demo Scenario](#demo-scenario)

---

## Project Overview

### What We're Building

A Uniswap v4 hook that automatically protects liquidity providers from impermanent loss using Fully Homomorphic Encryption (FHE) to keep risk parameters private.

### Key Innovation

- **Automated IL Protection:** Monitors IL after every swap, auto-exits when threshold breached
- **Privacy-Preserving:** FHE encryption keeps IL thresholds secret from MEV bots
- **Trustless:** Fully on-chain, no centralized components
- **Gas-Efficient:** Optimized for production use

### Success Criteria for Hackathon

1. Working demo on testnet showing IL calculation and automated exit
2. FHE integration demonstrating private threshold comparison
3. User-friendly frontend for LP onboarding
4. Complete documentation and demo video
5. Open-source codebase ready for judging

---

## Technology Stack

### Smart Contracts
- **Solidity:** ^0.8.20
- **Uniswap v4:** Core, Periphery, Hooks SDK
- **Foundry:** Testing framework
- **OpenZeppelin:** Security utilities

### FHE Layer
- **Fhenix:** FHE blockchain and SDK
- **fhenixjs:** Client-side encryption library
- **Supported Types:** euint32, euint256, ebool

### Frontend
- **Next.js 14:** React framework with App Router
- **TypeScript:** Type safety
- **Wagmi v2:** Ethereum hooks
- **Viem:** Ethereum interactions
- **RainbowKit:** Wallet connection
- **TailwindCSS:** Styling
- **shadcn/ui:** Component library

### Infrastructure
- **Testnet:** Sepolia or Fhenix testnet
- **RPC:** Alchemy/Infura
- **IPFS:** Documentation hosting (optional)
- **Vercel:** Frontend deployment

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend (Next.js)                      │
│  ┌─────────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  LP Dashboard   │  │  FHE Client  │  │ Wallet Conn  │    │
│  └─────────────────┘  └──────────────┘  └──────────────┘    │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Blockchain Layer (Uniswap v4)                  │
│                                                             │
│  ┌────────────────────────────────────────────────────┐     │
│  │          ILProtectionHook.sol                      │     │
│  │                                                    │     │
│  │  ┌──────────────────┐  ┌──────────────────┐        │     │
│  │  │beforeAddLiquidity│  │   afterSwap      │        │     │
│  │  │                  │  │                  │        │     │
│  │  │ - Validate data  │  │ - Get price      │        │     │
│  │  │ - Store position │  │ - Calc IL        │        │     │
│  │  │ - Emit event     │  │ - FHE compare    │        │     │
│  │  │                  │  │ - Withdraw       │        │     │
│  │  └──────────────────┘  └──────────────────┘        │     │
│  │                                                    │     │
│  │  ┌─────────────────────────────────────────┐       │     │
│  │  │      Position Storage (LPPosition)      │       │     │
│  │  │  - lpAddress                            │       │     │
│  │  │  - entryPrice                           │       │     │
│  │  │  - token0Amount, token1Amount           │       │     │
│  │  │  - encryptedILThreshold (euint32)       │       │     │
│  │  │  - isActive                             │       │     │
│  │  └─────────────────────────────────────────┘       │     │
│  └────────────────────────────────────────────────────┘     │
│                                                             │
│  ┌────────────────────────────────────────────────────┐     │
│  │  - calculateIL()                                   │     │
│  │  - getCurrentPrice()                               │     │
│  │  - getPositionValue()                              │     │
│  └────────────────────────────────────────────────────┘     │
│                                                             │
│  ┌────────────────────────────────────────────────────┐     │
│  │         FHEManager.sol (Library)                   │     │
│  │  - encryptValue()                                  │     │
│  │  - compareThresholds()                             │     │
│  │  - enforceCondition()                              │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│            Fhenix FHE Protocol Layer                        │
│  - Homomorphic encryption/decryption                        │
│  - FHE.gt(), FHE.asEuint32(), FHE.req()                     │
│  - Privacy-preserving computation                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Team Structure & Responsibilities

### Developer 1: Smart Contracts & Uniswap v4 Integration
**Focus:** Hook implementation, IL calculation, Uniswap v4 integration

**Primary Responsibilities:**
- Uniswap v4 hook development (beforeAddLiquidity, afterSwap)
- IL calculation engine
- Position management and storage
- Price oracle integration
- Liquidity withdrawal logic
- Smart contract testing with Foundry

**Skills Required:**
- Strong Solidity experience
- Familiarity with Uniswap v3/v4
- Understanding of AMM mechanics
- Testing with Foundry/Hardhat

---

### Developer 2: FHE Integration & Privacy Layer
**Focus:** Fhenix integration, encryption logic, privacy guarantees

**Primary Responsibilities:**
- Fhenix SDK integration (smart contract side)
- FHE comparison logic (euint32 operations)
- Client-side encryption (fhenixjs)
- Privacy testing and validation
- Gas optimization for FHE operations
- Security considerations

**Skills Required:**
- Solidity with FHE knowledge
- Understanding of cryptography basics
- Experience with Fhenix or similar FHE platforms
- Performance optimization

---

### Developer 3: Frontend & User Experience
**Focus:** UI/UX, wallet integration, user flows

**Primary Responsibilities:**
- Next.js application setup
- LP dashboard and position monitoring
- Wallet connection (RainbowKit)
- FHE client-side encryption interface
- Transaction management and status
- Demo and presentation materials

**Skills Required:**
- React/Next.js proficiency
- Web3 integration (wagmi, viem)
- TypeScript
- UI/UX design skills

---

## Developer 1: Smart Contracts & Uniswap v4 Integration

### Phase 1: Project Setup (Days 1-2)

#### Task 1.1: Initialize Foundry Project
```bash
# Create project structure
forge init pili-contracts
cd pili-contracts

# Install dependencies
forge install Uniswap/v4-core
forge install Uniswap/v4-periphery
forge install OpenZeppelin/openzeppelin-contracts
```

**File Structure:**
```
pili-contracts/
├── src/
│   ├── ILProtectionHook.sol
│   ├── libraries/
│   │   ├── ILCalculator.sol
│   │   └── FHEManager.sol
│   └── interfaces/
│       ├── IILProtectionHook.sol
│       └── ILPPosition.sol
├── test/
│   ├── ILProtectionHook.t.sol
│   ├── ILCalculator.t.sol
│   └── mocks/
│       └── MockPoolManager.sol
├── script/
│   ├── Deploy.s.sol
│   └── Setup.s.sol
└── foundry.toml
```

#### Task 1.2: Define Data Structures

**File:** `src/interfaces/ILPPosition.sol`
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Position data for IL-protected liquidity
struct LPPosition {
    address lpAddress;           // LP's wallet address
    uint256 positionId;          // Unique position identifier
    uint256 entryPrice;          // Price when LP deposited (in token1 per token0)
    uint256 token0Amount;        // Initial token0 amount
    uint256 token1Amount;        // Initial token1 amount
    euint32 encryptedILThreshold; // Encrypted IL threshold in basis points (e.g., 500 = 5%)
    uint256 depositTimestamp;    // When position was created
    bool isActive;               // Whether position is still active
}

interface ILPPosition {
    event PositionCreated(
        uint256 indexed positionId,
        address indexed lpAddress,
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 entryPrice
    );

    event PositionWithdrawn(
        uint256 indexed positionId,
        address indexed lpAddress,
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 currentIL
    );

    event ILThresholdBreached(
        uint256 indexed positionId,
        uint256 currentIL
    );
}
```

### Phase 2: IL Calculator Library (Days 2-3)

#### Task 1.3: Implement IL Calculation Logic

**File:** `src/libraries/ILCalculator.sol`
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PoolKey} from "v4-core/types/PoolKey.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {FullMath} from "v4-core/libraries/FullMath.sol";

/// @title ILCalculator
/// @notice Library for calculating impermanent loss
library ILCalculator {
    uint256 constant PRECISION = 1e18;
    uint256 constant BP_DIVISOR = 10000; // Basis points divisor

    /// @notice Calculate impermanent loss as basis points
    /// @param entryPrice Price when LP deposited
    /// @param currentPrice Current pool price
    /// @return ilBasisPoints IL as basis points (500 = 5%)
    function calculateIL(
        uint256 entryPrice,
        uint256 currentPrice
    ) internal pure returns (uint256 ilBasisPoints) {
        require(entryPrice > 0, "Entry price must be > 0");
        require(currentPrice > 0, "Current price must be > 0");

        // Calculate price ratio: currentPrice / entryPrice
        uint256 priceRatio = (currentPrice * PRECISION) / entryPrice;

        // IL formula: 2 * sqrt(priceRatio) / (1 + priceRatio) - 1
        uint256 sqrtRatio = sqrt(priceRatio);
        uint256 numerator = 2 * sqrtRatio;
        uint256 denominator = PRECISION + priceRatio;

        // Result in percentage terms
        uint256 result = (numerator * PRECISION) / denominator;

        // If result < PRECISION, we have IL (negative return)
        if (result < PRECISION) {
            uint256 ilPercentage = PRECISION - result;
            ilBasisPoints = (ilPercentage * BP_DIVISOR) / PRECISION;
        } else {
            // No IL (price returned to entry or gained)
            ilBasisPoints = 0;
        }

        return ilBasisPoints;
    }

    /// @notice Get current pool price from Uniswap v4
    /// @param poolManager The Uniswap v4 pool manager
    /// @param key The pool key
    /// @return price Current price in token1 per token0
    function getCurrentPrice(
        IPoolManager poolManager,
        PoolKey memory key
    ) internal view returns (uint256 price) {
        // Get sqrtPriceX96 from pool
        (uint160 sqrtPriceX96, , , ) = poolManager.getSlot0(key.toId());

        // Convert sqrtPriceX96 to regular price
        // price = (sqrtPriceX96 / 2^96)^2
        price = FullMath.mulDiv(
            uint256(sqrtPriceX96),
            uint256(sqrtPriceX96),
            1 << 192
        );

        return price;
    }

    /// @notice Calculate current position value
    /// @param token0Amount Initial token0 amount
    /// @param token1Amount Initial token1 amount
    /// @param entryPrice Entry price
    /// @param currentPrice Current price
    /// @return hodlValue Value if LP had just held tokens
    /// @return lpValue Current value as LP
    function calculatePositionValue(
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 entryPrice,
        uint256 currentPrice
    ) internal pure returns (uint256 hodlValue, uint256 lpValue) {
        // HODL value: what LP would have if they just held
        hodlValue = (token0Amount * currentPrice) / PRECISION + token1Amount;

        // LP value: current value in AMM (using constant product formula)
        // k = token0 * token1 (constant)
        uint256 k = token0Amount * token1Amount;

        // At current price: token0_new * token1_new = k
        // token1_new / token0_new = currentPrice
        // So: token0_new = sqrt(k / currentPrice)
        //     token1_new = sqrt(k * currentPrice)

        uint256 kScaled = k * PRECISION;
        uint256 token0New = sqrt(kScaled / currentPrice);
        uint256 token1New = sqrt(kScaled * currentPrice) / PRECISION;

        lpValue = (token0New * currentPrice) / PRECISION + token1New;

        return (hodlValue, lpValue);
    }

    /// @notice Square root function (Babylonian method)
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
```

**Testing File:** `test/ILCalculator.t.sol`
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/libraries/ILCalculator.sol";

contract ILCalculatorTest is Test {
    using ILCalculator for *;

    uint256 constant PRECISION = 1e18;

    function testCalculateIL_PriceDoubles() public {
        uint256 entryPrice = 2000 * PRECISION; // $2000
        uint256 currentPrice = 4000 * PRECISION; // $4000

        uint256 ilBp = ILCalculator.calculateIL(entryPrice, currentPrice);

        // When price doubles, IL should be ~5.72%
        assertApprox(ilBp, 572, 10); // ~572 basis points with 10 bp tolerance
    }

    function testCalculateIL_PriceUnchanged() public {
        uint256 entryPrice = 2000 * PRECISION;
        uint256 currentPrice = 2000 * PRECISION;

        uint256 ilBp = ILCalculator.calculateIL(entryPrice, currentPrice);

        // No price change = no IL
        assertEq(ilBp, 0);
    }

    function testCalculateIL_SmallPriceIncrease() public {
        uint256 entryPrice = 2000 * PRECISION;
        uint256 currentPrice = 2100 * PRECISION; // 5% increase

        uint256 ilBp = ILCalculator.calculateIL(entryPrice, currentPrice);

        // Small price change = small IL (~0.06%)
        assertApprox(ilBp, 6, 2);
    }

    function testCalculatePositionValue() public {
        uint256 token0Amount = 10 * PRECISION; // 10 ETH
        uint256 token1Amount = 20000 * PRECISION; // 20,000 USDC
        uint256 entryPrice = 2000 * PRECISION;
        uint256 currentPrice = 4000 * PRECISION;

        (uint256 hodlValue, uint256 lpValue) = ILCalculator.calculatePositionValue(
            token0Amount,
            token1Amount,
            entryPrice,
            currentPrice
        );

        // HODL: 10 ETH * $4000 + $20,000 = $60,000
        assertEq(hodlValue, 60000 * PRECISION);

        // LP value should be less due to IL
        assertLt(lpValue, hodlValue);
    }

    function assertApprox(uint256 a, uint256 b, uint256 tolerance) internal {
        uint256 diff = a > b ? a - b : b - a;
        assertLe(diff, tolerance, "Values not approximately equal");
    }
}
```

### Phase 3: Main Hook Implementation (Days 4-6)

#### Task 1.4: Implement ILProtectionHook

**File:** `src/ILProtectionHook.sol`
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseHook} from "v4-periphery/BaseHook.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";

import {ILCalculator} from "./libraries/ILCalculator.sol";
import {FHEManager} from "./libraries/FHEManager.sol";
import {LPPosition, ILPPosition} from "./interfaces/ILPPosition.sol";

/// @title ILProtectionHook
/// @notice Uniswap v4 hook providing automated IL protection with FHE privacy
contract ILProtectionHook is BaseHook, ILPPosition {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using ILCalculator for *;
    using FHEManager for *;

    // Storage
    mapping(PoolId => mapping(uint256 => LPPosition)) public positions;
    mapping(PoolId => uint256[]) public activePositionIds;
    mapping(address => uint256[]) public userPositions;
    uint256 public nextPositionId;

    // Constants
    uint256 constant SLIPPAGE_TOLERANCE = 50; // 0.5% in basis points

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    /// @notice Returns the hook permissions
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false
        });
    }

    /// @notice Hook called before liquidity is added
    /// @dev Stores LP position with encrypted IL threshold
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override poolManagerOnly returns (bytes4) {
        // Decode encrypted IL threshold from hookData
        euint32 encryptedThreshold = abi.decode(hookData, (euint32));

        // Get current price
        uint256 currentPrice = ILCalculator.getCurrentPrice(poolManager, key);

        // Create position
        uint256 positionId = nextPositionId++;
        PoolId poolId = key.toId();

        positions[poolId][positionId] = LPPosition({
            lpAddress: sender,
            positionId: positionId,
            entryPrice: currentPrice,
            token0Amount: uint256(params.liquidityDelta), // Simplified
            token1Amount: uint256(params.liquidityDelta), // Simplified
            encryptedILThreshold: encryptedThreshold,
            depositTimestamp: block.timestamp,
            isActive: true
        });

        // Track active positions
        activePositionIds[poolId].push(positionId);
        userPositions[sender].push(positionId);

        emit PositionCreated(
            positionId,
            sender,
            positions[poolId][positionId].token0Amount,
            positions[poolId][positionId].token1Amount,
            currentPrice
        );

        return BaseHook.beforeAddLiquidity.selector;
    }

    /// @notice Hook called after a swap occurs
    /// @dev Checks IL for all positions and triggers withdrawals if threshold breached
    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4) {
        PoolId poolId = key.toId();
        uint256[] memory activeIds = activePositionIds[poolId];

        // Get current price
        uint256 currentPrice = ILCalculator.getCurrentPrice(poolManager, key);

        // Check each active position
        for (uint256 i = 0; i < activeIds.length; i++) {
            uint256 positionId = activeIds[i];
            LPPosition storage position = positions[poolId][positionId];

            if (!position.isActive) continue;

            // Calculate current IL
            uint256 currentILBp = ILCalculator.calculateIL(
                position.entryPrice,
                currentPrice
            );

            // FHE comparison: currentIL > threshold?
            bool shouldExit = FHEManager.compareThresholds(
                currentILBp,
                position.encryptedILThreshold
            );

            if (shouldExit) {
                // Trigger withdrawal
                _withdrawPosition(poolId, positionId, key, currentILBp);
            }
        }

        return BaseHook.afterSwap.selector;
    }

    /// @notice Internal function to withdraw position
    function _withdrawPosition(
        PoolId poolId,
        uint256 positionId,
        PoolKey calldata key,
        uint256 currentIL
    ) internal {
        LPPosition storage position = positions[poolId][positionId];

        require(position.isActive, "Position not active");

        // Mark inactive
        position.isActive = false;

        // Remove liquidity via PoolManager
        // Note: Simplified - actual implementation needs proper liquidity calculation
        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: /* get from position */,
            tickUpper: /* get from position */,
            liquidityDelta: -int256(position.token0Amount) // Simplified
        });

        // Execute removal
        poolManager.modifyLiquidity(key, params, "");

        emit ILThresholdBreached(positionId, currentIL);
        emit PositionWithdrawn(
            positionId,
            position.lpAddress,
            position.token0Amount,
            position.token1Amount,
            currentIL
        );
    }

    /// @notice Get position details (without encrypted data)
    function getPosition(PoolId poolId, uint256 positionId)
        external
        view
        returns (
            address lpAddress,
            uint256 entryPrice,
            uint256 token0Amount,
            uint256 token1Amount,
            uint256 depositTimestamp,
            bool isActive
        )
    {
        LPPosition storage position = positions[poolId][positionId];
        return (
            position.lpAddress,
            position.entryPrice,
            position.token0Amount,
            position.token1Amount,
            position.depositTimestamp,
            position.isActive
        );
    }

    /// @notice Get all active positions for a pool
    function getActivePositions(PoolId poolId)
        external
        view
        returns (uint256[] memory)
    {
        return activePositionIds[poolId];
    }

    /// @notice Get all positions for a user
    function getUserPositions(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userPositions[user];
    }
}
```

### Phase 4: Testing & Deployment (Days 7-8)

#### Task 1.5: Comprehensive Testing

**File:** `test/ILProtectionHook.t.sol`
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ILProtectionHook.sol";
import "./mocks/MockPoolManager.sol";

contract ILProtectionHookTest is Test {
    ILProtectionHook hook;
    MockPoolManager poolManager;
    PoolKey testKey;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        poolManager = new MockPoolManager();
        hook = new ILProtectionHook(IPoolManager(address(poolManager)));

        // Setup test pool key
        testKey = PoolKey({
            currency0: Currency.wrap(address(0x1)),
            currency1: Currency.wrap(address(0x2)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });
    }

    function testBeforeAddLiquidity_CreatesPosition() public {
        // Prepare encrypted threshold (mock)
        euint32 encryptedThreshold = FHEManager.encrypt(500); // 5%
        bytes memory hookData = abi.encode(encryptedThreshold);

        // Add liquidity
        vm.prank(alice);
        hook.beforeAddLiquidity(
            alice,
            testKey,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 1000e18
            }),
            hookData
        );

        // Verify position created
        (
            address lpAddress,
            uint256 entryPrice,
            ,
            ,
            ,
            bool isActive
        ) = hook.getPosition(testKey.toId(), 0);

        assertEq(lpAddress, alice);
        assertGt(entryPrice, 0);
        assertTrue(isActive);
    }

    function testAfterSwap_TriggersWithdrawal_WhenThresholdBreached() public {
        // Setup position with 5% threshold
        _createPosition(alice, 500); // 5% = 500 bp

        // Simulate price change causing >5% IL
        poolManager.setPrice(3000e18); // Significant price change

        // Execute swap
        vm.prank(bob);
        hook.afterSwap(
            bob,
            testKey,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: 1e18,
                sqrtPriceLimitX96: 0
            }),
            BalanceDelta.wrap(0),
            ""
        );

        // Verify position withdrawn
        (
            ,
            ,
            ,
            ,
            ,
            bool isActive
        ) = hook.getPosition(testKey.toId(), 0);

        assertFalse(isActive);
    }

    function testAfterSwap_DoesNotTrigger_WhenThresholdNotBreached() public {
        // Setup position with 10% threshold
        _createPosition(alice, 1000); // 10% = 1000 bp

        // Small price change (<10% IL)
        poolManager.setPrice(2050e18);

        // Execute swap
        vm.prank(bob);
        hook.afterSwap(
            bob,
            testKey,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: 1e18,
                sqrtPriceLimitX96: 0
            }),
            BalanceDelta.wrap(0),
            ""
        );

        // Verify position still active
        (
            ,
            ,
            ,
            ,
            ,
            bool isActive
        ) = hook.getPosition(testKey.toId(), 0);

        assertTrue(isActive);
    }

    function _createPosition(address lp, uint256 thresholdBp) internal {
        euint32 encryptedThreshold = FHEManager.encrypt(thresholdBp);
        bytes memory hookData = abi.encode(encryptedThreshold);

        vm.prank(lp);
        hook.beforeAddLiquidity(
            lp,
            testKey,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 1000e18
            }),
            hookData
        );
    }
}
```

#### Task 1.6: Deployment Script

**File:** `script/Deploy.s.sol`
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ILProtectionHook.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy hook
        ILProtectionHook hook = new ILProtectionHook(
            IPoolManager(poolManager)
        );

        console.log("ILProtectionHook deployed at:", address(hook));

        vm.stopBroadcast();
    }
}
```

### Deliverables for Developer 1

- [ ] Complete smart contract implementation
- [ ] ILCalculator library with tests (>95% coverage)
- [ ] ILProtectionHook with full functionality
- [ ] Comprehensive test suite
- [ ] Deployment scripts for testnet
- [ ] Gas optimization report
- [ ] Documentation of contract functions

---

## Developer 2: FHE Integration & Privacy Layer

### Phase 1: Fhenix Setup & Research (Days 1-2)

#### Task 2.1: Environment Setup

```bash
# Install Fhenix SDK
npm install fhenixjs
npm install @fhenixprotocol/contracts

# Setup Fhenix testnet RPC
export FHENIX_RPC_URL="https://api.helium.fhenix.zone"
export FHENIX_CHAIN_ID=8008420
```

#### Task 2.2: Research Fhenix Operations

**Study Documentation:**
- Fhenix FHE primitives (euint32, euint256, ebool)
- Supported operations (gt, lt, eq, add, sub, mul)
- Gas costs for FHE operations
- Permission system for decryption
- Client-side encryption with fhenixjs

**Create Reference Document:**

**File:** `docs/FHE_INTEGRATION_GUIDE.md`
```markdown
# FHE Integration Guide for PILI

## Fhenix Overview

Fhenix enables encrypted computations on blockchain using Fully Homomorphic Encryption (FHE).

## Key Concepts

### Data Types
- `euint32`: Encrypted 32-bit unsigned integer (for IL threshold in basis points)
- `euint256`: Encrypted 256-bit unsigned integer (for prices)
- `ebool`: Encrypted boolean (for comparison results)

### Operations
- `FHE.asEuint32(uint32 value)`: Encrypt plaintext value
- `FHE.gt(euint32 a, euint32 b)`: Greater than comparison (encrypted)
- `FHE.req(ebool condition)`: Require condition (reverts if false)
- `FHE.decrypt(euint32 value)`: Decrypt value (requires permission)

### Gas Costs (Testnet Estimates)
- Encryption: ~50,000 gas
- Comparison: ~100,000 gas
- Conditional execution: ~20,000 gas

## Client-Side Encryption Flow

```typescript
import { FhenixClient } from 'fhenixjs';

// Initialize client
const client = new FhenixClient({ provider });

// Encrypt IL threshold
const threshold = 500; // 5% in basis points
const encrypted = await client.encrypt_uint32(threshold);

// Send in transaction
const tx = await contract.addLiquidity(
  amount0,
  amount1,
  encrypted // hookData
);
```

## On-Chain Comparison Flow

```solidity
function afterSwap(...) {
    // Calculate current IL
    uint256 currentIL = calculateIL(entryPrice, currentPrice);

    // Encrypt current IL
    euint32 encryptedCurrentIL = FHE.asEuint32(uint32(currentIL));

    // Compare with threshold (never decrypted!)
    ebool shouldExit = FHE.gt(
        encryptedCurrentIL,
        position.encryptedILThreshold
    );

    // Convert to boolean for conditional (in production, use FHE.req)
    bool exitCondition = FHE.decrypt(shouldExit);

    if (exitCondition) {
        withdrawLiquidity(position);
    }
}
```

## Privacy Guarantees

1. **Threshold Privacy:** IL threshold never stored in plaintext
2. **Comparison Privacy:** Comparison happens on encrypted values
3. **Result Privacy:** Result can be encrypted until execution needed
4. **Client Privacy:** Encryption key stays with client

## Security Considerations

- Never log or emit encrypted values in plaintext
- Minimize decryption operations
- Use FHE.req() for conditional execution when possible
- Test for timing attacks
```

### Phase 2: FHE Manager Library (Days 3-5)

#### Task 2.3: Implement FHE Manager

**File:** `src/libraries/FHEManager.sol`
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@fhenixprotocol/contracts/FHE.sol";

/// @title FHEManager
/// @notice Library for FHE operations in IL Protection Hook
library FHEManager {

    /// @notice Encrypt a plaintext basis point value
    /// @param basisPoints Value in basis points (e.g., 500 = 5%)
    /// @return encrypted Encrypted value as euint32
    function encryptBasisPoints(uint32 basisPoints)
        internal
        pure
        returns (euint32 encrypted)
    {
        require(basisPoints <= 10000, "Invalid basis points");
        encrypted = FHE.asEuint32(basisPoints);
        return encrypted;
    }

    /// @notice Compare if current IL exceeds threshold using FHE
    /// @param currentILBp Current IL in basis points (plaintext)
    /// @param encryptedThreshold Encrypted threshold
    /// @return shouldExit True if IL exceeds threshold
    function compareThresholds(
        uint256 currentILBp,
        euint32 encryptedThreshold
    ) internal returns (bool shouldExit) {
        require(currentILBp <= type(uint32).max, "IL too large");

        // Encrypt current IL
        euint32 encryptedCurrentIL = FHE.asEuint32(uint32(currentILBp));

        // FHE comparison: currentIL > threshold?
        ebool comparisonResult = FHE.gt(encryptedCurrentIL, encryptedThreshold);

        // Decrypt result for conditional execution
        // Note: In production, could use FHE.req() to keep encrypted
        shouldExit = FHE.decrypt(comparisonResult);

        return shouldExit;
    }

    /// @notice Compare using FHE.req (reverts if condition false)
    /// @param currentILBp Current IL in basis points
    /// @param encryptedThreshold Encrypted threshold
    /// @dev Reverts if currentIL <= threshold, proceeds if currentIL > threshold
    function requireThresholdBreached(
        uint256 currentILBp,
        euint32 encryptedThreshold
    ) internal {
        require(currentILBp <= type(uint32).max, "IL too large");

        euint32 encryptedCurrentIL = FHE.asEuint32(uint32(currentILBp));
        ebool shouldExit = FHE.gt(encryptedCurrentIL, encryptedThreshold);

        // Enforce condition - reverts if false
        FHE.req(shouldExit);
    }

    /// @notice Validate encrypted threshold (client-provided)
    /// @param encryptedThreshold Encrypted threshold from client
    /// @return isValid Whether the encrypted value is valid
    function validateEncryptedThreshold(euint32 encryptedThreshold)
        internal
        pure
        returns (bool isValid)
    {
        // Basic validation - ensure not zero handle
        // Additional validation logic as needed
        return true; // Simplified for demo
    }

    /// @notice Encrypt price value (for price bounds feature)
    /// @param price Price value to encrypt
    /// @return encrypted Encrypted price as euint256
    function encryptPrice(uint256 price)
        internal
        pure
        returns (euint256 encrypted)
    {
        encrypted = FHE.asEuint256(price);
        return encrypted;
    }

    /// @notice Compare prices using FHE
    /// @param encryptedCurrentPrice Current price (encrypted)
    /// @param encryptedUpperBound Upper price bound (encrypted)
    /// @param encryptedLowerBound Lower price bound (encrypted)
    /// @return isOutOfBounds True if price outside bounds
    function comparePriceBounds(
        euint256 encryptedCurrentPrice,
        euint256 encryptedUpperBound,
        euint256 encryptedLowerBound
    ) internal returns (bool isOutOfBounds) {
        // Check if price > upper OR price < lower
        ebool aboveUpper = FHE.gt(encryptedCurrentPrice, encryptedUpperBound);
        ebool belowLower = FHE.lt(encryptedCurrentPrice, encryptedLowerBound);

        // OR operation (at least one is true)
        ebool outOfBounds = FHE.or(aboveUpper, belowLower);

        isOutOfBounds = FHE.decrypt(outOfBounds);
        return isOutOfBounds;
    }
}
```

#### Task 2.4: FHE Testing

**File:** `test/FHEManager.t.sol`
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/libraries/FHEManager.sol";
import "@fhenixprotocol/contracts/FHE.sol";

contract FHEManagerTest is Test {

    function testEncryptBasisPoints() public {
        uint32 threshold = 500; // 5%

        euint32 encrypted = FHEManager.encryptBasisPoints(threshold);

        // Verify encryption succeeded (non-zero handle)
        assertTrue(euint32.unwrap(encrypted) != 0);
    }

    function testEncryptBasisPoints_RevertsOnInvalid() public {
        uint32 invalidThreshold = 10001; // > 100%

        vm.expectRevert("Invalid basis points");
        FHEManager.encryptBasisPoints(invalidThreshold);
    }

    function testCompareThresholds_ExceedsThreshold() public {
        // Setup: threshold = 5% (500 bp)
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(500);

        // Current IL = 6% (600 bp) - exceeds threshold
        uint256 currentIL = 600;

        bool shouldExit = FHEManager.compareThresholds(
            currentIL,
            encryptedThreshold
        );

        assertTrue(shouldExit);
    }

    function testCompareThresholds_BelowThreshold() public {
        // Setup: threshold = 5% (500 bp)
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(500);

        // Current IL = 3% (300 bp) - below threshold
        uint256 currentIL = 300;

        bool shouldExit = FHEManager.compareThresholds(
            currentIL,
            encryptedThreshold
        );

        assertFalse(shouldExit);
    }

    function testRequireThresholdBreached_Reverts() public {
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(500);
        uint256 currentIL = 300; // Below threshold

        vm.expectRevert(); // FHE.req should revert
        FHEManager.requireThresholdBreached(currentIL, encryptedThreshold);
    }

    function testRequireThresholdBreached_Succeeds() public {
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(500);
        uint256 currentIL = 600; // Above threshold

        // Should not revert
        FHEManager.requireThresholdBreached(currentIL, encryptedThreshold);
    }

    function testEncryptPrice() public {
        uint256 price = 2500e18; // $2500

        euint256 encrypted = FHEManager.encryptPrice(price);

        assertTrue(euint256.unwrap(encrypted) != 0);
    }

    function testComparePriceBounds_WithinBounds() public {
        // Setup price bounds: $2000 - $3000
        euint256 lowerBound = FHEManager.encryptPrice(2000e18);
        euint256 upperBound = FHEManager.encryptPrice(3000e18);

        // Current price: $2500 (within bounds)
        euint256 currentPrice = FHEManager.encryptPrice(2500e18);

        bool outOfBounds = FHEManager.comparePriceBounds(
            currentPrice,
            upperBound,
            lowerBound
        );

        assertFalse(outOfBounds);
    }

    function testComparePriceBounds_AboveUpper() public {
        euint256 lowerBound = FHEManager.encryptPrice(2000e18);
        euint256 upperBound = FHEManager.encryptPrice(3000e18);

        // Current price: $3500 (above upper)
        euint256 currentPrice = FHEManager.encryptPrice(3500e18);

        bool outOfBounds = FHEManager.comparePriceBounds(
            currentPrice,
            upperBound,
            lowerBound
        );

        assertTrue(outOfBounds);
    }

    function testComparePriceBounds_BelowLower() public {
        euint256 lowerBound = FHEManager.encryptPrice(2000e18);
        euint256 upperBound = FHEManager.encryptPrice(3000e18);

        // Current price: $1500 (below lower)
        euint256 currentPrice = FHEManager.encryptPrice(1500e18);

        bool outOfBounds = FHEManager.comparePriceBounds(
            currentPrice,
            upperBound,
            lowerBound
        );

        assertTrue(outOfBounds);
    }
}
```

### Phase 3: Client-Side Integration (Days 6-7)

#### Task 2.5: Create Encryption Utilities

**File:** `utils/fheUtils.ts`
```typescript
import { FhenixClient, Encrypted Uint32 } from 'fhenixjs';
import { ethers } from 'ethers';

export class FHEUtils {
  private client: FhenixClient;

  constructor(provider: ethers.providers.Provider) {
    this.client = new FhenixClient({ provider });
  }

  /**
   * Encrypt IL threshold (in basis points) for on-chain storage
   * @param thresholdPercent Threshold as percentage (e.g., 5 for 5%)
   * @returns Encrypted threshold
   */
  async encryptILThreshold(thresholdPercent: number): Promise<EncryptedUint32> {
    // Convert percentage to basis points
    const basisPoints = Math.floor(thresholdPercent * 100);

    // Validate
    if (basisPoints < 0 || basisPoints > 10000) {
      throw new Error('Threshold must be between 0% and 100%');
    }

    // Encrypt using Fhenix client
    const encrypted = await this.client.encrypt_uint32(basisPoints);

    return encrypted;
  }

  /**
   * Encrypt price for price bounds feature
   * @param price Price value (in wei or base units)
   * @returns Encrypted price
   */
  async encryptPrice(price: bigint): Promise<EncryptedUint256> {
    const encrypted = await this.client.encrypt_uint256(price);
    return encrypted;
  }

  /**
   * Prepare hookData for addLiquidity transaction
   * @param encryptedThreshold Encrypted IL threshold
   * @returns Encoded hookData bytes
   */
  encodeHookData(encryptedThreshold: EncryptedUint32): string {
    // ABI encode the encrypted value
    const abiCoder = new ethers.utils.AbiCoder();
    const encoded = abiCoder.encode(['bytes'], [encryptedThreshold.data]);

    return encoded;
  }

  /**
   * Test encryption/decryption round-trip (for development only)
   * @param value Value to test
   * @returns Decrypted value (should match input)
   */
  async testEncryptionRoundTrip(value: number): Promise<number> {
    const encrypted = await this.client.encrypt_uint32(value);

    // Note: Decryption requires permission in production
    // This is for testing only
    const decrypted = await this.client.decrypt_uint32(encrypted);

    return decrypted;
  }

  /**
   * Estimate gas cost for FHE operations
   * @returns Estimated gas costs
   */
  estimateFHEGasCosts() {
    return {
      encryption: 50000,
      comparison: 100000,
      conditional: 20000,
      total: 170000
    };
  }
}

// Example usage
export async function exampleUsage() {
  const provider = new ethers.providers.JsonRpcProvider(
    'https://api.helium.fhenix.zone'
  );

  const fheUtils = new FHEUtils(provider);

  // Encrypt 5% IL threshold
  const threshold = await fheUtils.encryptILThreshold(5.0);
  console.log('Encrypted threshold:', threshold);

  // Prepare for transaction
  const hookData = fheUtils.encodeHookData(threshold);
  console.log('Hook data:', hookData);

  // Estimate gas
  const gasCosts = fheUtils.estimateFHEGasCosts();
  console.log('Estimated gas costs:', gasCosts);
}
```

#### Task 2.6: Integration Tests

**File:** `test/integration/FHEIntegration.test.ts`
```typescript
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { FHEUtils } from '../../utils/fheUtils';

describe('FHE Integration Tests', () => {
  let fheUtils: FHEUtils;
  let provider: ethers.providers.Provider;

  before(async () => {
    provider = ethers.provider;
    fheUtils = new FHEUtils(provider);
  });

  describe('Threshold Encryption', () => {
    it('should encrypt valid threshold', async () => {
      const threshold = 5.0; // 5%
      const encrypted = await fheUtils.encryptILThreshold(threshold);

      expect(encrypted).to.not.be.null;
      expect(encrypted.data).to.not.be.empty;
    });

    it('should reject invalid threshold (negative)', async () => {
      await expect(
        fheUtils.encryptILThreshold(-1)
      ).to.be.rejectedWith('Threshold must be between 0% and 100%');
    });

    it('should reject invalid threshold (>100%)', async () => {
      await expect(
        fheUtils.encryptILThreshold(101)
      ).to.be.rejectedWith('Threshold must be between 0% and 100%');
    });

    it('should handle edge cases (0% and 100%)', async () => {
      const zero = await fheUtils.encryptILThreshold(0);
      const hundred = await fheUtils.encryptILThreshold(100);

      expect(zero).to.not.be.null;
      expect(hundred).to.not.be.null;
    });
  });

  describe('HookData Encoding', () => {
    it('should encode encrypted threshold correctly', async () => {
      const encrypted = await fheUtils.encryptILThreshold(5.0);
      const hookData = fheUtils.encodeHookData(encrypted);

      expect(hookData).to.be.a('string');
      expect(hookData).to.match(/^0x[0-9a-f]+$/i);
    });
  });

  describe('Encryption Round-Trip', () => {
    it('should decrypt to original value', async () => {
      const original = 500; // 5% in bp
      const decrypted = await fheUtils.testEncryptionRoundTrip(original);

      expect(decrypted).to.equal(original);
    });
  });

  describe('Gas Estimation', () => {
    it('should provide reasonable gas estimates', () => {
      const estimates = fheUtils.estimateFHEGasCosts();

      expect(estimates.encryption).to.be.above(0);
      expect(estimates.comparison).to.be.above(0);
      expect(estimates.total).to.equal(
        estimates.encryption + estimates.comparison + estimates.conditional
      );
    });
  });
});
```

### Phase 4: Documentation & Security (Day 8)

#### Task 2.7: Security Analysis

**File:** `docs/FHE_SECURITY_ANALYSIS.md`
```markdown
# FHE Security Analysis for PILI

## Threat Model

### Assets to Protect
1. **IL Threshold:** LP's risk tolerance (must remain private)
2. **Comparison Results:** Whether threshold is breached
3. **User Strategy:** Overall trading/LP strategy

### Adversaries
1. **MEV Bots:** Want to front-run exits
2. **Other LPs:** Want to learn competitors' strategies
3. **Blockchain Observers:** Can analyze all on-chain data

## Privacy Guarantees

### What FHE Protects
- ✅ IL threshold value (encrypted on-chain)
- ✅ Comparison operations (computed on encrypted data)
- ✅ Individual LP strategies (thresholds independent)

### What FHE Does NOT Protect
- ❌ Entry price (public, needed for calculation)
- ❌ Token amounts (public, visible in pool)
- ❌ Withdrawal event (public, but doesn't reveal threshold)
- ❌ Timing of withdrawal (public, but threshold remains private)

## Attack Vectors & Mitigations

### 1. Statistical Inference Attack
**Attack:** Observe many withdrawals to infer threshold ranges
**Mitigation:**
- FHE prevents exact threshold knowledge
- Large user base makes individual strategy inference hard
- Random delays could be added

### 2. Timing Analysis Attack
**Attack:** Correlate price movements with withdrawals
**Mitigation:**
- Multiple LPs with different thresholds create noise
- Batch processing of withdrawals (future enhancement)
- Private mempools (Flashbots, etc.)

### 3. Front-Running Attack
**Attack:** See withdrawal transaction in mempool, front-run with large trade
**Mitigation:**
- Slippage protection on withdrawals
- Private mempools
- Threshold privacy limits predictability

### 4. Side-Channel Attacks
**Attack:** Analyze gas usage patterns to infer encrypted values
**Mitigation:**
- Constant-time FHE operations
- Consistent gas usage regardless of threshold value
- No conditional branches based on encrypted values

## Security Best Practices

### Smart Contract Level
```solidity
// ✅ GOOD: Never decrypt threshold
ebool shouldExit = FHE.gt(currentIL, threshold);
FHE.req(shouldExit);

// ❌ BAD: Decrypting reveals information
bool shouldExit = FHE.decrypt(FHE.gt(currentIL, threshold));
if (shouldExit) { withdraw(); }
```

### Client Level
```typescript
// ✅ GOOD: Encrypt before network transmission
const encrypted = await fheClient.encrypt_uint32(threshold);
await contract.addLiquidity(amount, encrypted);

// ❌ BAD: Sending plaintext
await contract.addLiquidity(amount, threshold); // Visible!
```

### Event Emission
```solidity
// ✅ GOOD: Emit without revealing threshold
emit PositionWithdrawn(positionId, lpAddress, amount);

// ❌ BAD: Emit threshold or comparison result
emit PositionWithdrawn(positionId, threshold, currentIL); // Reveals strategy!
```

## Gas Cost Security

### FHE Operation Costs
- Encryption: ~50k gas
- Comparison: ~100k gas
- Total per check: ~150k gas

### DoS Considerations
- Limit active positions per pool (prevents gas griefing)
- Early exit for inactive positions
- Batch processing for efficiency

## Audit Checklist

- [ ] Verify no plaintext threshold storage
- [ ] Confirm FHE operations use correct types
- [ ] Check for information leakage in events
- [ ] Validate gas usage consistency
- [ ] Test timing attack resistance
- [ ] Review permission system for decryption
- [ ] Ensure client-side encryption before transmission
- [ ] Verify slippage protection on withdrawals

## Future Enhancements

1. **Zero-Knowledge Proofs:** Prove threshold breached without revealing value
2. **Threshold Encryption:** Require multiple parties to decrypt
3. **Batch Processing:** Process multiple withdrawals atomically
4. **Anonymous Credentials:** Hide LP identity
```

### Deliverables for Developer 2

- [ ] FHEManager library with comprehensive FHE operations
- [ ] Client-side encryption utilities (TypeScript)
- [ ] FHE integration tests (Solidity + TypeScript)
- [ ] Security analysis document
- [ ] Integration guide for Developer 1 & 3
- [ ] Gas cost analysis and optimization recommendations
- [ ] Demo scripts showing encryption flow

---

## Developer 3: Frontend & User Experience

### Phase 1: Project Setup (Days 1-2)

#### Task 3.1: Initialize Next.js Project

```bash
# Create Next.js app with TypeScript and Tailwind
npx create-next-app@latest pili-frontend --typescript --tailwind --app --eslint

cd pili-frontend

# Install Web3 dependencies
npm install wagmi viem @tanstack/react-query
npm install @rainbow-me/rainbowkit
npm install fhenixjs

# Install UI dependencies
npm install @radix-ui/react-dialog @radix-ui/react-tabs
npm install @radix-ui/react-slider @radix-ui/react-tooltip
npm install lucide-react
npm install recharts

# Install shadcn/ui
npx shadcn-ui@latest init
```

**Project Structure:**
```
pili-frontend/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   ├── dashboard/
│   │   └── page.tsx
│   └── api/
├── components/
│   ├── ui/              # shadcn components
│   ├── wallet/
│   │   └── WalletConnect.tsx
│   ├── liquidity/
│   │   ├── AddLiquidityForm.tsx
│   │   ├── PositionCard.tsx
│   │   └── ILProtectionConfig.tsx
│   └── dashboard/
│       ├── PositionList.tsx
│       ├── ILChart.tsx
│       └── Stats.tsx
├── hooks/
│   ├── useContract.ts
│   ├── useFHE.ts
│   ├── usePositions.ts
│   └── useILCalculation.ts
├── lib/
│   ├── contracts.ts
│   ├── fhe.ts
│   └── utils.ts
├── types/
│   └── index.ts
└── public/
```

#### Task 3.2: Setup Wagmi & RainbowKit

**File:** `app/providers.tsx`
```typescript
'use client';

import { WagmiConfig, createConfig, configureChains } from 'wagmi';
import { sepolia, fhenixHelium } from 'wagmi/chains';
import { publicProvider } from 'wagmi/providers/public';
import { RainbowKitProvider, getDefaultWallets } from '@rainbow-me/rainbowkit';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import '@rainbow-me/rainbowkit/styles.css';

// Configure chains
const { chains, publicClient } = configureChains(
  [sepolia, fhenixHelium],
  [publicProvider()]
);

// Configure wallets
const { connectors } = getDefaultWallets({
  appName: 'PILI - IL Protection',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_ID!,
  chains,
});

// Create wagmi config
const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
});

// React Query client
const queryClient = new QueryClient();

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiConfig config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider chains={chains}>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiConfig>
  );
}
```

**File:** `app/layout.tsx`
```typescript
import './globals.css';
import { Inter } from 'next/font/google';
import { Providers } from './providers';

const inter = Inter({ subsets: ['latin'] });

export const metadata = {
  title: 'PILI - Privacy-Preserving IL Insurance',
  description: 'Automated impermanent loss protection for Uniswap v4',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
```

### Phase 2: Core Components (Days 3-5)

#### Task 3.3: Wallet Connection Component

**File:** `components/wallet/WalletConnect.tsx`
```typescript
'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';

export function WalletConnect() {
  const { address, isConnected } = useAccount();

  return (
    <div className="flex items-center gap-4">
      {isConnected && (
        <div className="text-sm text-gray-600">
          {address?.slice(0, 6)}...{address?.slice(-4)}
        </div>
      )}
      <ConnectButton />
    </div>
  );
}
```

#### Task 3.4: Add Liquidity Form with IL Protection

**File:** `components/liquidity/AddLiquidityForm.tsx`
```typescript
'use client';

import { useState } from 'react';
import { useAccount, useContractWrite, usePrepareContractWrite } from 'wagmi';
import { parseEther } from 'viem';
import { Card } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Slider } from '@/components/ui/slider';
import { Label } from '@/components/ui/label';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { Info, Shield, TrendingDown } from 'lucide-react';
import { useFHE } from '@/hooks/useFHE';
import { ILProtectionHookABI } from '@/lib/contracts';

export function AddLiquidityForm() {
  const { address } = useAccount();
  const { encryptThreshold } = useFHE();

  // Form state
  const [token0Amount, setToken0Amount] = useState('');
  const [token1Amount, setToken1Amount] = useState('');
  const [ilThreshold, setILThreshold] = useState(5); // 5% default
  const [isEncrypting, setIsEncrypting] = useState(false);

  // Calculate projected IL scenarios
  const calculateProjectedIL = (priceChange: number) => {
    const ratio = 1 + priceChange / 100;
    const il = (2 * Math.sqrt(ratio) / (1 + ratio) - 1) * 100;
    return Math.abs(il).toFixed(2);
  };

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      setIsEncrypting(true);

      // Encrypt IL threshold
      const encryptedThreshold = await encryptThreshold(ilThreshold);

      // Prepare transaction
      // (Will integrate with contract write)
      console.log('Encrypted threshold:', encryptedThreshold);
      console.log('Adding liquidity:', {
        token0: token0Amount,
        token1: token1Amount,
        threshold: ilThreshold
      });

    } catch (error) {
      console.error('Error:', error);
    } finally {
      setIsEncrypting(false);
    }
  };

  return (
    <Card className="p-6">
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Header */}
        <div className="flex items-center gap-2">
          <Shield className="w-6 h-6 text-blue-600" />
          <h2 className="text-2xl font-bold">Add Protected Liquidity</h2>
        </div>

        {/* Token Inputs */}
        <div className="space-y-4">
          <div>
            <Label htmlFor="token0">ETH Amount</Label>
            <Input
              id="token0"
              type="number"
              step="0.001"
              placeholder="0.0"
              value={token0Amount}
              onChange={(e) => setToken0Amount(e.target.value)}
              className="text-lg"
            />
          </div>

          <div>
            <Label htmlFor="token1">USDC Amount</Label>
            <Input
              id="token1"
              type="number"
              step="0.01"
              placeholder="0.0"
              value={token1Amount}
              onChange={(e) => setToken1Amount(e.target.value)}
              className="text-lg"
            />
          </div>
        </div>

        {/* IL Protection Configuration */}
        <div className="space-y-4 p-4 bg-blue-50 rounded-lg">
          <div className="flex items-center gap-2">
            <TrendingDown className="w-5 h-5 text-blue-600" />
            <h3 className="font-semibold">IL Protection Settings</h3>
            <TooltipProvider>
              <Tooltip>
                <TooltipTrigger>
                  <Info className="w-4 h-4 text-gray-400" />
                </TooltipTrigger>
                <TooltipContent>
                  <p className="max-w-xs">
                    Your liquidity will automatically exit when impermanent loss
                    exceeds this threshold. This value is encrypted and completely private.
                  </p>
                </TooltipContent>
              </Tooltip>
            </TooltipProvider>
          </div>

          {/* IL Threshold Slider */}
          <div className="space-y-2">
            <div className="flex justify-between">
              <Label>Maximum IL Tolerance</Label>
              <span className="text-lg font-bold text-blue-600">
                {ilThreshold}%
              </span>
            </div>

            <Slider
              value={[ilThreshold]}
              onValueChange={([value]) => setILThreshold(value)}
              min={1}
              max={20}
              step={0.5}
              className="w-full"
            />

            <div className="flex justify-between text-xs text-gray-500">
              <span>1% (Conservative)</span>
              <span>20% (Aggressive)</span>
            </div>
          </div>

          {/* Privacy Notice */}
          <div className="flex items-start gap-2 text-sm text-gray-600 bg-white p-3 rounded">
            <Shield className="w-4 h-4 mt-0.5 flex-shrink-0" />
            <p>
              <strong>Privacy Protected:</strong> Your {ilThreshold}% threshold
              will be encrypted before being stored on-chain. No one can see your
              risk tolerance, not even MEV bots.
            </p>
          </div>
        </div>

        {/* Projected IL Scenarios */}
        <div className="space-y-2">
          <h4 className="font-semibold text-sm text-gray-700">
            Projected IL at Different Price Changes
          </h4>
          <div className="grid grid-cols-3 gap-2 text-sm">
            {[10, 25, 50].map((priceChange) => {
              const projectedIL = calculateProjectedIL(priceChange);
              const wouldExit = parseFloat(projectedIL) > ilThreshold;

              return (
                <div
                  key={priceChange}
                  className={`p-3 rounded ${
                    wouldExit ? 'bg-red-50 border border-red-200' : 'bg-gray-50'
                  }`}
                >
                  <div className="font-semibold">+{priceChange}% Price</div>
                  <div className="text-lg">{projectedIL}% IL</div>
                  {wouldExit && (
                    <div className="text-xs text-red-600 mt-1">
                      ⚠️ Would auto-exit
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Gas Estimate */}
        <div className="text-sm text-gray-600">
          <div className="flex justify-between">
            <span>Estimated Gas Cost:</span>
            <span className="font-semibold">~$3-5</span>
          </div>
          <div className="flex justify-between">
            <span>Monthly Monitoring Cost:</span>
            <span className="font-semibold">~$3-5</span>
          </div>
        </div>

        {/* Submit Button */}
        <Button
          type="submit"
          className="w-full"
          size="lg"
          disabled={!address || !token0Amount || !token1Amount || isEncrypting}
        >
          {isEncrypting ? (
            <>
              <span className="animate-spin mr-2">⏳</span>
              Encrypting Threshold...
            </>
          ) : (
            <>
              <Shield className="w-5 h-5 mr-2" />
              Add Protected Liquidity
            </>
          )}
        </Button>
      </form>
    </Card>
  );
}
```

#### Task 3.5: Position Card Component

**File:** `components/liquidity/PositionCard.tsx`
```typescript
'use client';

import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { AlertTriangle, TrendingUp, TrendingDown, DollarSign } from 'lucide-react';
import { formatEther, formatUnits } from 'viem';

interface Position {
  id: string;
  token0Amount: bigint;
  token1Amount: bigint;
  entryPrice: bigint;
  currentPrice: bigint;
  currentIL: number; // Decrypted client-side
  threshold: number; // Decrypted client-side
  isActive: boolean;
  depositTimestamp: number;
}

export function PositionCard({ position }: { position: Position }) {
  const ilPercentage = (position.currentIL / position.threshold) * 100;
  const priceChange =
    ((Number(position.currentPrice) - Number(position.entryPrice)) /
     Number(position.entryPrice)) * 100;

  const getILStatusColor = () => {
    if (ilPercentage < 50) return 'text-green-600';
    if (ilPercentage < 80) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getILStatusBadge = () => {
    if (ilPercentage < 50) return { color: 'green', text: 'Safe' };
    if (ilPercentage < 80) return { color: 'yellow', text: 'Warning' };
    return { color: 'red', text: 'Critical' };
  };

  const status = getILStatusBadge();

  return (
    <Card className="p-6 space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="text-lg font-semibold">
            ETH/USDC Position #{position.id}
          </div>
          <Badge variant={status.color as any}>
            {status.text}
          </Badge>
          {!position.isActive && (
            <Badge variant="secondary">Withdrawn</Badge>
          )}
        </div>
        <Button variant="outline" size="sm">
          Manage
        </Button>
      </div>

      {/* Amounts */}
      <div className="grid grid-cols-2 gap-4">
        <div>
          <div className="text-sm text-gray-500">ETH Amount</div>
          <div className="text-xl font-semibold">
            {formatEther(position.token0Amount)} ETH
          </div>
        </div>
        <div>
          <div className="text-sm text-gray-500">USDC Amount</div>
          <div className="text-xl font-semibold">
            {formatUnits(position.token1Amount, 6)} USDC
          </div>
        </div>
      </div>

      {/* Price Info */}
      <div className="grid grid-cols-2 gap-4 text-sm">
        <div>
          <div className="text-gray-500">Entry Price</div>
          <div className="font-semibold">
            ${formatUnits(position.entryPrice, 18)}
          </div>
        </div>
        <div>
          <div className="text-gray-500">Current Price</div>
          <div className="font-semibold flex items-center gap-1">
            ${formatUnits(position.currentPrice, 18)}
            {priceChange >= 0 ? (
              <TrendingUp className="w-4 h-4 text-green-600" />
            ) : (
              <TrendingDown className="w-4 h-4 text-red-600" />
            )}
            <span className={priceChange >= 0 ? 'text-green-600' : 'text-red-600'}>
              {priceChange.toFixed(2)}%
            </span>
          </div>
        </div>
      </div>

      {/* IL Progress */}
      <div className="space-y-2">
        <div className="flex justify-between text-sm">
          <span className="text-gray-500">Impermanent Loss</span>
          <span className={`font-semibold ${getILStatusColor()}`}>
            {position.currentIL.toFixed(2)}% / {position.threshold.toFixed(2)}%
          </span>
        </div>
        <Progress value={ilPercentage} className="h-2" />
        <div className="flex justify-between text-xs text-gray-500">
          <span>0%</span>
          <span>Threshold ({position.threshold}%)</span>
        </div>
      </div>

      {/* Warning if close to threshold */}
      {ilPercentage > 80 && position.isActive && (
        <div className="flex items-start gap-2 p-3 bg-red-50 rounded text-sm text-red-800">
          <AlertTriangle className="w-4 h-4 mt-0.5 flex-shrink-0" />
          <p>
            <strong>Warning:</strong> Your position is close to the auto-exit
            threshold. Current IL is at {ilPercentage.toFixed(0)}% of your limit.
          </p>
        </div>
      )}

      {/* Time info */}
      <div className="text-xs text-gray-500 pt-2 border-t">
        Deposited {new Date(position.depositTimestamp * 1000).toLocaleDateString()}
      </div>
    </Card>
  );
}
```

### Phase 3: Dashboard & Monitoring (Days 6-7)

#### Task 3.6: Dashboard Page

**File:** `app/dashboard/page.tsx`
```typescript
'use client';

import { useAccount } from 'wagmi';
import { usePositions } from '@/hooks/usePositions';
import { PositionCard } from '@/components/liquidity/PositionCard';
import { Card } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Shield, TrendingDown, DollarSign, Activity } from 'lucide-react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';

export default function DashboardPage() {
  const { address, isConnected } = useAccount();
  const { positions, stats, isLoading } = usePositions(address);

  if (!isConnected) {
    return (
      <div className="container mx-auto px-4 py-16">
        <Card className="p-12 text-center">
          <h2 className="text-2xl font-bold mb-4">
            Connect Your Wallet
          </h2>
          <p className="text-gray-600 mb-6">
            Connect your wallet to view and manage your protected positions
          </p>
        </Card>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold mb-2">Your Protected Positions</h1>
          <p className="text-gray-600">
            Monitor and manage your IL-protected liquidity
          </p>
        </div>
        <Link href="/">
          <Button>
            <Shield className="w-4 h-4 mr-2" />
            Add New Position
          </Button>
        </Link>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <Card className="p-6">
          <div className="flex items-center gap-3 mb-2">
            <Activity className="w-5 h-5 text-blue-600" />
            <div className="text-sm text-gray-500">Active Positions</div>
          </div>
          <div className="text-3xl font-bold">{stats.activePositions}</div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center gap-3 mb-2">
            <DollarSign className="w-5 h-5 text-green-600" />
            <div className="text-sm text-gray-500">Total Value</div>
          </div>
          <div className="text-3xl font-bold">
            ${stats.totalValue.toLocaleString()}
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center gap-3 mb-2">
            <TrendingDown className="w-5 h-5 text-yellow-600" />
            <div className="text-sm text-gray-500">Avg IL</div>
          </div>
          <div className="text-3xl font-bold">
            {stats.averageIL.toFixed(2)}%
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center gap-3 mb-2">
            <Shield className="w-5 h-5 text-purple-600" />
            <div className="text-sm text-gray-500">Protected Value</div>
          </div>
          <div className="text-3xl font-bold">
            ${stats.protectedValue.toLocaleString()}
          </div>
        </Card>
      </div>

      {/* Positions List */}
      <Tabs defaultValue="active" className="w-full">
        <TabsList>
          <TabsTrigger value="active">
            Active ({positions.filter(p => p.isActive).length})
          </TabsTrigger>
          <TabsTrigger value="withdrawn">
            Withdrawn ({positions.filter(p => !p.isActive).length})
          </TabsTrigger>
          <TabsTrigger value="all">
            All ({positions.length})
          </TabsTrigger>
        </TabsList>

        <TabsContent value="active" className="space-y-4 mt-6">
          {isLoading ? (
            <div className="text-center py-12">Loading positions...</div>
          ) : positions.filter(p => p.isActive).length === 0 ? (
            <Card className="p-12 text-center">
              <p className="text-gray-600 mb-4">
                You don't have any active protected positions
              </p>
              <Link href="/">
                <Button>
                  <Shield className="w-4 h-4 mr-2" />
                  Add Your First Position
                </Button>
              </Link>
            </Card>
          ) : (
            positions
              .filter(p => p.isActive)
              .map(position => (
                <PositionCard key={position.id} position={position} />
              ))
          )}
        </TabsContent>

        <TabsContent value="withdrawn" className="space-y-4 mt-6">
          {positions
            .filter(p => !p.isActive)
            .map(position => (
              <PositionCard key={position.id} position={position} />
            ))}
        </TabsContent>

        <TabsContent value="all" className="space-y-4 mt-6">
          {positions.map(position => (
            <PositionCard key={position.id} position={position} />
          ))}
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

#### Task 3.7: Custom Hooks

**File:** `hooks/useFHE.ts`
```typescript
import { useState } from 'react';
import { usePublicClient } from 'wagmi';
import { FhenixClient, EncryptedUint32 } from 'fhenixjs';

export function useFHE() {
  const publicClient = usePublicClient();
  const [isEncrypting, setIsEncrypting] = useState(false);

  const encryptThreshold = async (thresholdPercent: number): Promise<EncryptedUint32> => {
    setIsEncrypting(true);
    try {
      // Convert to basis points
      const basisPoints = Math.floor(thresholdPercent * 100);

      // Initialize Fhenix client
      const fhenixClient = new FhenixClient({ provider: publicClient });

      // Encrypt
      const encrypted = await fhenixClient.encrypt_uint32(basisPoints);

      return encrypted;
    } finally {
      setIsEncrypting(false);
    }
  };

  const encryptPrice = async (price: bigint): Promise<EncryptedUint256> => {
    setIsEncrypting(true);
    try {
      const fhenixClient = new FhenixClient({ provider: publicClient });
      const encrypted = await fhenixClient.encrypt_uint256(price);
      return encrypted;
    } finally {
      setIsEncrypting(false);
    }
  };

  return {
    encryptThreshold,
    encryptPrice,
    isEncrypting
  };
}
```

**File:** `hooks/usePositions.ts`
```typescript
import { useEffect, useState } from 'react';
import { useContractReads } from 'wagmi';
import { ILProtectionHookABI, ILProtectionHookAddress } from '@/lib/contracts';

export function usePositions(userAddress?: string) {
  const [positions, setPositions] = useState([]);
  const [stats, setStats] = useState({
    activePositions: 0,
    totalValue: 0,
    averageIL: 0,
    protectedValue: 0
  });

  // Read user positions from contract
  const { data, isLoading } = useContractReads({
    contracts: userAddress ? [
      {
        address: ILProtectionHookAddress,
        abi: ILProtectionHookABI,
        functionName: 'getUserPositions',
        args: [userAddress]
      }
    ] : [],
    watch: true
  });

  useEffect(() => {
    if (data) {
      // Process positions data
      // (Simplified - actual implementation would fetch full position details)
      const positionIds = data[0].result as bigint[];

      // Fetch details for each position
      // Calculate stats
      // Update state
    }
  }, [data]);

  return {
    positions,
    stats,
    isLoading
  };
}
```

### Phase 4: Polish & Demo Preparation (Day 8)

#### Task 3.8: Landing Page

**File:** `app/page.tsx`
```typescript
'use client';

import { WalletConnect } from '@/components/wallet/WalletConnect';
import { AddLiquidityForm } from '@/components/liquidity/AddLiquidityForm';
import { Card } from '@/components/ui/card';
import { Shield, Lock, Zap, TrendingDown } from 'lucide-react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white">
      {/* Header */}
      <header className="border-b bg-white/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Shield className="w-8 h-8 text-blue-600" />
            <span className="text-2xl font-bold">PILI</span>
          </div>
          <div className="flex items-center gap-4">
            <Link href="/dashboard">
              <Button variant="ghost">Dashboard</Button>
            </Link>
            <WalletConnect />
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-16">
        <div className="max-w-4xl mx-auto text-center mb-12">
          <h1 className="text-5xl font-bold mb-6">
            Privacy-Preserving
            <br />
            <span className="text-blue-600">Impermanent Loss Insurance</span>
          </h1>
          <p className="text-xl text-gray-600 mb-8">
            Automated protection for Uniswap liquidity providers using
            Fully Homomorphic Encryption. Set your risk tolerance privately,
            and let PILI protect your liquidity 24/7.
          </p>

          {/* Features */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
            <Card className="p-6 text-left">
              <Shield className="w-10 h-10 text-blue-600 mb-3" />
              <h3 className="font-semibold mb-2">Automated Protection</h3>
              <p className="text-sm text-gray-600">
                Set your max IL tolerance and forget it. Auto-exit when breached.
              </p>
            </Card>

            <Card className="p-6 text-left">
              <Lock className="w-10 h-10 text-purple-600 mb-3" />
              <h3 className="font-semibold mb-2">Complete Privacy</h3>
              <p className="text-sm text-gray-600">
                FHE encryption keeps your threshold secret from MEV bots.
              </p>
            </Card>

            <Card className="p-6 text-left">
              <Zap className="w-10 h-10 text-yellow-600 mb-3" />
              <h3 className="font-semibold mb-2">Gas Efficient</h3>
              <p className="text-sm text-gray-600">
                Only ~$3-5/month per protected position on mainnet.
              </p>
            </Card>
          </div>
        </div>

        {/* Main Form */}
        <div className="max-w-2xl mx-auto">
          <AddLiquidityForm />
        </div>
      </section>

      {/* How It Works */}
      <section className="bg-gray-50 py-16">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-12">How It Works</h2>

          <div className="max-w-4xl mx-auto grid grid-cols-1 md:grid-cols-4 gap-8">
            {[
              {
                step: 1,
                title: 'Deposit Liquidity',
                description: 'Add liquidity to Uniswap v4 pool with your tokens'
              },
              {
                step: 2,
                title: 'Set Threshold',
                description: 'Choose your max IL tolerance (e.g., 5%)'
              },
              {
                step: 3,
                title: 'Encrypt & Store',
                description: 'Threshold encrypted with FHE and stored on-chain'
              },
              {
                step: 4,
                title: 'Auto Protection',
                description: 'Hook monitors IL and exits when threshold breached'
              }
            ].map(({ step, title, description }) => (
              <div key={step} className="text-center">
                <div className="w-12 h-12 bg-blue-600 text-white rounded-full flex items-center justify-center text-xl font-bold mx-auto mb-4">
                  {step}
                </div>
                <h3 className="font-semibold mb-2">{title}</h3>
                <p className="text-sm text-gray-600">{description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t py-8">
        <div className="container mx-auto px-4 text-center text-gray-600">
          <p>Built for Uniswap v4 Hookathon in Partnership with FHE</p>
          <p className="text-sm mt-2">
            Open Source • Audited • Privacy-First
          </p>
        </div>
      </footer>
    </div>
  );
}
```

### Deliverables for Developer 3

- [ ] Complete Next.js application with all pages
- [ ] Wallet connection with RainbowKit
- [ ] Add Liquidity form with IL protection configuration
- [ ] Position monitoring dashboard
- [ ] FHE client-side encryption integration
- [ ] Responsive design (mobile + desktop)
- [ ] Demo video (2-3 minutes)
- [ ] Deployment to Vercel/Netlify
- [ ] User documentation

---

## Development Phases

### Week 1: Foundation

**Days 1-2: Setup**
- Dev 1: Foundry project, data structures
- Dev 2: Fhenix research, environment setup
- Dev 3: Next.js project, Wagmi configuration

**Days 3-4: Core Development**
- Dev 1: IL Calculator library
- Dev 2: FHEManager library
- Dev 3: Basic components (wallet, forms)

**Days 5-6: Integration**
- Dev 1: Hook implementation
- Dev 2: Client-side encryption
- Dev 3: Position cards, dashboard

**Days 7-8: Testing & Polish**
- Dev 1: Smart contract testing, deployment
- Dev 2: FHE integration tests, security analysis
- Dev 3: Demo prep, documentation

### Week 2: Polish & Submission

**Days 9-10: Integration Testing**
- All devs: End-to-end testing
- Fix bugs and edge cases
- Optimize gas costs

**Days 11-12: Demo & Documentation**
- All devs: Demo video production
- Complete README and docs
- Prepare presentation

**Days 13-14: Final Polish**
- All devs: Code review
- Security checks
- Submission preparation

---

## Integration Points

### Dev 1 ↔ Dev 2

**Smart Contract Interface:**
```solidity
// Dev 2 provides to Dev 1
library FHEManager {
    function compareThresholds(uint256 currentIL, euint32 threshold)
        returns (bool);
    function encryptBasisPoints(uint32 bp) returns (euint32);
}

// Dev 1 uses in hook
function afterSwap(...) {
    uint256 currentIL = ILCalculator.calculateIL(...);
    bool shouldExit = FHEManager.compareThresholds(currentIL, threshold);
    if (shouldExit) { withdraw(); }
}
```

### Dev 2 ↔ Dev 3

**Client Encryption Interface:**
```typescript
// Dev 2 provides to Dev 3
class FHEUtils {
    async encryptILThreshold(percent: number): Promise<EncryptedUint32>;
    encodeHookData(encrypted: EncryptedUint32): string;
}

// Dev 3 uses in frontend
const encrypted = await fheUtils.encryptILThreshold(5.0);
const hookData = fheUtils.encodeHookData(encrypted);
await contract.beforeAddLiquidity(..., hookData);
```

### Dev 1 ↔ Dev 3

**Contract ABI Interface:**
```typescript
// Dev 1 provides ABI and addresses
export const ILProtectionHookABI = [...];
export const ILProtectionHookAddress = "0x...";

// Dev 3 uses for contract interaction
import { useContractWrite } from 'wagmi';
import { ILProtectionHookABI, ILProtectionHookAddress } from '@/lib/contracts';

const { write } = useContractWrite({
    address: ILProtectionHookAddress,
    abi: ILProtectionHookABI,
    functionName: 'beforeAddLiquidity'
});
```

---

## Testing Strategy

### Unit Tests

**Dev 1: Smart Contracts**
```bash
# Run tests
forge test

# Coverage
forge coverage

# Gas snapshot
forge snapshot
```

**Test Files:**
- `ILCalculator.t.sol` - IL calculation accuracy
- `ILProtectionHook.t.sol` - Hook functionality
- `Integration.t.sol` - End-to-end flows

### Integration Tests

**Dev 2: FHE Operations**
```bash
# Run FHE tests
npm run test:fhe

# Test encryption flow
npm run test:integration
```

**Test Scenarios:**
- Encryption/decryption round-trip
- Threshold comparison accuracy
- Gas cost validation

### Frontend Tests

**Dev 3: UI/UX**
```bash
# Run frontend tests
npm run test

# E2E tests
npm run test:e2e
```

**Test Scenarios:**
- Wallet connection flow
- Form validation
- Transaction submission
- Position monitoring

### Combined Testing

**All Devs: Integration**
1. Deploy contracts to testnet
2. Test frontend → encryption → contract flow
3. Verify IL calculation accuracy
4. Test auto-exit functionality
5. Measure gas costs

---

## Deployment Plan

### Testnet Deployment

**Phase 1: Contracts (Dev 1)**
```bash
# Deploy to Sepolia
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast

# Verify contract
forge verify-contract <address> ILProtectionHook --chain sepolia
```

**Phase 2: Fhenix Setup (Dev 2)**
```bash
# Deploy to Fhenix testnet
# Configure FHE parameters
# Test encryption flow
```

**Phase 3: Frontend (Dev 3)**
```bash
# Deploy to Vercel
vercel --prod

# Configure environment variables
# Connect to testnet contracts
```

### Testing Flow

1. **Dev 3** creates liquidity position via frontend
2. **Dev 2** verifies encryption succeeded
3. **Dev 1** confirms position stored correctly
4. Trigger swap to change price
5. Verify IL calculation
6. Confirm auto-exit when threshold breached

---

## Hackathon Deliverables

### Code Repositories

1. **Smart Contracts Repo** (Dev 1 lead)
   - Complete Foundry project
   - All contracts and libraries
   - Comprehensive tests (>90% coverage)
   - Deployment scripts
   - README with setup instructions

2. **Frontend Repo** (Dev 3 lead)
   - Complete Next.js application
   - All components and hooks
   - FHE integration (Dev 2 contribution)
   - Deployed demo link
   - README with usage guide

### Documentation

1. **README.md** (All devs)
   - Project overview
   - Technical architecture
   - Setup instructions
   - Demo instructions
   - Team member contributions

2. **Technical Documentation** (All devs)
   - Smart contract documentation (Dev 1)
   - FHE integration guide (Dev 2)
   - Frontend architecture (Dev 3)
   - API documentation

### Demo Materials

1. **Demo Video** (Dev 3 lead, all contribute)
   - 2-3 minutes maximum
   - Show complete user flow
   - Highlight privacy features
   - Demonstrate auto-exit
   - Professional production

2. **Presentation Slides** (All devs)
   - Problem statement
   - Solution overview
   - Technical innovation (FHE + Hooks)
   - Demo walkthrough
   - Future roadmap

### Live Demo

1. **Deployed Testnet Contracts**
   - Verified on block explorer
   - Accessible via frontend
   - Pre-funded with testnet tokens

2. **Live Frontend**
   - Deployed on Vercel/Netlify
   - Connected to testnet
   - Working wallet connection
   - Functional add liquidity + monitoring

---

## Demo Scenario

### Setup (Before Demo)

1. Deploy contracts to testnet
2. Create test LP position with 5% IL threshold
3. Have wallet ready with testnet tokens
4. Prepare video recording

### Demo Script

**Scene 1: Problem Introduction (30s)**
- Show traditional LP dashboard
- Explain impermanent loss problem
- Highlight lack of automated protection

**Scene 2: Solution Overview (30s)**
- Introduce PILI
- Explain FHE privacy benefits
- Show architecture diagram

**Scene 3: User Flow (60s)**
1. Connect wallet
2. Select pool (ETH/USDC)
3. Enter token amounts (10 ETH, 25,000 USDC)
4. Set IL threshold (5%) with slider
5. Show encryption happening
6. Submit transaction
7. Show position created

**Scene 4: Monitoring (30s)**
1. Navigate to dashboard
2. Show active position
3. Display current IL (3.2%)
4. Show IL progress bar

**Scene 5: Auto-Exit Demo (30s)**
1. Trigger price change (manual or pre-recorded)
2. Show IL exceeds 5%
3. Show automatic withdrawal
4. Show tokens returned to wallet

**Scene 6: Technical Highlights (30s)**
- Show encrypted threshold on blockchain
- Explain FHE comparison
- Highlight gas efficiency
- Show privacy guarantees

**Closing (10s)**
- Team info
- Open source links
- Call to action

---

## Key Success Factors

### For Developer 1 (Smart Contracts)

✅ **Must Have:**
- Working IL calculation (accurate to 0.01%)
- Functional hook integration with Uniswap v4
- Position storage and retrieval
- Basic withdrawal logic

✅ **Nice to Have:**
- Gas optimizations
- Multiple pool support
- Emergency pause functionality
- Advanced position management

### For Developer 2 (FHE Integration)

✅ **Must Have:**
- Client-side threshold encryption
- On-chain FHE comparison
- Privacy guarantees verified
- Integration with Dev 1 & 3

✅ **Nice to Have:**
- Gas cost optimizations
- Multiple encryption schemes
- Decryption permissions system
- Security audit prep

### For Developer 3 (Frontend)

✅ **Must Have:**
- Wallet connection working
- Add liquidity form functional
- Position monitoring dashboard
- FHE encryption integration
- Responsive design

✅ **Nice to Have:**
- Advanced charts and analytics
- Mobile app
- Notification system
- Social features

---

## Communication & Coordination

### Daily Standups

**Format:** 15 minutes, async or sync

**Questions:**
1. What did you complete yesterday?
2. What are you working on today?
3. Any blockers?

### Integration Checkpoints

**Day 2:** Interfaces defined
**Day 4:** First integration test
**Day 6:** Full integration test
**Day 8:** Demo rehearsal

### Code Sharing

**Tools:**
- GitHub for version control
- Shared Notion/Google Docs for documentation
- Slack/Discord for communication
- Loom for async video updates

**Branches:**
- `main` - stable, working code
- `dev` - integration branch
- `dev1-contracts` - Developer 1
- `dev2-fhe` - Developer 2
- `dev3-frontend` - Developer 3

---

## Risk Mitigation

### Technical Risks

**Risk:** Fhenix API changes or issues
**Mitigation:** Start with FHE integration early (Day 1-2)

**Risk:** Uniswap v4 not available on testnet
**Mitigation:** Prepare mock pool manager for testing

**Risk:** Integration issues between components
**Mitigation:** Define interfaces early, frequent integration tests

**Risk:** Gas costs too high
**Mitigation:** Gas optimization from Day 1, have fallback strategies

### Timeline Risks

**Risk:** Scope too large for hackathon
**Mitigation:** Focus on MVP (must-haves), cut nice-to-haves if needed

**Risk:** Developer availability
**Mitigation:** Clear task breakdown, async communication, documented handoffs

### Demo Risks

**Risk:** Live demo fails during presentation
**Mitigation:** Pre-record backup video, test repeatedly

**Risk:** Testnet issues during demo
**Mitigation:** Have screenshots/video of working features

---

## Post-Hackathon Roadmap

### Phase 1: Polish (Week 1-2)
- Address judge feedback
- Fix bugs found during hackathon
- Improve documentation

### Phase 2: Audit (Week 3-4)
- Security audit contracts
- Fix vulnerabilities
- Formal verification

### Phase 3: Mainnet (Week 5-6)
- Deploy to mainnet
- Start with limited beta
- Gradual rollout

---

## Resources & References

### Uniswap v4
- [Docs](https://docs.uniswap.org/contracts/v4/overview)
- [GitHub](https://github.com/Uniswap/v4-core)
- [Hook Examples](https://github.com/Uniswap/v4-periphery)

### Fhenix
- [Docs](https://docs.fhenix.io/)
- [SDK](https://github.com/FhenixProtocol/fhenix.js)
- [Examples](https://github.com/FhenixProtocol/fhenix-hardhat-example)

### Development Tools
- [Foundry Book](https://book.getfoundry.sh/)
- [Next.js Docs](https://nextjs.org/docs)
- [Wagmi Docs](https://wagmi.sh/)

---

## Contact & Support

### Team Communication

**Developer 1 (Contracts):**
- Responsible for: Hook implementation, IL calculations
- Primary tools: Foundry, Solidity
- Blockers: Share immediately in #dev-chat

**Developer 2 (FHE):**
- Responsible for: FHE integration, privacy layer
- Primary tools: Fhenix, TypeScript, Solidity
- Blockers: Share immediately in #dev-chat

**Developer 3 (Frontend):**
- Responsible for: UI/UX, demo
- Primary tools: Next.js, TypeScript
- Blockers: Share immediately in #dev-chat

### Emergency Contacts

If any developer is blocked:
1. Post in team chat
2. Schedule quick sync call
3. Pivot to alternative approach if needed

---

## Appendix A: Environment Setup

### Developer 1 Setup

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone and setup
git clone <repo>
cd pili-contracts
forge install
forge build
forge test

# Environment variables
cp .env.example .env
# Edit .env with your keys
```

### Developer 2 Setup

```bash
# Install Fhenix CLI
npm install -g fhenix-cli

# Setup project
git clone <repo>
cd pili-contracts
npm install

# Configure Fhenix
fhenix-cli config --network testnet
```

### Developer 3 Setup

```bash
# Clone frontend
git clone <repo>
cd pili-frontend

# Install dependencies
npm install

# Setup environment
cp .env.example .env.local
# Edit with contract addresses and RPC URLs

# Run development server
npm run dev
```

---

## Appendix B: Testing Checklist

### Smart Contract Tests

- [ ] IL calculation accuracy (5 test cases)
- [ ] Position creation and storage
- [ ] afterSwap hook execution
- [ ] Withdrawal logic
- [ ] Edge cases (zero amounts, extreme prices)
- [ ] Gas consumption (<200k per operation)
- [ ] Multiple concurrent positions

### FHE Tests

- [ ] Threshold encryption
- [ ] Comparison operations (>, <, ==)
- [ ] Client-side encryption flow
- [ ] Round-trip encryption/decryption
- [ ] Invalid input handling
- [ ] Gas costs for FHE operations

### Frontend Tests

- [ ] Wallet connection
- [ ] Form validation
- [ ] Transaction submission
- [ ] Position display
- [ ] IL calculation display
- [ ] Responsive design (mobile/desktop)
- [ ] Error handling

### Integration Tests

- [ ] End-to-end add liquidity flow
- [ ] Encryption → storage → retrieval
- [ ] IL monitoring updates
- [ ] Auto-exit trigger
- [ ] Event emission and display

---

## Appendix C: Submission Checklist

### Code

- [ ] Smart contracts deployed to testnet
- [ ] Frontend deployed and accessible
- [ ] All repositories public on GitHub
- [ ] README files complete
- [ ] Code commented and documented
- [ ] Tests passing (>90% coverage)

### Documentation

- [ ] Technical architecture document
- [ ] API documentation
- [ ] Setup instructions
- [ ] User guide
- [ ] Video demo (2-3 minutes)

### Demo

- [ ] Live demo link working
- [ ] Demo video recorded and uploaded
- [ ] Presentation slides ready
- [ ] Test accounts funded
- [ ] Backup screenshots/recordings

### Submission Form

- [ ] Team information
- [ ] Project description
- [ ] GitHub links
- [ ] Demo video link
- [ ] Live demo link
- [ ] Technical documentation link

---

**Document Version:** 1.0
**Last Updated:** December 1, 2025
**Status:** Ready for Implementation ✅

**Good luck team! Let's build something amazing! 🚀**
