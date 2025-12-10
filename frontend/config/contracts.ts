/**
 * Contract configuration for PILI DApp
 *
 * This file contains contract addresses and ABIs for different networks.
 * Update these values when deploying to new networks.
 */

import ILProtectionHookABI from "../abis/ILProtectionHook.json";

export interface ContractConfig {
  address: `0x${string}`;
  abi: typeof ILProtectionHookABI.abi;
}

export interface NetworkConfig {
  name: string;
  chainId: number;
  rpcUrl: string;
  blockExplorerUrl: string;
  nativeCurrency: {
    name: string;
    symbol: string;
    decimals: number;
  };
  contracts: {
    ILProtectionHook: ContractConfig;
  };
}

/**
 * Network configurations
 */
export const NETWORKS: Record<number, NetworkConfig> = {
  // Fhenix Helix Testnet
  8008135: {
    name: "Fhenix Helix",
    chainId: 8008135,
    rpcUrl: "https://api.helix.fhenix.zone",
    blockExplorerUrl: "https://explorer.helix.fhenix.zone",
    nativeCurrency: {
      name: "Fhenix",
      symbol: "FHE",
      decimals: 18,
    },
    contracts: {
      ILProtectionHook: {
        // TODO: Update with deployed contract address
        address: "0x0000000000000000000000000000000000000000" as `0x${string}`,
        abi: ILProtectionHookABI.abi,
      },
    },
  },
  // Ethereum Sepolia Testnet
  11155111: {
    name: "Sepolia",
    chainId: 11155111,
    rpcUrl: "https://sepolia.infura.io/v3/",
    blockExplorerUrl: "https://sepolia.etherscan.io",
    nativeCurrency: {
      name: "Ethereum",
      symbol: "ETH",
      decimals: 18,
    },
    contracts: {
      ILProtectionHook: {
        // TODO: Update with deployed contract address
        address: "0x0000000000000000000000000000000000000000" as `0x${string}`,
        abi: ILProtectionHookABI.abi,
      },
    },
  },
  // Ethereum Mainnet
  1: {
    name: "Ethereum",
    chainId: 1,
    rpcUrl: "https://mainnet.infura.io/v3/",
    blockExplorerUrl: "https://etherscan.io",
    nativeCurrency: {
      name: "Ethereum",
      symbol: "ETH",
      decimals: 18,
    },
    contracts: {
      ILProtectionHook: {
        // TODO: Update with deployed contract address
        address: "0x0000000000000000000000000000000000000000" as `0x${string}`,
        abi: ILProtectionHookABI.abi,
      },
    },
  },
};

/**
 * Default network for the DApp
 */
export const DEFAULT_CHAIN_ID = 8008135; // Fhenix Helix

/**
 * Get network configuration by chain ID
 */
export function getNetworkConfig(chainId: number): NetworkConfig | undefined {
  return NETWORKS[chainId];
}

/**
 * Get contract configuration for a specific network
 */
export function getContractConfig(
  chainId: number,
  contractName: keyof NetworkConfig["contracts"]
): ContractConfig | undefined {
  const network = getNetworkConfig(chainId);
  return network?.contracts[contractName];
}

/**
 * Supported chain IDs for Wagmi configuration
 */
export const SUPPORTED_CHAIN_IDS = Object.keys(NETWORKS).map(Number);

/**
 * Common ERC-20 tokens for testing
 */
export const COMMON_TOKENS = {
  // Fhenix Helix Testnet
  8008135: {
    WETH: {
      address: "0x4200000000000000000000000000000000000006" as `0x${string}`,
      symbol: "WETH",
      name: "Wrapped Ether",
      decimals: 18,
    },
    USDC: {
      address: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913" as `0x${string}`,
      symbol: "USDC",
      name: "USD Coin",
      decimals: 6,
    },
  },
  // Ethereum Sepolia Testnet
  11155111: {
    WETH: {
      address: "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14" as `0x${string}`,
      symbol: "WETH",
      name: "Wrapped Ether",
      decimals: 18,
    },
    USDC: {
      address: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238" as `0x${string}`,
      symbol: "USDC",
      name: "USD Coin",
      decimals: 6,
    },
  },
  // Ethereum Mainnet
  1: {
    WETH: {
      address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2" as `0x${string}`,
      symbol: "WETH",
      name: "Wrapped Ether",
      decimals: 18,
    },
    USDC: {
      address: "0xA0b86a33E6441b8e8C7C7b0b8e8e8e8e8e8e8e8" as `0x${string}`,
      symbol: "USDC",
      name: "USD Coin",
      decimals: 6,
    },
  },
};

/**
 * Get token configuration for a network
 */
export function getTokenConfig(
  chainId: number,
  tokenSymbol: keyof (typeof COMMON_TOKENS)[typeof DEFAULT_CHAIN_ID]
) {
  return (COMMON_TOKENS as any)[chainId]?.[tokenSymbol];
}
