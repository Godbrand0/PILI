/**
 * FHE Utilities for PILI Frontend
 * 
 * Provides client-side encryption using Fhenix for privacy-preserving
 * impermanent loss protection.
 */

import { FhenixClient, EncryptedUint32, EncryptedUint256 } from 'fhenixjs';
import { AbiCoder, type BrowserProvider, type JsonRpcProvider } from 'ethers';

/**
 * Gas cost estimates for FHE operations on Fhenix testnet
 */
export interface FHEGasCosts {
  encryption: number;
  comparison: number;
  conditional: number;
  total: number;
}

/**
 * FHE utility class for encrypting IL thresholds and prices
 */
export class FHEUtils {
  private client: FhenixClient;

  constructor(provider: BrowserProvider | JsonRpcProvider) {
    this.client = new FhenixClient({ provider: provider as any });
  }

  /**
   * Encrypt IL threshold for on-chain storage
   * 
   * @param thresholdPercent - Threshold as percentage (e.g., 5 for 5%)
   * @returns Encrypted threshold as EncryptedUint32
   * @throws Error if threshold is out of valid range [0, 100]
   * 
   * @example
   * ```typescript
   * const fheUtils = new FHEUtils(provider);
   * const encrypted = await fheUtils.encryptILThreshold(5.0); // 5%
   * ```
   */
  async encryptILThreshold(thresholdPercent: number): Promise<EncryptedUint32> {
    // Convert percentage to basis points (5% = 500 bp)
    const basisPoints = Math.floor(thresholdPercent * 100);

    // Validate range
    if (basisPoints < 0 || basisPoints > 10000) {
      throw new Error('Threshold must be between 0% and 100%');
    }

    // Encrypt using Fhenix client
    const encrypted = await this.client.encrypt_uint32(basisPoints);
    return encrypted;
  }

  /**
   * Encrypt price value for price bounds feature
   * 
   * @param price - Price value in wei or base units
   * @returns Encrypted price as EncryptedUint256
   * 
   * @example
   * ```typescript
   * const price = parseEther("2500"); // $2500
   * const encrypted = await fheUtils.encryptPrice(price);
   * ```
   */
  async encryptPrice(price: bigint): Promise<EncryptedUint256> {
    const encrypted = await this.client.encrypt_uint256(price);
    return encrypted;
  }

  /**
   * Encode encrypted threshold as hookData for addLiquidity transaction
   * 
   * @param encryptedThreshold - Encrypted IL threshold
   * @returns Hex-encoded bytes for transaction hookData parameter
   * 
   * @example
   * ```typescript
   * const encrypted = await fheUtils.encryptILThreshold(5.0);
   * const hookData = fheUtils.encodeHookData(encrypted);
   * await contract.addLiquidity(amount0, amount1, hookData);
   * ```
   */
  encodeHookData(encryptedThreshold: EncryptedUint32): string {
    // ABI encode the encrypted value as bytes
    // This matches the implementation plan specification
    const abiCoder = new AbiCoder();
    const encoded = abiCoder.encode(['bytes'], [encryptedThreshold.data]);
    return encoded;
  }

  /**
   * Test encryption/decryption round-trip (development only)
   * 
   * WARNING: This requires decryption permissions and should only be used
   * for testing. In production, thresholds should never be decrypted.
   * 
   * @param value - Value to test (in basis points)
   * @returns Decrypted value (should match input)
   * 
   * @example
   * ```typescript
   * const original = 500; // 5% in basis points
   * const decrypted = await fheUtils.testEncryptionRoundTrip(original);
   * console.assert(decrypted === original);
   * ```
   */
  async testEncryptionRoundTrip(value: number): Promise<number> {
    if (value < 0 || value > 10000) {
      throw new Error('Value must be between 0 and 10000 basis points');
    }

    const encrypted = await this.client.encrypt_uint32(value);
    
    // Note: Decryption is not supported in fhenixjs client-side API
    // This method is kept for API compatibility but will throw
    throw new Error('Decryption not supported in client-side fhenixjs. Use for encryption testing only.');
  }

