'use client';

import { useAccount } from 'wagmi';
import { useILProtectionHook } from '../../hooks/useILProtectionHook';
import { PositionCard, PositionCardSkeleton } from '../../components/PositionCard';
import { Button } from '../../components/ui/Button';
import Link from 'next/link';

export default function PositionsPage() {
  const { address, isConnected } = useAccount();
  const { positions, totalPositions, activePositions, totalDeposited } = useILProtectionHook(address);

  if (!isConnected) {
    return (
      <div className="text-center space-y-4">
        <h1 className="text-3xl font-bold">My Positions</h1>
        <p className="text-muted-foreground">
          Connect your wallet to view your liquidity positions
        </p>
        <Link href="/">
          <Button>Connect Wallet</Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold">My Positions</h1>
        <div className="text-sm text-muted-foreground">
          {totalPositions} total positions ({activePositions} active)
        </div>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-3">
        <div className="rounded-lg border p-6">
          <h3 className="text-lg font-semibold">Total Deposited</h3>
          <p className="text-2xl font-bold">
            {totalDeposited.toString()} ETH
          </p>
        </div>
        <div className="rounded-lg border p-6">
          <h3 className="text-lg font-semibold">Active Positions</h3>
          <p className="text-2xl font-bold">
            {activePositions}
          </p>
        </div>
        <div className="rounded-lg border p-6">
          <h3 className="text-lg font-semibold">Inactive Positions</h3>
          <p className="text-2xl font-bold">
            {totalPositions - activePositions}
          </p>
        </div>
      </div>

      {/* Positions List */}
      <div className="space-y-4">
        {positions.length === 0 ? (
          <div className="rounded-lg border p-8 text-center">
            <h3 className="text-lg font-semibold mb-2">No Positions Found</h3>
            <p className="text-muted-foreground mb-4">
              You haven't created any liquidity positions with IL protection yet.
            </p>
            <Link href="/add-liquidity">
              <Button>Create Your First Position</Button>
            </Link>
          </div>
        ) : (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {positions.map((position) => (
              <PositionCard
                key={position.positionId.toString()}
                position={position}
                onWithdraw={(positionId) => {
                  // Handle withdrawal logic here
                  console.log('Withdraw position:', positionId);
                }}
              />
            ))}
          </div>
        )}
      </div>

      {/* Loading State */}
      {positions.length === 0 && (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {[...Array(6)].map((_, index) => (
            <PositionCardSkeleton key={index} />
          ))}
        </div>
      )}
    </div>
  );
}