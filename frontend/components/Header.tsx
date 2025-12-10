"use client";

import { useAccount } from 'wagmi';
import Link from 'next/link';
import { WalletConnectButton } from "./WalletConnectButton";
import { Button } from "./ui/Button";

/**
 * Header component with navigation and wallet connection
 */
export function Header() {
  const { isConnected } = useAccount();

  return (
    <header className="border-b bg-white/95 backdrop-blur supports-[backdrop-filter]:bg-white/60 dark:bg-black/95 dark:supports-[backdrop-filter]:bg-black/60">
      <div className="container flex h-16 items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="h-6 w-6 rounded bg-blue-500" />
          <h1 className="text-xl font-bold">PILI</h1>
          <span className="text-sm text-gray-600 dark:text-gray-400">
            Privacy-Preserving IL Protection
          </span>
        </div>

        <nav className="hidden md:flex items-center gap-6">
          <Link
            href="/"
            className="text-sm font-medium transition-colors hover:text-blue-600 dark:hover:text-blue-400"
          >
            Home
          </Link>
          {isConnected && (
            <>
              <Link
                href="/add-liquidity"
                className="text-sm font-medium transition-colors hover:text-blue-600 dark:hover:text-blue-400"
              >
                Add Liquidity
              </Link>
              <Link
                href="/positions"
                className="text-sm font-medium transition-colors hover:text-blue-600 dark:hover:text-blue-400"
              >
                My Positions
              </Link>
            </>
          )}
        </nav>

        <div className="flex items-center gap-4">
          <div className="hidden sm:flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
            <div className="h-4 w-4 rounded bg-green-500" />
            <span>Fhenix Helix</span>
          </div>
          {isConnected && (
            <>
              <Link href="/add-liquidity">
                <Button variant="ghost" size="sm">Add Liquidity</Button>
              </Link>
              <Link href="/positions">
                <Button variant="ghost" size="sm">Positions</Button>
              </Link>
            </>
          )}
          <WalletConnectButton />
        </div>
      </div>
    </header>
  );
}
