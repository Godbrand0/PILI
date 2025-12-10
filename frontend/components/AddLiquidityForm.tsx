'use client';

import { useState, useEffect } from 'react';
import { useAccount, useBalance } from 'wagmi';
import { formatEther, etherToWei } from '../lib/utils';
import { useFHEUtils } from '../utils/fheUtils';
import { Button } from './ui/Button';
import { useILProtectionWrite } from '../hooks/useILProtectionHook';
import { getTokenConfig } from '../config/contracts';

interface AddLiquidityFormProps {
  onSuccess?: () => void;
}

/**
 * Form for adding liquidity with IL protection
 */
export function AddLiquidityForm({ onSuccess }: AddLiquidityFormProps) {
  const { address, isConnected } = useAccount();
  const { data: wethBalance } = useBalance({ 
    address: getTokenConfig(8008135, 'WETH')?.address,
    token: 'native' 
  });
  const { data: usdcBalance } = useBalance({ 
    address: getTokenConfig(8008135, 'USDC')?.address 
  });

  const { provider } = useAccount();
  const fheUtils = useFHEUtils(provider);

  // Form state
  const [token0Amount, setToken0Amount] = useState('');
  const [token1Amount, setToken1Amount] = useState('');
  const [ilThreshold, setIlThreshold] = useState('5.0'); // Default 5%
  const [isEncrypting, setIsEncrypting] = useState(false);
  const [encryptedThreshold, setEncryptedThreshold] = useState<string | null>(null);

  const { writeContract, isPending, isConfirmed, error } = useILProtectionWrite();

  // Validate form
  const isValid = 
    isConnected &&
    token0Amount && 
    token1Amount && 
    ilThreshold &&
    Number(token0Amount) > 0 &&
    Number(token1Amount) > 0 &&
    Number(ilThreshold) >= 0 &&
    Number(ilThreshold) <= 100;

  // Encrypt IL threshold when it changes
  useEffect(() => {
    if (!fheUtils || !ilThreshold) return;

    const encryptThreshold = async () => {
      try {
        setIsEncrypting(true);
        const threshold = Number(ilThreshold);
        if (fheUtils.validateThreshold(threshold)) {
          const encrypted = await fheUtils.encryptILThreshold(threshold);
          setEncryptedThreshold(fheUtils.encodeHookData(encrypted));
        }
      } catch (error) {
        console.error('Failed to encrypt IL threshold:', error);
      } finally {
        setIsEncrypting(false);
      }
    };

    encryptThreshold();
  }, [ilThreshold, fheUtils]);

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!isValid || !encryptedThreshold) return;

    try {
      const amount0 = etherToWei(token0Amount);
      const amount1 = etherToWei(token1Amount);

      // This would integrate with Uniswap v4 hook system
      // For now, we'll simulate the transaction
      await writeContract({
        functionName: 'addLiquidity', // This would be the actual function name
        args: [
          amount0,
          amount1,
          encryptedThreshold, // Hook data with encrypted IL threshold
        ],
      });

      if (isConfirmed) {
        onSuccess?.();
        // Reset form
        setToken0Amount('');
        setToken1Amount('');
        setIlThreshold('5.0');
        setEncryptedThreshold(null);
      }
    } catch (error) {
      console.error('Failed to add liquidity:', error);
    }
  };

  if (!isConnected) {
    return (
      <div className="rounded-lg border p-6 text-center">
        <p className="text-muted-foreground">
          Please connect your wallet to add liquidity
        </p>
      </div>
    );
  }

  return (
    <div className="rounded-lg border p-6 space-y-6">
      <div>
        <h2 className="text-2xl font-bold mb-4">Add Liquidity with IL Protection</h2>
        <p className="text-muted-foreground mb-6">
          Provide liquidity to Uniswap v4 pools with privacy-preserving impermanent loss protection.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Token Selection */}
        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2">
            <label className="text-sm font-medium">WETH Amount</label>
            <input
              type="number"
              step="0.001"
              placeholder="0.0"
              value={token0Amount}
              onChange={(e) => setToken0Amount(e.target.value)}
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              disabled={!isConnected}
            />
            <p className="text-xs text-muted-foreground">
              Balance: {wethBalance ? formatEther(wethBalance.value) : '0'} WETH
            </p>
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium">USDC Amount</label>
            <input
              type="number"
              step="0.01"
              placeholder="0.0"
              value={token1Amount}
              onChange={(e) => setToken1Amount(e.target.value)}
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              disabled={!isConnected}
            />
            <p className="text-xs text-muted-foreground">
              Balance: {usdcBalance ? formatEther(usdcBalance.value) : '0'} USDC
            </p>
          </div>
        </div>

        {/* IL Threshold */}
        <div className="space-y-2">
          <label className="text-sm font-medium">
            IL Protection Threshold (%)
          </label>
          <div className="flex gap-2">
            <input
              type="number"
              min="0"
              max="100"
              step="0.1"
              placeholder="5.0"
              value={ilThreshold}
              onChange={(e) => setIlThreshold(e.target.value)}
              className="flex-1 rounded-md border border-input bg-background px-3 py-2 text-sm"
              disabled={!isConnected}
            />
            <span className="text-sm text-muted-foreground">%</span>
          </div>
          <p className="text-xs text-muted-foreground">
            Position will be automatically withdrawn if impermanent loss exceeds this threshold.
          </p>
          {isEncrypting && (
            <p className="text-xs text-blue-600">
              Encrypting threshold with FHE...
            </p>
          )}
        </div>

        {/* Gas Estimate */}
        {fheUtils && (
          <div className="rounded-md bg-muted p-3">
            <p className="text-sm">
              <strong>Estimated Gas Cost:</strong>{' '}
              {fheUtils.estimateFHEGasCosts().total.toLocaleString()} gas
            </p>
            <p className="text-xs text-muted-foreground">
              Includes FHE encryption and comparison operations
            </p>
          </div>
        )}

        {/* Submit Button */}
        <Button
          type="submit"
          className="w-full"
          disabled={!isValid || isPending || !encryptedThreshold}
        >
          {isPending ? 'Adding Liquidity...' : 'Add Liquidity with Protection'}
        </Button>

        {/* Error Display */}
        {error && (
          <div className="rounded-md bg-destructive/10 p-3 mt-4">
            <p className="text-sm text-destructive">
              Error: {error.message}
            </p>
          </div>
        )}

        {/* Success Message */}
        {isConfirmed && (
          <div className="rounded-md bg-green-50 p-3 mt-4">
            <p className="text-sm text-green-800">
              ✅ Liquidity added successfully with IL protection!
            </p>
          </div>
        )}
      </form>
    </div>
  );
}