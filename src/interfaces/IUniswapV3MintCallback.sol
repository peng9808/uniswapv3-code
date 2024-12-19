// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

interface IuniswapV3MintCallback {
    function uniswapV3MintCallback(uint256 amount0, uint256 amount1) external;
}
