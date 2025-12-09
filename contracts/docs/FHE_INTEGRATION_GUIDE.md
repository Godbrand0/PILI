# FHE Integration Guide for PILI

## Overview
This guide explains how to integrate Fully Homomorphic Encryption (FHE) using Fhenix into the PILI IL Protection system.

## Key Concepts

### Data Types
- `euint32`: Encrypted 32-bit uint (IL thresholds in basis points)
- `euint256`: Encrypted 256-bit uint (prices)
- `ebool`: Encrypted boolean (comparison results)

### Core Operations
```solidity
euint32 encrypted = FHE.asEuint32(500); // Encrypt
ebool result = FHE.gt(encryptedA, encryptedB); // Compare
bool plainResult = FHE.decrypt(result); // Decrypt (minimize!)
```

### Gas Costs
- Encryption: ~50,000 gas
- Comparison: ~100,000 gas  
- Decryption: ~20,000 gas
- **Total**: ~170,000 gas (baseline), ~50,000 gas (with P0)

## Approach 1: Minimal Decryption (Recommended)
```solidity
uint256 currentIL = calculateIL(entryPrice, currentPrice);
euint32 encryptedIL = FHE.asEuint32(uint32(currentIL));
ebool shouldExit = FHE.gt(encryptedIL, threshold);
bool exit = FHE.decrypt(shouldExit); // Only decrypt boolean
```

**Privacy**: 90/100 | **UX**: Excellent | **Gas**: 50k (with P0)

## Client-Side Encryption
```typescript
import { FhenixClient } from 'fhenixjs';
const client = new FhenixClient({ provider });
const encrypted = await client.encrypt_uint32(500); // 5%
```

## Security Best Practices
✅ Never decrypt threshold values
✅ Encrypt before network transmission  
✅ Don't emit encrypted values in events
❌ Never log plaintext thresholds

See full guide in contracts/docs/
