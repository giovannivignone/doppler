// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { PoolId, PoolIdLibrary } from "@v4-core/types/PoolId.sol";
import { PoolKey } from "@v4-core/types/PoolKey.sol";
import { IHooks } from "@v4-core/interfaces/IHooks.sol";
import { Currency } from "@v4-core/types/Currency.sol";
import { TickMath } from "@v4-core/libraries/TickMath.sol";
import { PoolManager } from "@v4-core/PoolManager.sol";
import { BaseTest, TestERC20 } from "test/shared/BaseTest.sol";
import { DopplerImplementation } from "test/shared/DopplerImplementation.sol";
import {
    MAX_TICK_SPACING,
    MAX_PRICE_DISCOVERY_SLUGS,
    InvalidTickRange,
    InvalidGamma,
    InvalidEpochLength,
    InvalidTimeRange,
    InvalidTickSpacing,
    InvalidNumPDSlugs,
    InvalidProceedLimits
} from "src/Doppler.sol";

using PoolIdLibrary for PoolKey;

contract DopplerConstructorTest is BaseTest {
    function setUp() public override {
        manager = new PoolManager(address(this));
        _deployTokens();
    }

    function deployDoppler(
        bytes4 selector,
        DopplerConfig memory config,
        int24 _startTick,
        int24 _endTick,
        bool _isToken0
    ) internal {
        isToken0 = _isToken0;

        (token0, token1) = isToken0 ? (asset, numeraire) : (numeraire, asset);
        TestERC20(isToken0 ? token0 : token1).transfer(address(hook), config.numTokensToSell);
        vm.label(address(token0), "Token0");
        vm.label(address(token1), "Token1");

        key = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: config.fee,
            tickSpacing: config.tickSpacing,
            hooks: IHooks(address(hook))
        });
        if (selector != 0) {
            vm.expectRevert(selector);
        }

        int24 startTick = _startTick != 0 ? _startTick : isToken0 ? DEFAULT_START_TICK : -DEFAULT_START_TICK;
        int24 endTick = _endTick != 0 ? _endTick : isToken0 ? -DEFAULT_END_TICK : DEFAULT_END_TICK;
        deployCodeTo(
            "DopplerImplementation.sol:DopplerImplementation",
            abi.encode(
                manager,
                config.numTokensToSell,
                config.minimumProceeds,
                config.maximumProceeds,
                config.startingTime,
                config.endingTime,
                startTick,
                endTick,
                config.epochLength,
                config.gamma,
                isToken0,
                config.numPDSlugs,
                hook,
                address(0xbeef) // airlock
            ),
            address(hook)
        );
        if (selector == 0) {
            poolId = key.toId();

            manager.initialize(key, TickMath.getSqrtPriceAtTick(startTick));
        }
    }

    function testConstructor_RevertsInvalidTickRange_WhenIsToken0_AndStartingTickLEEndingTick() public {
        vm.skip(true);
        bool _isToken0 = true;
        int24 _startTick = 100;
        int24 _endTick = 101;

        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;

        deployDoppler(InvalidTickRange.selector, config, _startTick, _endTick, _isToken0);
    }

    function testConstructor_RevertsInvalidTickRange_WhenNotIsToken0_AndStartingTickGEEndingTick() public {
        vm.skip(true);
        bool _isToken0 = false;
        int24 _startTick = 200;
        int24 _endTick = 100;

        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;

        deployDoppler(InvalidTickRange.selector, config, _startTick, _endTick, _isToken0);
    }

    function testConstructor_RevertsInvalidGamma_tickDeltaNotDivisibleByEpochsTimesGamma() public {
        vm.skip(true);
        bool _isToken0 = true;
        int24 _startTick = 200;
        int24 _endTick = 100;
        int24 _gamma = 5;
        uint256 _startingTime = 1000;
        uint256 _endingTime = 5000;
        uint256 _epochLength = 1000;

        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        config.gamma = _gamma;
        config.startingTime = _startingTime;
        config.endingTime = _endingTime;
        config.epochLength = _epochLength;

        deployDoppler(InvalidGamma.selector, config, _startTick, _endTick, _isToken0);
    }

    function testConstructor_RevertsInvalidTickSpacing_WhenTickSpacingGreaterThanMax() public {
        vm.skip(true);
        int24 maxTickSpacing = MAX_TICK_SPACING;
        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        config.tickSpacing = int24(maxTickSpacing + 1);

        deployDoppler(InvalidTickSpacing.selector, config, 0, 0, true);
    }

    function testConstructor_RevertsInvalidTimeRange_WhenStartingTimeGreaterThanOrEqualToEndingTime() public {
        vm.skip(true);
        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        config.startingTime = 1000;
        config.endingTime = 1000;

        deployDoppler(InvalidTimeRange.selector, config, DEFAULT_START_TICK, DEFAULT_START_TICK, true);
    }

    function testConstructor_RevertsInvalidGamma_WhenGammaCalculationZero() public {
        vm.skip(true);
        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        config.startingTime = 1000;
        config.endingTime = 1001;
        config.epochLength = 1;
        config.gamma = 0;

        deployDoppler(InvalidGamma.selector, config, 0, 0, true);
    }

    function testConstructor_RevertsInvalidEpochLength_WhenTimeDeltaNotDivisibleByEpochLength() public {
        vm.skip(true);
        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        config.epochLength = 3000;

        deployDoppler(InvalidEpochLength.selector, config, DEFAULT_START_TICK, DEFAULT_START_TICK, true);
    }

    function testConstructor_RevertsInvalidGamma_WhenGammaNotDivisibleByTickSpacing() public {
        vm.skip(true);
        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        config.gamma += 1;

        deployDoppler(InvalidGamma.selector, config, 0, 0, true);
    }

    function testConstructor_RevertsInvalidGamma_WhenGammaTimesTotalEpochsNotDivisibleByTotalTickDelta() public {
        vm.skip(true);
        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        config.gamma = 10;
        config.startingTime = 1000;
        config.endingTime = 5000;
        config.epochLength = 1000;

        deployDoppler(InvalidGamma.selector, config, 0, 0, true);
    }

    function testConstructor_RevertsInvalidGamma_WhenGammaIsNegative() public {
        vm.skip(true);
        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        config.gamma = -1;

        deployDoppler(InvalidGamma.selector, config, 0, 0, true);
    }

    function testConstructor_RevertsInvalidNumPDSlugs_WithZeroSlugs() public {
        vm.skip(true);
        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        config.numPDSlugs = 0;

        deployDoppler(InvalidNumPDSlugs.selector, config, 0, 0, true);
    }

    function testConstructor_RevertsInvalidNumPDSlugs_GreaterThanMax() public {
        vm.skip(true);
        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        config.numPDSlugs = MAX_PRICE_DISCOVERY_SLUGS + 1;

        deployDoppler(InvalidNumPDSlugs.selector, config, 0, 0, true);
    }

    function testConstructor_RevertsInvalidProceedLimits_WhenMinimumProceedsGreaterThanMaximumProceeds() public {
        vm.skip(true);
        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        config.minimumProceeds = 100;
        config.maximumProceeds = 0;

        deployDoppler(InvalidProceedLimits.selector, config, 0, 0, true);
    }

    function testConstructor_Succeeds_WithValidParameters() public {
        vm.skip(true);
        DopplerConfig memory config = DEFAULT_DOPPLER_CONFIG;
        deployDoppler(0, config, 0, 0, asset < numeraire);
    }
}
