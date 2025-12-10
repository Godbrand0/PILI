"use client";

import { useAccount } from "wagmi";
import { formatAddress } from "../lib/utils";
import { Button } from "../components/ui/Button";
import { WalletConnectButton } from "../components/WalletConnectButton";
import Link from "next/link";

export default function Home() {
  const { address, isConnected } = useAccount();

  return (
    <div className="space-y-8">
      {/* Hero Section */}
      <section className="text-center space-y-4">
        <h1 className="text-4xl font-bold tracking-tight">
          Privacy-Preserving IL Protection
        </h1>
        <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
          Protect your Uniswap v4 liquidity from impermanent loss with
          <span className="font-semibold text-primary">
            fully homomorphic encryption
          </span>
        </p>
        <div className="flex justify-center gap-4">
          {isConnected ? (
            <>
              <Link href="/add-liquidity">
                <Button>Add Liquidity</Button>
              </Link>
              <Link href="/positions">
                <Button variant="outline">My Positions</Button>
              </Link>
            </>
          ) : (
            <WalletConnectButton />
          )}
        </div>
      </section>

      {/* Features Section */}
      <section className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-lg border p-6 space-y-4">
          <div className="h-12 w-12 rounded-lg bg-primary/10 flex items-center justify-center">
            <div className="h-6 w-6 rounded bg-primary" />
          </div>
          <h3 className="text-lg font-semibold">Privacy-Preserving</h3>
          <p className="text-sm text-muted-foreground">
            Your impermanent loss threshold is encrypted using FHE, keeping your
            strategy private.
          </p>
        </div>

        <div className="rounded-lg border p-6 space-y-4">
          <div className="h-12 w-12 rounded-lg bg-green-100 flex items-center justify-center">
            <div className="h-6 w-6 rounded bg-green-600" />
          </div>
          <h3 className="text-lg font-semibold">Automatic Protection</h3>
          <p className="text-sm text-muted-foreground">
            Smart contracts automatically monitor and protect your positions
            when IL exceeds your threshold.
          </p>
        </div>

        <div className="rounded-lg border p-6 space-y-4">
          <div className="h-12 w-12 rounded-lg bg-blue-100 flex items-center justify-center">
            <div className="h-6 w-6 rounded bg-blue-600" />
          </div>
          <h3 className="text-lg font-semibold">Gas Efficient</h3>
          <p className="text-sm text-muted-foreground">
            Optimized FHE operations minimize gas costs while maintaining
            privacy.
          </p>
        </div>
      </section>

      {/* How It Works */}
      <section className="space-y-6">
        <h2 className="text-3xl font-bold text-center">How It Works</h2>
        <div className="grid gap-8 md:grid-cols-3">
          <div className="space-y-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground font-bold text-sm">
              1
            </div>
            <h3 className="font-semibold">Set IL Threshold</h3>
            <p className="text-sm text-muted-foreground">
              Choose your impermanent loss tolerance (e.g., 5%) and encrypt it
              with FHE.
            </p>
          </div>

          <div className="space-y-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground font-bold text-sm">
              2
            </div>
            <h3 className="font-semibold">Add Liquidity</h3>
            <p className="text-sm text-muted-foreground">
              Provide liquidity to Uniswap v4 pools with your encrypted IL
              protection.
            </p>
          </div>

          <div className="space-y-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground font-bold text-sm">
              3
            </div>
            <h3 className="font-semibold">Automatic Protection</h3>
            <p className="text-sm text-muted-foreground">
              Smart contracts monitor your position and automatically withdraw
              if IL exceeds threshold.
            </p>
          </div>
        </div>
      </section>

      {/* Wallet Connection Status */}
      {isConnected && address && (
        <section className="rounded-lg border p-6 bg-muted/50">
          <h3 className="text-lg font-semibold mb-2">Connected Wallet</h3>
          <p className="text-sm text-muted-foreground">
            Address: {formatAddress(address)}
          </p>
          <p className="text-sm text-primary">
            Ready to protect your liquidity positions
          </p>
        </section>
      )}

      {/* Call to Action */}
      {!isConnected && (
        <section className="text-center space-y-4">
          <h2 className="text-2xl font-semibold">Get Started</h2>
          <p className="text-muted-foreground">
            Connect your wallet to start protecting your liquidity positions
          </p>
          <WalletConnectButton />
        </section>
      )}
    </div>
  );
}
