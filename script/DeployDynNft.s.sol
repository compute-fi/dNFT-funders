// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {HelperConfig} from "script/HelperConfig.sol";
import {dynNFT} from "src/dynamic-nft.sol";
import {Script, console} from "forge-std/Script.sol";

contract DeployDynNFT is Script {
    function run() external returns (dynNFT, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // Fetch necessary configurations from HelperConfig if needed

        vm.startBroadcast();
        dynNFT deployedDynNFT = new dynNFT(); // Deploy dynNFT contract

        console.log(
            "Deployed dynNFT successfully at:",
            address(deployedDynNFT)
        );
        vm.stopBroadcast();
        return (deployedDynNFT, helperConfig);
    }
}
