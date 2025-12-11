// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {ILProtectionHook} from "../src/ILProtectionHook.sol";

contract DeployPiliSystem is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy PoolManager first
        IPoolManager poolManager = new PoolManager(address(this));
        console2.log("PoolManager deployed at:", address(poolManager));
        
        // Deploy ILProtectionHook with PoolManager address
        ILProtectionHook hook = new ILProtectionHook(IPoolManager(address(poolManager)));
        console2.log("ILProtectionHook deployed at:", address(hook));
        
        vm.stopBroadcast();
        
        console2.log("\n=== DEPLOYMENT COMPLETE ===");
        console2.log("PoolManager:", address(poolManager));
        console2.log("ILProtectionHook:", address(hook));
        console2.log("Deployer:", vm.addr(deployerPrivateKey));
        console2.log("\nAdd these to your .env file:");
        console2.log("POOL_MANAGER_ADDRESS=", address(poolManager));
        console2.log("IL_PROTECTION_HOOK_ADDRESS=", address(hook));
    }
}