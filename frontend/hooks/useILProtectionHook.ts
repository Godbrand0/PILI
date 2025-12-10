'use client';

import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther } from 'ethers';
import { getContractConfig } from '../config/contracts';
import { ILProtectionHookABI } from '../abis/ILProtectionHook.json';
import { useMemo } from 'react';

/**
 * Position data structure
 */
export interface Position {
  positionId: bigint;
  lpAddress: string;
  entryPrice: bigint;
  token0Amount: bigint;
  token1Amount: bigint;
  depositTimestamp: bigint;
  isActive: boolean;
}

/**
 * Hook for reading IL Protection Hook contract data
 */
export function useILProtectionHook(address?: `0x${string}`) {
  const contractConfig = useMemo(() => {
    if (!address) return undefined;
    return getContractConfig(8008135, 'ILProtectionHook'); // Fhenix Helix
  }, [address]);

  // Read contract data
  const { data: nextPositionId } = useReadContract({
    ...contractConfig,
    functionName: 'nextPositionId',
    query: {
      enabled: !!contractConfig,
    },
  });

  const { data: totalProtectedLiquidity } = useReadContract({
    ...contractConfig,
    functionName: 'totalProtectedLiquidity',
    query: {
      enabled: !!contractConfig,
    },
  });

  const { data: paused } = useReadContract({
    ...contractConfig,
    functionName: 'paused',
    query: {
      enabled: !!contractConfig,
    },
  });

  // Get user positions
  const { data: userPositionIds } = useReadContract({
    ...contractConfig,
    functionName: 'getUserPositions',
    args: address ? [address] : undefined,
    query: {
      enabled: !!contractConfig && !!address,
    },
  });

  // Get position details for each user position
  const positions = useMemo(() => {
    if (!userPositionIds || !contractConfig) return [];
    
    return userPositionIds.map((positionId: bigint) => {
      // We'll need to make individual calls for each position
      // This is a simplified version - in production, you'd want to batch these
      return {
        positionId,
        lpAddress: address || '',
        entryPrice: 0n,
        token0Amount: 0n,
        token1Amount: 0n,
        depositTimestamp: 0n,
        isActive: false,
      } as Position;
    });
  }, [userPositionIds, address, contractConfig]);

  return {
    // Contract info
    contract: contractConfig,
    nextPositionId,
    totalProtectedLiquidity,
    paused,
    
    // User positions
    userPositionIds,
    positions,
    
    // Computed values
    totalPositions: positions.length,
    activePositions: positions.filter(p => p.isActive),
    totalDeposited: positions.reduce((sum, p) => sum + p.token0Amount + p.token1Amount, 0n),
  };
}

/**
 * Hook for writing to IL Protection Hook contract
 */
export function useILProtectionWrite() {
  const contractConfig = getContractConfig(8008135, 'ILProtectionHook'); // Fhenix Helix

  const { data: hash, writeContract, isPending, error } = useWriteContract({
    ...contractConfig,
  });

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    writeContract,
    isPending,
    isConfirming,
    isConfirmed,
    error,
    hash,
  };
}

/**
 * Hook for getting a specific position
 */
export function usePosition(positionId?: bigint) {
  const contractConfig = getContractConfig(8008135, 'ILProtectionHook'); // Fhenix Helix

  const { data: position } = useReadContract({
    ...contractConfig,
    functionName: 'getPosition',
    args: positionId ? [0n, positionId] : undefined, // poolId would be calculated based on the pool
    query: {
      enabled: !!contractConfig && !!positionId,
    },
  });

  return position;
}

/**
 * Hook for getting active positions in a pool
 */
export function useActivePositions(poolId?: string) {
  const contractConfig = getContractConfig(8008135, 'ILProtectionHook'); // Fhenix Helix

  const { data: activePositionIds } = useReadContract({
    ...contractConfig,
    functionName: 'getActivePositions',
    args: poolId ? [poolId as `0x${string}`] : undefined,
    query: {
      enabled: !!contractConfig && !!poolId,
    },
  });

  return activePositionIds;
}

/**
 * Helper function to format position data
 */
export function formatPosition(position: any): Position {
  return {
    positionId: position.positionId || 0n,
    lpAddress: position.lpAddress || '',
    entryPrice: position.entryPrice || 0n,
    token0Amount: position.token0Amount || 0n,
    token1Amount: position.token1Amount || 0n,
    depositTimestamp: position.depositTimestamp || 0n,
    isActive: position.isActive || false,
  };
}

/**
 * Helper function to calculate position value
 */
export function calculatePositionValue(position: Position, token0Price: bigint, token1Price: bigint): bigint {
  const token0Value = (position.token0Amount * token0Price) / BigInt(10 ** 18);
  const token1Value = (position.token1Amount * token1Price) / BigInt(10 ** 18);
  return token0Value + token1Value;
}

/**
 * Helper function to calculate impermanent loss
 */
export function calculateImpermanentLossForPosition(
  position: Position,
  currentToken0Price: bigint,
  currentToken1Price: bigint
): number {
  // This is a simplified calculation
  // In production, you'd use the actual Uniswap v4 math
  const entryValue = Number(formatEther(position.entryPrice));
  const currentValue = Number(formatEther(currentToken0Price));
  
  if (entryValue === 0) return 0;
  
  return ((currentValue - entryValue) / entryValue) * 100;
}