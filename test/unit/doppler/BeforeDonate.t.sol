// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { BaseTest } from "test/shared/BaseTest.sol";
import { CannotDonate } from "src/Doppler.sol";

contract DopplerBeforeDonateTest is BaseTest {
    function test_BeforeDonate_RevertsEveryTime() public {
        vm.expectRevert(CannotDonate.selector);
        hook.beforeDonate(address(0), key, 0, 0, new bytes(0));
    }
}
