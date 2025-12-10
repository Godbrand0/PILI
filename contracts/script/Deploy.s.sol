// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {ILProtectionHook} from "../src/ILProtectionHook.sol";

contract DeployScript is Script {
    function run() external {
        // Load deployer private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get PoolManager address from environment or use default
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");
        
        // Start broadcasting
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy ILProtectionHook
        ILProtectionHook hook = new ILProtectionHook(poolManager);
        
        // Log deployment info
        console.log("ILProtectionHook deployed at:", address(hook));
        console.log("PoolManager address:", poolManager);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        // Verify deployment
        require(address(hook) != address(0), "Deployment failed");
        
        // Stop broadcasting
        vm.stopBroadcast();
        
        // Log initial state
        console.log("Initial owner:", hook.owner());
        console.log("Initial paused state:", hook.paused());
        console.log("Initial nextPositionId:", hook.nextPositionId());
    }
}
