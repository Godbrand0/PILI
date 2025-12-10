/**
 * Wagmi configuration for PILI DApp
 * 
 * This file configures Wagmi with supported networks and providers.
 */

import { http, createConfig } from 'wagmi';
import { sepolia, mainnet } from 'wagmi/chains';
import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { SUPPORTED_CHAIN_IDS, DEFAULT_CHAIN_ID } from './contracts';
import { chain } from 'wagmi';

/**
 * Custom Fhenix Helix chain configuration
 */
const fhenixHelixCustom = chain({
  id: 8008135,
  name: 'Fhenix Helix',
  nativeCurrency: {
    decimals: 18,
    name: 'Fhenix',
    symbol: 'FHE',
  },
  rpcUrls: {
    default: { http: ['https://api.helix.fhenix.zone'] },
    public: { http: ['https://api.helix.fhenix.zone'] },
  },
  blockExplorers: {
    default: { name: 'Fhenix Explorer', url: 'https://explorer.helix.fhenix.zone' },
  },
  testnet: true,
});

/**
 * Supported chains for DApp
 */
export const supportedChains = [
  fhenixHelixCustom,
  sepolia,
  mainnet,
].filter(chain => SUPPORTED_CHAIN_IDS.includes(chain.id));

/**
 * Project configuration for RainbowKit
 */
const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'demo-project-id';

/**
 * Wagmi configuration
 */
export const wagmiConfig = getDefaultConfig({
  appName: 'PILI - Privacy-Preserving IL Protection',
  projectId,
  chains: supportedChains,
  transports: {
    [fhenixHelixCustom.id]: http(),
    [sepolia.id]: http(),
    [mainnet.id]: http(),
  },
  ssr: false, // Disable SSR for wallet connection
});

/**
 * Default chain ID
 */
export { DEFAULT_CHAIN_ID };

/**
 * Get chain configuration by ID
 */
export function getChainById(chainId: number) {
  return supportedChains.find(chain => chain.id === chainId);
}

/**
 * Check if chain is supported
 */
export function isSupportedChain(chainId: number): boolean {
  return SUPPORTED_CHAIN_IDS.includes(chainId);
}

/**
 * Get RPC URL for a chain
 */
export function getRpcUrl(chainId: number): string | undefined {
  const chain = getChainById(chainId);
  return chain?.rpcUrls.default.http[0];
}
