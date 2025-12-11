# PILI User Experience Documentation

## Overview

PILI (Private Impermanent Loss Insurance) provides a seamless user experience for liquidity providers to protect their positions against impermanent loss while maintaining privacy through Fully Homomorphic Encryption (FHE). This document outlines the complete user journey from onboarding to position management.

## User Journey

### 1. Wallet Connection

**Entry Point**: Landing page (`/`)

- Users see a clean, professional interface with a clear value proposition
- "Connect Wallet" button prominently displayed
- Supports multiple wallet providers through RainbowKit
- Once connected, users are redirected to the main dashboard

**User Experience**:
- Seamless wallet connection with familiar wallet providers
- Clear indication of connection status
- Network switching support (optimized for Fhenix Helix)

### 2. Adding Liquidity with IL Protection

**Entry Point**: "Add Liquidity" page (`/add-liquidity`)

#### Step-by-Step Flow:

1. **Token Selection & Amounts**
   - Users see their current token balances
   - Input fields for WETH and USDC amounts
   - Real-time balance validation
   - Clear display of available tokens

2. **IL Threshold Setting**
   - Default threshold set to 5% (user-friendly default)
   - Slider/input for customizing threshold (0-100%)
   - Real-time encryption indicator
   - Educational tooltip explaining the concept

3. **FHE Encryption Process**
   - Visual feedback during encryption: "Encrypting threshold with FHE..."
   - Gas cost estimation displayed transparently
   - Clear explanation of what's happening behind the scenes

4. **Transaction Confirmation**
   - Clear summary of the position being created
   - Gas fee breakdown
   - Transaction pending state with progress indicator
   - Success confirmation with position details

**Key UX Features**:
- Form validation with helpful error messages
- Real-time feedback on all interactions
- Educational content explaining IL protection
- Transparent gas cost estimation
- Loading states for all async operations

### 3. Position Management Dashboard

**Entry Point**: "My Positions" page (`/positions`)

#### Dashboard Components:

1. **Portfolio Overview**
   - Total deposited value
   - Number of active/inactive positions
   - Visual statistics cards

2. **Position Cards**
   - Each position displayed in an intuitive card format
   - Key metrics prominently displayed:
     - Position ID
     - Token amounts
     - Entry price
     - Current value
     - Impermanent loss percentage
     - Time elapsed

3. **Real-time IL Monitoring**
   - Color-coded IL indicators (green/yellow/red)
   - Warning alerts for high IL (>5%)
   - Visual indicators for protection status

4. **Position Actions**
   - "Withdraw Liquidity" button for active positions
   - Clear status indicators (Active/Inactive)
   - One-click withdrawal process

**Interactive Features**:
- Hover states on all interactive elements
- Smooth transitions and micro-interactions
- Responsive design for all screen sizes
- Loading skeletons for better perceived performance

## Technical Implementation Details

### Frontend Architecture

The frontend is built with:
- **Next.js 14** with App Router for modern React patterns
- **TypeScript** for type safety
- **Tailwind CSS** for responsive styling
- **Wagmi** for Ethereum wallet integration
- **RainbowKit** for wallet connection UI

### Key Components

#### AddLiquidityForm Component
```typescript
// Key features:
- Real-time form validation
- FHE encryption integration
- Gas estimation
- Transaction state management
- Error handling with user-friendly messages
```

#### PositionCard Component
```typescript
// Key features:
- Dynamic IL calculation
- Color-coded status indicators
- Responsive layout
- Loading states
- Interactive actions
```

#### useILProtectionHook Hook
```typescript
// Key features:
- Contract interaction abstraction
- Real-time data fetching
- Position calculations
- Transaction management
```

### FHE Integration

The FHE integration is designed to be transparent to users:

1. **Threshold Encryption**
   - Happens automatically when user sets threshold
   - Visual feedback during encryption process
   - No additional user steps required

2. **Privacy Preservation**
   - Users' IL thresholds remain encrypted
   - Protection triggers automatically without revealing thresholds
   - No compromise on user privacy

3. **Gas Optimization**
   - Efficient FHE operations
   - Clear gas cost estimation
   - Batch operations where possible

## User Experience Enhancements

### 1. Progressive Disclosure

- Simple interface for beginners
- Advanced options available for experienced users
- Educational content integrated naturally
- Tooltips and help text throughout

### 2. Visual Feedback

- Loading states for all async operations
- Progress indicators for long-running operations
- Success/error states with clear messaging
- Real-time updates for position values

### 3. Error Handling

- User-friendly error messages
- Recovery suggestions for common errors
- Network error handling with retry options
- Transaction failure explanations

### 4. Performance Optimization

- Lazy loading for position data
- Efficient data fetching with caching
- Optimistic updates for better perceived performance
- Skeleton loading states

## Mobile Experience

The application is fully responsive with:

- Mobile-first design approach
- Touch-friendly interface elements
- Optimized layouts for small screens
- Simplified navigation on mobile

## Accessibility

- Semantic HTML structure
- ARIA labels for screen readers
- Keyboard navigation support
- High contrast mode support
- Focus management

## Security Considerations

### User Security

1. **Wallet Security**
   - No private keys stored on the application
   - Secure wallet connection through established providers
   - Clear transaction signing prompts

2. **Smart Contract Interaction**
   - Clear transaction details before signing
   - Gas fee transparency
   - Contract verification information

3. **Privacy Protection**
   - FHE ensures threshold privacy
   - No sensitive data stored in plaintext
   - Secure data transmission

## Future UX Enhancements

### Planned Features

1. **Advanced Analytics**
   - Historical IL tracking
   - Portfolio performance charts
   - Yield farming insights

2. **Customizable Alerts**
   - Email notifications for IL thresholds
   - Push notifications for position changes
   - Custom alert conditions

3. **Social Features**
   - Anonymous position sharing
   - Community insights
   - Educational content hub

4. **Advanced Protection Options**
   - Dynamic threshold adjustment
   - Multi-pool protection
   - Yield optimization strategies

### User Feedback Integration

- In-app feedback mechanism
- User testing sessions
- A/B testing for UX improvements
- Community-driven feature requests

## Conclusion

The PILI user experience is designed to make impermanent loss protection accessible to all liquidity providers while maintaining the highest standards of privacy and security. The interface balances simplicity for beginners with advanced features for experienced DeFi users, all powered by cutting-edge FHE technology.

The seamless integration of complex cryptographic operations with an intuitive interface ensures that users can protect their positions without needing to understand the underlying technology, making DeFi more accessible and secure for everyone.