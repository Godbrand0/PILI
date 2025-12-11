"use client";

import {
  formatEther,
  formatDate,
  formatDuration,
  calculateImpermanentLoss,
} from "../lib/utils";
import {
  Position,
  calculatePositionValue,
  calculateImpermanentLossForPosition,
} from "../hooks/useILProtectionHook";
import { Button } from "./ui/Button";

interface PositionCardProps {
  position: Position;
  currentSqrtPriceX96?: bigint;
  onWithdraw?: (positionId: bigint) => void;
}

/**
 * Card component for displaying a liquidity position
 */
export function PositionCard({
  position,
  currentSqrtPriceX96 = BigInt(0),
  onWithdraw,
}: PositionCardProps) {
  // For position value calculation, we need regular prices
  // Convert sqrtPriceX96 to regular price for display
  const currentPrice = currentSqrtPriceX96 > 0
    ? BigInt(Math.floor((Number(currentSqrtPriceX96) ** 2 / (2 ** 192)))
    : BigInt(0);
  
  const positionValue = calculatePositionValue(
    position,
    currentPrice,
    currentPrice // Using same price for both tokens for simplicity
  );
  const impermanentLoss = calculateImpermanentLossForPosition(
    position,
    currentSqrtPriceX96
  );

  const handleWithdraw = () => {
    if (onWithdraw) {
      onWithdraw(position.positionId);
    }
  };

  return (
    <div className="rounded-lg border p-6 space-y-4">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h3 className="text-lg font-semibold">
            Position #{position.positionId.toString()}
          </h3>
          <p className="text-sm text-muted-foreground">
            Created: {formatDate(Number(position.depositTimestamp))}
          </p>
        </div>
        <div
          className={`px-2 py-1 rounded-full text-xs font-medium ${
            position.isActive
              ? "bg-green-100 text-green-800"
              : "bg-gray-100 text-gray-800"
          }`}
        >
          {position.isActive ? "Active" : "Inactive"}
        </div>
      </div>

      {/* Position Details */}
      <div className="grid gap-4 md:grid-cols-2">
        <div className="space-y-2">
          <p className="text-sm font-medium">Token0 Amount</p>
          <p className="text-lg font-semibold">
            {position.token0Amount.toString()} ETH
          </p>
        </div>
        <div className="space-y-2">
          <p className="text-sm font-medium">Token1 Amount</p>
          <p className="text-lg font-semibold">
            {position.token1Amount.toString()} USDC
          </p>
        </div>
      </div>

      {/* Entry Price */}
      <div className="space-y-2">
        <p className="text-sm font-medium">Entry Price</p>
        <p className="text-lg font-semibold">
          {position.entryPrice.toString()} ETH per USDC
        </p>
      </div>

      {/* Current Value */}
      <div className="space-y-2">
        <p className="text-sm font-medium">Current Value</p>
        <p className="text-lg font-semibold">
          {positionValue.toString()} ETH
        </p>
      </div>

      {/* Impermanent Loss */}
      <div className="space-y-2">
        <p className="text-sm font-medium">Impermanent Loss</p>
        <div className="flex items-center gap-2">
          <p
            className={`text-lg font-semibold ${
              impermanentLoss > 0
                ? "text-red-600"
                : impermanentLoss < 0
                ? "text-green-600"
                : "text-gray-600"
            }`}
          >
            {impermanentLoss > 0 ? "+" : ""}
            {impermanentLoss.toFixed(2)}%
          </p>
          {impermanentLoss > 0 && (
            <div className="w-4 h-4 rounded-full bg-red-100 flex items-center justify-center">
              <span className="text-xs text-red-600 font-bold">!</span>
            </div>
          )}
        </div>
      </div>

      {/* Time Elapsed */}
      <div className="space-y-2">
        <p className="text-sm font-medium">Time Elapsed</p>
        <p className="text-lg font-semibold">
          {formatDuration(Number(position.depositTimestamp))}
        </p>
      </div>

      {/* Actions */}
      <div className="flex gap-2 pt-4 border-t">
        <Button
          onClick={handleWithdraw}
          variant="outline"
          className="flex-1"
          disabled={!position.isActive}
        >
          {position.isActive ? "Withdraw Liquidity" : "Position Inactive"}
        </Button>
        {position.isActive && impermanentLoss > 5 && (
          <div className="flex-1 text-center">
            <p className="text-sm text-red-600">
              ⚠️ High IL detected - Consider withdrawing
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

/**
 * Loading skeleton for position card
 */
export function PositionCardSkeleton() {
  return (
    <div className="rounded-lg border p-6 space-y-4">
      <div className="animate-pulse">
        <div className="flex items-start justify-between">
          <div className="space-y-2">
            <div className="h-6 w-24 bg-muted rounded"></div>
            <div className="h-4 w-32 bg-muted rounded"></div>
          </div>
          <div className="h-6 w-16 bg-muted rounded"></div>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2">
            <div className="h-4 w-20 bg-muted rounded"></div>
            <div className="h-6 w-32 bg-muted rounded"></div>
          </div>
          <div className="space-y-2">
            <div className="h-4 w-20 bg-muted rounded"></div>
            <div className="h-6 w-32 bg-muted rounded"></div>
          </div>
        </div>

        <div className="space-y-2">
          <div className="h-4 w-24 bg-muted rounded"></div>
          <div className="h-6 w-32 bg-muted rounded"></div>
        </div>

        <div className="space-y-2">
          <div className="h-4 w-24 bg-muted rounded"></div>
          <div className="h-6 w-32 bg-muted rounded"></div>
        </div>

        <div className="space-y-2">
          <div className="h-4 w-24 bg-muted rounded"></div>
          <div className="h-6 w-32 bg-muted rounded"></div>
        </div>

        <div className="flex gap-2 pt-4 border-t">
          <div className="h-10 w-24 bg-muted rounded"></div>
          <div className="h-10 w-32 bg-muted rounded"></div>
        </div>
      </div>
    </div>
  );
}
