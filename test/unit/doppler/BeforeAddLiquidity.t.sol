// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { IPoolManager } from "@v4-core/interfaces/IPoolManager.sol";
import { Hooks } from "@v4-core/libraries/Hooks.sol";
import { BaseHook } from "@v4-periphery/base/hooks/BaseHook.sol";
import { SafeCallback } from "@v4-periphery/base/SafeCallback.sol";
import { Hooks } from "@v4-core/libraries/Hooks.sol";
import { CannotAddLiquidity } from "src/Doppler.sol";
import { BaseTest } from "test/shared/BaseTest.sol";

contract DopplerBeforeAddLiquidityTest is BaseTest {
    // =========================================================================
    //                      beforeAddLiquidity Unit Tests
    // =========================================================================

    function testBeforeAddLiquidity_RevertsIfNotPoolManager() public {
        vm.expectRevert(SafeCallback.NotPoolManager.selector);
        hook.beforeAddLiquidity(
            address(this),
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -100_000,
                tickUpper: 100_000,
                liquidityDelta: 100e18,
                salt: bytes32(0)
            }),
            ""
        );
    }

    function testBeforeAddLiquidity_ReturnsSelectorForHookCaller() public {
        vm.prank(address(manager));
        bytes4 selector = hook.beforeAddLiquidity(
            address(hook),
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -100_000,
                tickUpper: 100_000,
                liquidityDelta: 100e18,
                salt: bytes32(0)
            }),
            ""
        );

        assertEq(selector, BaseHook.beforeAddLiquidity.selector);
    }

    function testBeforeAddLiquidity_RevertsForNonHookCaller() public {
        vm.prank(address(manager));
        vm.expectRevert(CannotAddLiquidity.selector);
        hook.beforeAddLiquidity(
            address(0xBEEF),
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -100_000,
                tickUpper: 100_000,
                liquidityDelta: 100e18,
                salt: bytes32(0)
            }),
            ""
        );
    }
}
