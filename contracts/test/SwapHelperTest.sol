// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../SwapHelper.sol";

/**
 * @title SwapHelperTest
 * @dev Test contract that exposes SwapHelper internal functions as public
 * @notice This contract should NEVER be deployed to mainnet - only for testing!
 */
contract SwapHelperTest is SwapHelper {
    
    constructor(address _uniswapRouter) SwapHelper(_uniswapRouter) {
        // Simple constructor - inherits from SwapHelper
    }

    /// @dev Test function to expose _prepareToken
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

    /// @dev Test function to expose _swapToWETH
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

    /// @dev Test function to expose _unwrapWETH
    function test_unwrapWETH(uint256 wethAmount) external returns (uint256 ethBalance) {
        return _unwrapWETH(wethAmount);
    }

    /// @dev Allow receiving ETH for testing
    receive() external payable {}
}
