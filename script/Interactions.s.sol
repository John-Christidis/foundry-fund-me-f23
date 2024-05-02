// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "@foundry-devops/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    function fundFundMe(address mostRecentContractAddressDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentContractAddressDeployed)).fund{
            value: SEND_VALUE
        }();
        vm.stopBroadcast();
        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecentContractAddressDeployed = DevOpsTools
            .get_most_recent_deployment("FundMe", block.chainid);

        fundFundMe(mostRecentContractAddressDeployed);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentContractAddressDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentContractAddressDeployed)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentContractAddressDeployed = DevOpsTools
            .get_most_recent_deployment("FundMe", block.chainid);

        withdrawFundMe(mostRecentContractAddressDeployed);
    }
}
