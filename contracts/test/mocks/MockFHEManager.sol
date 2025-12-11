// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {euint32, euint256, ebool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/// @title MockFHEManager
/// @notice Mock contract for testing ILProtectionHook without actual FHE environment
contract MockFHEManager {
    
    bool public shouldBreach;

    function setShouldBreach(bool _shouldBreach) external {
        shouldBreach = _shouldBreach;
    }

    function requireThresholdBreached(
        uint256 currentILBp,
        euint32 encryptedThreshold
    ) external view {
        if (!shouldBreach) {
            // Simulate FHE check failing (threshold NOT breached)
            // In the real contract, this is a try/catch, so we revert to be caught
            revert("Threshold not breached");
        }
        // If shouldBreach is true, we do nothing (success), which means threshold IS breached
    }

    function encryptBasisPoints(uint32 basisPoints)
        external
        pure
        returns (euint32 encrypted)
    {
        // Mock encryption - just wrap the value
        // In reality we can't create valid euint32 without FHE, but for tests we might not need to inspect it
        return euint32.wrap(basisPoints);
    }

    function validateEncryptedThreshold(euint32)
        external
        pure
        returns (bool isValid)
    {
        return true;
    }

    function getEncryptedZeroFor(address) external pure returns (euint32 encrypted) {
        return euint32.wrap(0);
    }

    function getEncryptedMaxBpFor(address) external pure returns (euint32 encrypted) {
        return euint32.wrap(10000);
    }

    function grantAccess(euint32, address) external pure {
        // Mock - do nothing
    }
}
