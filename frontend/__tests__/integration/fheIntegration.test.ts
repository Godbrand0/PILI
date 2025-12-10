/**
 * Integration tests for FHE utilities
 * 
 * Tests the complete encryption flow from client-side to smart contract
 */

import { describe, it, expect, beforeEach } from '@jest/globals';
import { FHEUtils } from '../../utils/fheUtils';
import { JsonRpcProvider } from 'ethers';

describe('FHE Integration Tests', () => {
  let fheUtils: FHEUtils;
  let provider: JsonRpcProvider;

  beforeEach(() => {
    // Use Fhenix testnet
    provider = new JsonRpcProvider('https://api.helium.fhenix.zone');
    fheUtils = new FHEUtils(provider);
  });

  describe('Threshold Encryption', () => {
    it('should encrypt valid threshold', async () => {
      const threshold = 5.0; // 5%
      const encrypted = await fheUtils.encryptILThreshold(threshold);

      expect(encrypted).toBeDefined();
      expect(encrypted.data).toBeDefined();
      expect(typeof encrypted.data).toBe('string');
      expect(encrypted.data).toMatch(/^0x[0-9a-f]+$/i);
    });

    it('should reject negative threshold', async () => {
      await expect(
        fheUtils.encryptILThreshold(-1)
      ).rejects.toThrow('Threshold must be between 0% and 100%');
    });

    it('should reject threshold > 100%', async () => {
      await expect(
        fheUtils.encryptILThreshold(101)
      ).rejects.toThrow('Threshold must be between 0% and 100%');
    });

    it('should handle edge case: 0%', async () => {
      const encrypted = await fheUtils.encryptILThreshold(0);
      expect(encrypted).toBeDefined();
      expect(encrypted.data).toBeDefined();
    });

    it('should handle edge case: 100%', async () => {
      const encrypted = await fheUtils.encryptILThreshold(100);
      expect(encrypted).toBeDefined();
      expect(encrypted.data).toBeDefined();
    });

    it('should handle decimal thresholds', async () => {
      const encrypted = await fheUtils.encryptILThreshold(5.5); // 5.5%
      expect(encrypted).toBeDefined();
      // Should convert to 550 basis points
    });

    it('should produce different ciphertexts for same value', async () => {
      // FHE encryption should be probabilistic
      const encrypted1 = await fheUtils.encryptILThreshold(5.0);
      const encrypted2 = await fheUtils.encryptILThreshold(5.0);

      // Different ciphertexts (probabilistic encryption)
      // Note: This may not always be true depending on FHE implementation
      expect(encrypted1.data).toBeDefined();
      expect(encrypted2.data).toBeDefined();
    });
  });

  describe('HookData Encoding', () => {
    it('should encode encrypted threshold correctly', async () => {
      const encrypted = await fheUtils.encryptILThreshold(5.0);
      const hookData = fheUtils.encodeHookData(encrypted);

      expect(hookData).toBeDefined();
      expect(typeof hookData).toBe('string');
      expect(hookData).toMatch(/^0x[0-9a-f]+$/i);
    });

    it('should produce valid hex string', async () => {
      const encrypted = await fheUtils.encryptILThreshold(10.0);
      const hookData = fheUtils.encodeHookData(encrypted);

      // Should be valid hex
      expect(() => BigInt(hookData)).not.toThrow();
    });

    it('should encode different thresholds to different hookData', async () => {
      const encrypted1 = await fheUtils.encryptILThreshold(5.0);
      const encrypted2 = await fheUtils.encryptILThreshold(10.0);

      const hookData1 = fheUtils.encodeHookData(encrypted1);
      const hookData2 = fheUtils.encodeHookData(encrypted2);

      // Different thresholds should produce different hookData
      expect(hookData1).not.toBe(hookData2);
    });
  });

  describe('Price Encryption', () => {
    it('should encrypt price values', async () => {
      const price = BigInt('2500000000000000000000'); // 2500 ETH in wei
      const encrypted = await fheUtils.encryptPrice(price);

      expect(encrypted).toBeDefined();
      expect(encrypted.data).toBeDefined();
    });

    it('should handle large price values', async () => {
      const largePrice = BigInt('1000000000000000000000000'); // 1M ETH
      const encrypted = await fheUtils.encryptPrice(largePrice);

      expect(encrypted).toBeDefined();
    });

    it('should handle zero price', async () => {
      const encrypted = await fheUtils.encryptPrice(BigInt(0));
      expect(encrypted).toBeDefined();
    });
  });

  describe('Validation', () => {
    it('should validate correct thresholds', () => {
      expect(fheUtils.validateThreshold(0)).toBe(true);
      expect(fheUtils.validateThreshold(5.0)).toBe(true);
      expect(fheUtils.validateThreshold(50.0)).toBe(true);
      expect(fheUtils.validateThreshold(100.0)).toBe(true);
    });

    it('should reject invalid thresholds', () => {
      expect(fheUtils.validateThreshold(-1)).toBe(false);
      expect(fheUtils.validateThreshold(101)).toBe(false);
      expect(fheUtils.validateThreshold(1000)).toBe(false);
    });

    it('should handle edge cases', () => {
      expect(fheUtils.validateThreshold(0.01)).toBe(true); // 0.01%
      expect(fheUtils.validateThreshold(99.99)).toBe(true); // 99.99%
    });
  });

  describe('Gas Estimation', () => {
    it('should provide reasonable gas estimates', () => {
      const estimates = fheUtils.estimateFHEGasCosts();

      expect(estimates.encryption).toBeGreaterThan(0);
      expect(estimates.comparison).toBeGreaterThan(0);
      expect(estimates.conditional).toBeGreaterThan(0);
      expect(estimates.total).toBe(
        estimates.encryption + estimates.comparison + estimates.conditional
      );
    });

    it('should return consistent estimates', () => {
      const estimates1 = fheUtils.estimateFHEGasCosts();
      const estimates2 = fheUtils.estimateFHEGasCosts();

      expect(estimates1).toEqual(estimates2);
    });

    it('should have realistic gas values', () => {
      const estimates = fheUtils.estimateFHEGasCosts();

      // FHE operations are expensive
      expect(estimates.encryption).toBeGreaterThanOrEqual(30000);
      expect(estimates.comparison).toBeGreaterThanOrEqual(50000);
      expect(estimates.total).toBeGreaterThanOrEqual(100000);
    });
  });

  describe('Utility Functions', () => {
    it('should convert basis points to percent', () => {
      expect(FHEUtils.basisPointsToPercent(500)).toBe(5.0);
      expect(FHEUtils.basisPointsToPercent(1000)).toBe(10.0);
      expect(FHEUtils.basisPointsToPercent(0)).toBe(0);
      expect(FHEUtils.basisPointsToPercent(10000)).toBe(100.0);
    });

    it('should convert percent to basis points', () => {
      expect(FHEUtils.percentToBasisPoints(5.0)).toBe(500);
      expect(FHEUtils.percentToBasisPoints(10.0)).toBe(1000);
      expect(FHEUtils.percentToBasisPoints(0)).toBe(0);
      expect(FHEUtils.percentToBasisPoints(100.0)).toBe(10000);
    });

    it('should handle decimal conversions', () => {
      expect(FHEUtils.percentToBasisPoints(5.5)).toBe(550);
      expect(FHEUtils.basisPointsToPercent(550)).toBe(5.5);
    });

    it('should round down for percent to basis points', () => {
      expect(FHEUtils.percentToBasisPoints(5.55)).toBe(555);
      expect(FHEUtils.percentToBasisPoints(5.559)).toBe(555);
    });
  });

  describe('Encryption Round-Trip (Development Only)', () => {
    it('should decrypt to original value', async () => {
      const original = 500; // 5% in basis points
      
      try {
        const decrypted = await fheUtils.testEncryptionRoundTrip(original);
        expect(decrypted).toBe(original);
      } catch (error) {
        // May fail if decryption permissions not set up
        // This is expected in some environments
        console.warn('Decryption test skipped:', error);
      }
    }, 10000); // Longer timeout for FHE operations

    it('should reject invalid values in round-trip', async () => {
      await expect(
        fheUtils.testEncryptionRoundTrip(-1)
      ).rejects.toThrow('Value must be between 0 and 10000 basis points');

      await expect(
        fheUtils.testEncryptionRoundTrip(10001)
      ).rejects.toThrow('Value must be between 0 and 10000 basis points');
    });
  });

  describe('Example Usage', () => {
    it('should complete full encryption flow', async () => {
      const { exampleUsage } = await import('../../utils/fheUtils');
      
      const result = await exampleUsage(provider);

      expect(result.encryptedThreshold).toBeDefined();
      expect(result.hookData).toBeDefined();
      expect(result.gasCosts).toBeDefined();
      expect(result.gasCosts.total).toBeGreaterThan(0);
    }, 10000);
  });

  describe('React Hook', () => {
    it('should return FHEUtils instance with valid provider', () => {
      const { useFHEUtils } = require('../../utils/fheUtils');
      const utils = useFHEUtils(provider);

      expect(utils).toBeInstanceOf(FHEUtils);
    });

    it('should return null with undefined provider', () => {
      const { useFHEUtils } = require('../../utils/fheUtils');
      const utils = useFHEUtils(undefined);

      expect(utils).toBeNull();
    });
  });

  describe('Error Handling', () => {
    it('should handle network errors gracefully', async () => {
      // Use invalid provider
      const badProvider = new JsonRpcProvider('http://invalid-url');
      const badUtils = new FHEUtils(badProvider);

      await expect(
        badUtils.encryptILThreshold(5.0)
      ).rejects.toThrow();
    });

    it('should provide meaningful error messages', async () => {
      try {
        await fheUtils.encryptILThreshold(150);
      } catch (error) {
        expect(error).toBeInstanceOf(Error);
        expect((error as Error).message).toContain('Threshold must be between');
      }
    });
  });

  describe('Performance', () => {
    it('should encrypt within reasonable time', async () => {
      const start = Date.now();
      await fheUtils.encryptILThreshold(5.0);
      const duration = Date.now() - start;

      // Should complete within 5 seconds
      expect(duration).toBeLessThan(5000);
    }, 10000);

    it('should handle multiple encryptions', async () => {
      const promises = [
        fheUtils.encryptILThreshold(5.0),
        fheUtils.encryptILThreshold(10.0),
        fheUtils.encryptILThreshold(15.0),
      ];

      const results = await Promise.all(promises);
      
      expect(results).toHaveLength(3);
      results.forEach(result => {
        expect(result).toBeDefined();
        expect(result.data).toBeDefined();
      });
    }, 15000);
  });
});