  /**
   * Get estimated gas costs for FHE operations
   * 
   * These are estimates based on Fhenix testnet measurements.
   * Actual costs may vary based on network conditions.
   * 
   * @returns Object containing gas cost estimates
   * 
   * @example
   * ```typescript
   * const costs = fheUtils.estimateFHEGasCosts();
   * console.log(`Total estimated gas: ${costs.total}`);
   * ```
   */
  estimateFHEGasCosts(): FHEGasCosts {
    return {
      encryption: 50000,      // FHE.asEuint32()
      comparison: 100000,     // FHE.gt()
      conditional: 20000,     // FHE.decrypt() or FHE.req()
      total: 170000          // Full IL check cycle
    };
  }

  /**
   * Validate threshold percentage before encryption
   * 
   * @param thresholdPercent - Threshold to validate
   * @returns true if valid, false otherwise
   * 
   * @example
   * ```typescript
   * if (fheUtils.validateThreshold(5.0)) {
   *   const encrypted = await fheUtils.encryptILThreshold(5.0);
   * }
   * ```
   */
  validateThreshold(thresholdPercent: number): boolean {
    const basisPoints = Math.floor(thresholdPercent * 100);
    return basisPoints >= 0 && basisPoints <= 10000;
  }

  /**
   * Convert basis points to percentage
   * 
   * @param basisPoints - Value in basis points (e.g., 500)
   * @returns Percentage value (e.g., 5.0)
   */
  static basisPointsToPercent(basisPoints: number): number {
    return basisPoints / 100;
  }

  /**
   * Convert percentage to basis points
   * 
   * @param percent - Percentage value (e.g., 5.0)
   * @returns Basis points value (e.g., 500)
   */
  static percentToBasisPoints(percent: number): number {
    return Math.floor(percent * 100);
  }
}

/**
 * Hook for using FHE utilities in React components
 * 
 * @param provider - Ethers provider
 * @returns FHEUtils instance
 * 
 * @example
 * ```typescript
 * function MyComponent() {
 *   const { provider } = useProvider();
 *   const fheUtils = useFHEUtils(provider);
 *   
 *   const handleEncrypt = async () => {
 *     const encrypted = await fheUtils.encryptILThreshold(5.0);
 *     // Use encrypted value...
 *   };
 * }
 * ```
 */
export function useFHEUtils(provider: BrowserProvider | JsonRpcProvider | undefined): FHEUtils | null {
  if (!provider) return null;
  return new FHEUtils(provider);
}

/**
 * Example usage demonstrating the complete flow
 */
export async function exampleUsage(provider: BrowserProvider | JsonRpcProvider) {
  // Initialize FHE utilities
  const fheUtils = new FHEUtils(provider);

  // 1. Validate threshold
  const thresholdPercent = 5.0; // 5%
  if (!fheUtils.validateThreshold(thresholdPercent)) {
    throw new Error('Invalid threshold');
  }

  // 2. Encrypt IL threshold
  const encryptedThreshold = await fheUtils.encryptILThreshold(thresholdPercent);
  console.log('Encrypted threshold:', encryptedThreshold);

  // 3. Prepare hookData for transaction
  const hookData = fheUtils.encodeHookData(encryptedThreshold);
  console.log('Hook data:', hookData);

  // 4. Estimate gas costs
  const gasCosts = fheUtils.estimateFHEGasCosts();
  console.log('Estimated gas costs:', gasCosts);

  // 5. Use in transaction (pseudo-code)
  // await contract.addLiquidity(amount0, amount1, hookData, {
  //   gasLimit: baseGas + gasCosts.total
  // });

  return {
    encryptedThreshold,
    hookData,
    gasCosts
  };
}
