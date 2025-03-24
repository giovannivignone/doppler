// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { PoolIdLibrary } from "@v4-core/types/PoolId.sol";
import { PoolKey } from "@v4-core/types/PoolKey.sol";
import { BaseTest } from "test/shared/BaseTest.sol";
import { Position } from "src/Doppler.sol";

contract DopplerBeforeInitializeTest is BaseTest {
    using PoolIdLibrary for PoolKey;

    // =========================================================================
    //                      beforeInitialize Unit Tests
    // =========================================================================

    function test_BeforeInitialize() public view { }
}
