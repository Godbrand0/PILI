// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

/// @title Deploy FHEManager Test Contract
/// @notice Deployment script for testing FHEManager on Fhenix testnet
contract DeployFHETest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== FHEManager Deployment ===");
        console.log("Network: Fhenix Helium Testnet");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        // FHEManager is a library - it will be linked when used by contracts
        // For testing, you would deploy a contract that uses FHEManager
        
        console.log("\nFHEManager library ready for integration");
        console.log("Next: Deploy ILProtectionHook that uses FHEManager");
        
        vm.stopBroadcast();
    }
}
