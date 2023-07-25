// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TokenFixture} from "@uniswap/v4-core/test/foundry-tests/utils/TokenFixture.sol";
import {PoolManager, IPoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {NonfungiblePositionManager, INonfungiblePositionManager} from "../contracts/NonfungiblePositionManager.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/libraries/CurrencyLibrary.sol";
import {MockERC20} from "@uniswap/v4-core/test/foundry-tests/utils/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NonfungiblePositionManagerTest is Test, TokenFixture {
    using PoolIdLibrary for IPoolManager.PoolKey;

    event ModifyPosition(
        PoolId indexed poolId, address indexed sender, int24 tickLower, int24 tickUpper, int256 liquidityDelta
    );

    PoolManager manager;
    NonfungiblePositionManager nonfungiblePositionManager;

    uint160 constant SQRT_RATIO_1_1 = 79228162514264337593543950336;
    uint256 constant MAX_UINT256 = type(uint256).max;

    function setUp() public {
        initializeTokens();
        manager = new PoolManager(500000);
        nonfungiblePositionManager = new NonfungiblePositionManager(manager, address(1));

        MockERC20(Currency.unwrap(currency0)).mint(address(this), 10 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 10 ether);
        MockERC20(Currency.unwrap(currency0)).approve(address(nonfungiblePositionManager), 10 ether);
        MockERC20(Currency.unwrap(currency1)).approve(address(nonfungiblePositionManager), 10 ether);
    }

    // Add 1 currency0 of liquidity.
    function testMintCurrency0() public {
        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            tickSpacing: 60
        });

        manager.initialize(key, SQRT_RATIO_1_1);

        vm.expectEmit(true, true, true, true);
        emit ModifyPosition(key.toId(), address(nonfungiblePositionManager), 0, 60, 333850249709699449134);

        nonfungiblePositionManager.mint(
            INonfungiblePositionManager.MintParams({
                poolKey: key,
                tickLower: 0,
                tickUpper: 60,
                amount0Desired: 1 ether,
                amount1Desired: 0,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: MAX_UINT256
            })
        );

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(this)), 9 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(this)), 10 ether);
    }

    // Add 1 currency1 of liquidity.
    function testMintCurrency1() public {
        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            tickSpacing: 60
        });

        manager.initialize(key, SQRT_RATIO_1_1);

        vm.expectEmit(true, true, true, true);
        emit ModifyPosition(key.toId(), address(nonfungiblePositionManager), -60, 0, 333850249709699449134);

        nonfungiblePositionManager.mint(
            INonfungiblePositionManager.MintParams({
                poolKey: key,
                tickLower: -60,
                tickUpper: 0,
                amount0Desired: 0,
                amount1Desired: 1 ether,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: MAX_UINT256
            })
        );

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(this)), 10 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(this)), 9 ether);
    }

    // Add 1 currency0 and 1 currency1 of liquidity.
    function testMintCurrency0AndCurrency1() public {
        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            tickSpacing: 60
        });

        manager.initialize(key, SQRT_RATIO_1_1);

        vm.expectEmit(true, true, true, true);
        emit ModifyPosition(key.toId(), address(nonfungiblePositionManager), -60, 60, 333850249709699449134);

        nonfungiblePositionManager.mint(
            INonfungiblePositionManager.MintParams({
                poolKey: key,
                tickLower: -60,
                tickUpper: 60,
                amount0Desired: 1 ether,
                amount1Desired: 1 ether,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: MAX_UINT256
            })
        );

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(this)), 9 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(this)), 9 ether);
    }
}
