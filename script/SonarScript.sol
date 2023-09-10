// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract Sonar {
    uint256 public counter = 1;

    function ping() external returns (uint256) {
        return counter++;
    }
}

library SonarLibary {
    function sendIt(Sonar sonar) external returns (uint256) {
        return sonar.ping();
    }
}

contract SonarScript is Script {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Sonar sonar = new Sonar();

        // Sends a transaction
        sonar.ping();

        // Does not send a transaction
        SonarLibary.sendIt(sonar);

        require(sonar.counter() == 3);

        sonar.ping();

        vm.stopBroadcast();
    }
}
