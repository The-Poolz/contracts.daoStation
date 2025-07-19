// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../SwapHelper.sol";

contract SwapHelperTest is SwapHelper {
    
    constructor(address _uniswapRouter) SwapHelper(_uniswapRouter) {}

    function test_prepareToken(
        address tokenIn,
        address user,
        uint256 amountIn,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _prepareToken(tokenIn, user, amountIn, deadline, v, r, s);
    }

    function test_swapToWETH(
        address tokenIn,
        uint24 poolFee,
        uint256 amountIn,
        uint256 amountOutMin,
        uint160 sqrtPriceLimitX96,
        uint256 deadline
    ) external returns (uint256 wethReceived) {
        return _swapToWETH(tokenIn, poolFee, amountIn, amountOutMin, sqrtPriceLimitX96, deadline);
    }

    function test_unwrapWETH(uint256 wethAmount) external returns (uint256 ethBalance) {
        return _unwrapWETH(wethAmount);
    }

    function test_depositETH() external payable {}

    receive() external payable {}
}
