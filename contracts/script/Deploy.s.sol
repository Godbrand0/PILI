// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {ILProtectionHook} from "../src/ILProtectionHook.sol";
import {PoolManager} from "v4-core/PoolManager.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy PoolManager (if not on a network with one)
        // For testnet/mainnet, you'd use the existing address
        PoolManager poolManager = new PoolManager(address(0));
        
        // 2. Deploy Hook
        // Pass address(0) for FHEManager to let the hook deploy its own
        ILProtectionHook hook = new ILProtectionHook(IPoolManager(address(poolManager)), address(0));
        
        console.log("PoolManager deployed at:", address(poolManager));
        console.log("ILProtectionHook deployed at:", address(hook));
        console.log("FHEManager deployed at:", address(hook.fheVerifier()));

        vm.stopBroadcast();
    }
}
