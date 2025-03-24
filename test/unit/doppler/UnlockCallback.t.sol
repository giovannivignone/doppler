// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { SafeCallback } from "@v4-periphery/base/SafeCallback.sol";
import { BaseTest } from "test/shared/BaseTest.sol";
import { Doppler } from "src/Doppler.sol";

contract DopplerUnlockCallbackTest is BaseTest {
    function test_unlockCallback_RevertsWhenNotPoolManager() public {
        vm.expectRevert(SafeCallback.NotPoolManager.selector);
        hook.unlockCallback("");
    }

    function test_unlockCallback_SucceedWhenSenderIsPoolManager() public {
        vm.skip(true);
        Doppler.CallbackData memory callbackData = Doppler.CallbackData({
            key: key,
            tick: hook.getStartingTick(),
            sender: address(0xbeef),
            isMigration: false
        });
        vm.prank(address(manager));
        hook.unlock(abi.encode(callbackData));
    }
}
