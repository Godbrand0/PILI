'use client';

import { useAccount } from 'wagmi';
import { AddLiquidityForm } from '../../components/AddLiquidityForm';
import { Button } from '../../components/ui/Button';
import Link from 'next/link';

export default function AddLiquidityPage() {
  const { isConnected } = useAccount();

  if (!isConnected) {
    return (
      <div className="text-center space-y-4">
        <h1 className="text-3xl font-bold">Add Liquidity with IL Protection</h1>
        <p className="text-muted-foreground">
          Connect your wallet to create a new liquidity position with impermanent loss protection
        </p>
        <Link href="/">
          <Button>Connect Wallet</Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto space-y-8">
      <div className="text-center space-y-2">
        <h1 className="text-3xl font-bold">Add Liquidity with IL Protection</h1>
        <p className="text-muted-foreground">
          Create a new liquidity position with automated impermanent loss protection using FHE
        </p>
      </div>

      <AddLiquidityForm />

      <div className="rounded-lg border p-6 bg-muted/50">
        <h3 className="text-lg font-semibold mb-3">How IL Protection Works</h3>
        <ul className="space-y-2 text-sm text-muted-foreground">
          <li>• Set your impermanent loss threshold (e.g., 5%)</li>
          <li>• Your threshold is encrypted using Fully Homomorphic Encryption</li>
          <li>• The system monitors your position in real-time</li>
          <li>• When IL exceeds your threshold, your position is automatically withdrawn</li>
          <li>• Your privacy is maintained throughout the process</li>
        </ul>
      </div>
    </div>
  );
}