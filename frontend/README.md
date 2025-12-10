# PILI Frontend

Privacy-Preserving Impermanent Loss Insurance frontend built with Next.js 16, TypeScript, and modern Web3 technologies.

## Overview

PILI is a DeFi application that protects Uniswap v4 liquidity positions from impermanent loss using Fully Homomorphic Encryption (FHE) on the Fhenix Protocol. Users can set private IL thresholds that are encrypted and monitored by smart contracts without revealing their strategy.

## Features

- **Privacy-Preserving**: IL thresholds encrypted with FHE
- **Automated Protection**: Smart contracts monitor and protect positions
- **Gas Efficient**: Optimized FHE operations
- **Modern UI**: Responsive design with Tailwind CSS
- **Wallet Integration**: RainbowKit + Wagmi v2
- **TypeScript**: Full type safety

## Tech Stack

- **Framework**: Next.js 16 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS + shadcn/ui
- **Web3**: Wagmi v2, RainbowKit, Viem
- **FHE**: Fhenix.js
- **State Management**: React hooks
- **Testing**: Jest + React Testing Library

## Project Structure

```
frontend/
├── app/                    # Next.js app router pages
│   ├── add-liquidity/      # Add liquidity page
│   ├── positions/          # Position management page
│   ├── layout.tsx          # Root layout with providers
│   └── page.tsx            # Home page
├── components/             # React components
│   ├── ui/                 # Reusable UI components
│   ├── AddLiquidityForm.tsx # Liquidity addition form
│   ├── Header.tsx          # Navigation header
│   ├── PositionCard.tsx   # Position display card
│   └── WalletConnectButton.tsx # Wallet connection
├── config/                 # Configuration files
│   ├── contracts.ts        # Contract addresses and ABIs
│   └── wagmi.ts            # Wagmi configuration
├── hooks/                  # Custom React hooks
│   └── useILProtectionHook.ts # Contract interaction hook
├── lib/                    # Utility libraries
│   └── utils.ts            # Helper functions
├── utils/                  # Utility functions
│   └── fheUtils.ts         # FHE encryption utilities
└── abis/                   # Contract ABIs
    └── ILProtectionHook.json
```

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- MetaMask or compatible wallet

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-org/pili.git
cd pili/frontend
```

2. Install dependencies:
```bash
npm install
```

3. Copy environment variables:
```bash
cp .env.example .env.local
```

4. Configure environment variables in `.env.local`:
```env
NEXT_PUBLIC_FHENIX_RPC_URL=https://helix.fhenix.zone
NEXT_PUBLIC_CONTRACT_ADDRESS=0x...
```

5. Run the development server:
```bash
npm run dev
```

6. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Usage

### Adding Liquidity with IL Protection

1. Connect your wallet to the Fhenix Helix network
2. Navigate to "Add Liquidity"
3. Configure your position:
   - Select token pair
   - Set liquidity amounts
   - Define IL threshold (e.g., 5%)
4. Approve and execute the transaction
5. Your IL threshold is encrypted using FHE

### Monitoring Positions

1. Navigate to "My Positions"
2. View all your protected liquidity positions
3. Monitor:
   - Current IL percentage
   - Position status
   - Withdrawal history
4. Withdraw positions manually when needed

### How IL Protection Works

1. **Threshold Setting**: User sets IL threshold (e.g., 5%)
2. **FHE Encryption**: Threshold is encrypted using FHE
3. **Monitoring**: Smart contracts continuously monitor position
4. **Automatic Withdrawal**: When IL exceeds threshold, position is automatically withdrawn
5. **Privacy**: Threshold remains private throughout the process

## Smart Contract Integration

The frontend integrates with the following smart contracts:

- **ILProtectionHook**: Main Uniswap v4 hook for IL protection
- **FHEManager**: Handles FHE operations and encryption
- **ILCalculator**: Calculates impermanent loss

### Contract Configuration

Contract addresses and ABIs are configured in `config/contracts.ts`:

```typescript
export const IL_PROTECTION_HOOK_ADDRESS = '0x...';
export const FHE_MANAGER_ADDRESS = '0x...';
```

## FHE Implementation

The frontend uses Fhenix.js for client-side FHE operations:

```typescript
import { fhenixjs } from 'fhenixjs';

// Encrypt IL threshold
const encryptedThreshold = await fhenixjs.encrypt_uint32(threshold);
```

## Testing

Run the test suite:

```bash
npm run test
```

Run tests with coverage:

```bash
npm run test:coverage
```

## Building for Production

1. Build the application:
```bash
npm run build
```

2. Start the production server:
```bash
npm run start
```

## Deployment

The frontend can be deployed to any static hosting service:

- Vercel (recommended)
- Netlify
- AWS Amplify
- Cloudflare Pages

### Environment Variables for Production

Ensure these are set in your deployment environment:

- `NEXT_PUBLIC_FHENIX_RPC_URL`
- `NEXT_PUBLIC_CONTRACT_ADDRESS`
- `NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## Security Considerations

- All sensitive operations require wallet confirmation
- IL thresholds are encrypted using FHE
- No private keys are stored on the frontend
- All contract interactions are validated

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please:

1. Check the documentation
2. Search existing issues
3. Create a new issue with details
4. Join our Discord community

## Acknowledgments

- [Fhenix Protocol](https://fhenix.io/) for FHE infrastructure
- [Uniswap v4](https://uniswap.org/) for hooks functionality
- [RainbowKit](https://www.rainbowkit.com/) for wallet integration
- [Wagmi](https://wagmi.sh/) for React hooks
