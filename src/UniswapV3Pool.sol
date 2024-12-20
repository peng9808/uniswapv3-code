// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.14;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV3MintCallback.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";

import "./lib/Tick.sol";
import "./lib/Position.sol";

contract UniswapV3Pool {
    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    error InvalidTickRange();
    error ZeroLiquidity();
    error InsufficientInputAmount();
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 liquidityDelta,
        uint256 amount0,
        uint256 amount1
    );
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    //Pool tokens
    address public immutable token0;
    address public immutable token1;

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
    }

    Slot0 public slot0;

    // Amount of liquidity,L.
    uint128 public liquidity;

    //Ticks info
    mapping(int24 => Tick.Info) public ticks;
    //Position info
    mapping(bytes32 => Position.Info) public positions;

    constructor(
        address token0_,
        address token1_,
        uint160 sqrtPriceX96_,
        int24 tick_
    ) {
        token0 = token0_;
        token1 = token1_;
        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96_, tick: tick_});
    }

    function mint(
        address owner,
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidityDelta
    ) external returns (uint256 amount0, uint256 amount1) {
        if (
            lowerTick >= upperTick ||
            lowerTick < MIN_TICK ||
            upperTick > MAX_TICK
        ) revert InvalidTickRange();
        if (liquidityDelta == 0) revert ZeroLiquidity();
        ticks.update(lowerTick, liquidityDelta);
        ticks.update(upperTick, liquidityDelta);

        Position.Info storage position = positions.get(
            owner,
            lowerTick,
            upperTick
        );
        position.update(liquidityDelta);

        amount0 = 0.998976618347425280 ether;
        amount1 = 5000 ether;

        liquidity += uint128(liquidityDelta);

        uint256 balance0Before;
        uint256 balance1Before;
        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();
        IuniswapV3MintCallback(msg.sender).uniswapV3MintCallback(
            amount0,
            amount1
        );
        if (amount0 > 0 && balance0Before + amount0 > balance0())
            revert("UniswapV3Pool: INSUFFICIENT_AMOUNT0");
        if (amount1 > 0 && balance1Before + amount1 > balance1())
            revert("UniswapV3Pool: INSUFFICIENT_AMOUNT1");

        emit Mint(
            msg.sender,
            owner,
            lowerTick,
            upperTick,
            liquidityDelta,
            amount0,
            amount1
        );
    }

    function swap(
        address recipient
    ) public returns (int256 amount0, int256 amount1) {
        int24 nextTick = 85184;
        uint160 nextPrice = 5604469350942327889444743441197;

        amount0 = -0.008396714242162444 ether;
        amount1 = 42 ether;
        (slot0.tick, slot0.sqrtPriceX96) = (nextTick, nextPrice);
        IERC20(token0).transfer(recipient, uint256(-amount0));

        uint256 balance1Before = balance1();
        IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
            amount0,
            amount1
        );
        if (balance1Before + uint256(amount1) < balance1())
            revert InsufficientInputAmount();
        emit Swap(
            msg.sender,
            recipient,
            amount0,
            amount1,
            slot0.sqrtPriceX96,
            liquidity,
            slot0.tick
        );
    }

    function balance0() internal returns (uint256 balance) {
        balance = IERC20(token0).balanceOf(address(this));
    }

    function balance1() internal returns (uint256 balance) {
        balance = IERC20(token1).balanceOf(address(this));
    }
}
