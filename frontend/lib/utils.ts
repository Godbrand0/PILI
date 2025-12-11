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
 * Convert sqrtPriceX96 to regular price
 * sqrtPriceX96 = sqrt(price) * 2^96
 * price = (sqrtPriceX96 / 2^96)^2 = sqrtPriceX96^2 / 2^192
 */
export function sqrtPriceX96ToPrice(sqrtPriceX96: bigint): number {
  const Q96 = BigInt(2) ** BigInt(96);
  const Q192 = Q96 * Q96; // 2^192
  const PRECISION = BigInt(1e18);

  // Calculate (sqrtPriceX96^2 * 1e18) / 2^192 for precision
  const sqrtPriceSquared = sqrtPriceX96 * sqrtPriceX96;
  const priceScaled = (sqrtPriceSquared * PRECISION) / Q192;

  // Convert to number (now with PRECISION decimals)
  const price = Number(priceScaled) / 1e18;

  // Debug logging
  if (typeof window !== 'undefined' && window.localStorage) {
    console.log('sqrtPriceX96ToPrice debug:', {
      sqrtPriceX96: sqrtPriceX96.toString(),
      sqrtPriceSquared: sqrtPriceSquared.toString(),
      priceScaled: priceScaled.toString(),
      price: price.toString()
    });
  }

  return price;
}

/**
 * Calculate impermanent loss percentage from sqrtPriceX96 values
 */
export function calculateImpermanentLoss(
  entrySqrtPriceX96: bigint,
  currentSqrtPriceX96: bigint
): number {
  // Convert sqrtPriceX96 to regular prices
  const entryPrice = sqrtPriceX96ToPrice(entrySqrtPriceX96);
  const currentPrice = sqrtPriceX96ToPrice(currentSqrtPriceX96);
  
  if (entryPrice === 0) return 0;
  
  // Calculate price ratio
  const priceRatio = currentPrice / entryPrice;
  
  // IL formula: (2 * sqrt(priceRatio) / (1 + priceRatio)) - 1
  const sqrtRatio = Math.sqrt(priceRatio);
  const il = (2 * sqrtRatio) / (1 + priceRatio) - 1;
  
  // Debug logging
  if (typeof window !== 'undefined' && window.localStorage) {
    console.log('calculateImpermanentLoss debug:', {
      entrySqrtPriceX96: entrySqrtPriceX96.toString(),
      currentSqrtPriceX96: currentSqrtPriceX96.toString(),
      entryPrice,
      currentPrice,
      priceRatio,
      sqrtRatio,
      il: il.toString(),
      ilPercent: (il * 100).toFixed(2) + '%'
    });
  }
  
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
 * Calculate impermanent loss percentage from regular prices
 */
export function calculateImpermanentLossFromPrices(
  entryPrice: number,
  currentPrice: number
): number {
  if (entryPrice === 0) return 0;
  
  // Calculate price ratio
  const priceRatio = currentPrice / entryPrice;
  
  // IL formula: (2 * sqrt(priceRatio) / (1 + priceRatio)) - 1
  const sqrtRatio = Math.sqrt(priceRatio);
  const il = (2 * sqrtRatio) / (1 + priceRatio) - 1;
  
  return il;
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
