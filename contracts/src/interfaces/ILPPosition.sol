// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {euint32, euint256, ebool} from "@fhenixprotocol/contracts/FHE.sol";

/// @title ILPPosition
/// @notice Interface and data structures for IL-protected liquidity positions
/// @dev Used by ILProtectionHook to manage LP positions with encrypted IL thresholds

/// @notice Position data for IL-protected liquidity
/// @dev Optimized storage layout: address + bool + uint96 packed in one slot
struct LPPosition {
    address lpAddress;           // LP's wallet address (20 bytes)
    bool isActive;               // Whether position is still active (1 byte)
    uint96 positionId;           // Unique position identifier (12 bytes)
    uint256 entryPrice;          // Price when LP deposited (sqrtPriceX96 format)
    uint128 token0Amount;        // Initial token0 amount
    uint128 token1Amount;        // Initial token1 amount
    euint32 encryptedILThreshold; // Encrypted IL threshold in basis points (e.g., 500 = 5%)
    uint256 depositTimestamp;    // Block timestamp when position was created
}

/// @title ILPPositionEvents
/// @notice Events emitted by the IL Protection Hook
interface ILPPositionEvents {
    /// @notice Emitted when a new LP position is created
    /// @param positionId Unique identifier for the position
    /// @param lpAddress Address of the liquidity provider
    /// @param poolId Identifier of the Uniswap v4 pool
    /// @param token0Amount Initial amount of token0
    /// @param token1Amount Initial amount of token1
    /// @param entryPrice Price at deposit (sqrtPriceX96 format)
    event PositionCreated(
        uint256 indexed positionId,
        address indexed lpAddress,
        bytes32 indexed poolId,
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 entryPrice
    );

    /// @notice Emitted when a position is withdrawn (manually or automatically)
    /// @param positionId Unique identifier for the position
    /// @param lpAddress Address of the liquidity provider
    /// @param poolId Identifier of the Uniswap v4 pool
    /// @param token0Amount Final amount of token0 returned
    /// @param token1Amount Final amount of token1 returned
    /// @param currentIL Current impermanent loss in basis points
    /// @param wasAutomatic Whether withdrawal was automatic (true) or manual (false)
    event PositionWithdrawn(
        uint256 indexed positionId,
        address indexed lpAddress,
        bytes32 indexed poolId,
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 currentIL,
        bool wasAutomatic
    );

    /// @notice Emitted when IL threshold is breached, triggering automatic withdrawal
    /// @param positionId Unique identifier for the position
    /// @param poolId Identifier of the Uniswap v4 pool
    /// @param currentIL Current impermanent loss in basis points that triggered exit
    event ILThresholdBreached(
        uint256 indexed positionId,
        bytes32 indexed poolId,
        uint256 currentIL
    );

    /// @notice Emitted when emergency pause state is changed
    /// @param isPaused New pause state
    /// @param admin Address that changed the pause state
    event EmergencyPauseChanged(bool isPaused, address indexed admin);
}