import { type ClassValue, clsx } from 'clsx';

export function cn(...inputs: ClassValue[]) {
  return clsx(inputs);
}

/**
 * Format address for display
 */
export function formatAddress(address: string): string {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

/**
 * Format balance with proper decimals
 */
export function formatBalance(balance: bigint, decimals: number = 18): string {
  const divisor = BigInt(10 ** decimals);
  const whole = balance / divisor;
  const fraction = (balance % divisor) / divisor;
  
  return `${whole.toLocaleString()}${fraction > 0 ? `.${fraction.toString().slice(2, 6)}` : ''}`;
}

/**
 * Format percentage
 */
export function formatPercentage(value: number): string {
  return `${(value * 100).toFixed(2)}%`;
}

/**
 * Calculate impermanent loss percentage
 */
export function calculateImpermanentLoss(
  priceRatio: number
): number {
  // IL formula: (2 * sqrt(priceRatio) / (1 + priceRatio)) - 1
  const sqrtRatio = Math.sqrt(priceRatio);
  const il = (2 * sqrtRatio) / (1 + priceRatio) - 1;
  return il;
}

/**
 * Calculate price ratio from current and entry prices
 */
export function calculatePriceRatio(
  currentPrice: bigint,
  entryPrice: bigint
): number {
  if (entryPrice === BigInt(0)) return 1;
  return Number(currentPrice) / Number(entryPrice);
}

/**
 * Format timestamp to readable date
 */
export function formatDate(timestamp: number): string {
  return new Date(timestamp * 1000).toLocaleDateString();
}

/**
 * Format duration between timestamps
 */
export function formatDuration(startTime: number, endTime?: number): string {
  const end = endTime || Date.now() / 1000;
  const duration = end - startTime;
  
  const days = Math.floor(duration / 86400);
  const hours = Math.floor((duration % 86400) / 3600);
  const minutes = Math.floor((duration % 3600) / 60);
  
  if (days > 0) {
    return `${days}d ${hours}h`;
  } else if (hours > 0) {
    return `${hours}h ${minutes}m`;
  } else {
    return `${minutes}m`;
  }
}

/**
 * Validate Ethereum address
 */
export function isValidAddress(address: string): boolean {
  return /^0x[a-fA-F0-9]{40}$/.test(address);
}

/**
 * Convert wei to ether
 */
export function weiToEther(wei: bigint): string {
  return formatBalance(wei, 18);
}

/**
 * Convert ether to wei
 */
export function etherToWei(ether: string): bigint {
  const parts = ether.split('.');
  const whole = BigInt(parts[0] || '0');
  const fraction = parts[1] ? parts[1].padEnd(18, '0').slice(0, 18) : '0';
  return whole * BigInt(10 ** 18) + BigInt(fraction);
}
