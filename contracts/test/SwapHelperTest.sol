// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../SwapHelper.sol";
import "../interfaces/Errors.sol";

contract SwapHelperTest is SwapHelper {
    constructor(address uniswapRouterAddress, address wethAddress, address initialOwner) 
        Ownable(initialOwner) 
    {
        if (uniswapRouterAddress == address(0)) {
            revert Errors.ZeroRouterAddress();
        }
        // Set the immutable variables
        uniswapRouter = uniswapRouterAddress;
        WETH = wethAddress;
    }

    // Implement required interface functions as dummy implementations for testing
    function setMaintainer(address maintainer, bool allowed) external override {
        // Dummy implementation for testing
    }

    function executeSwap(
        address tokenIn,
        uint24 poolFee,
        uint amountIn,
        uint amountOutMin,
        uint160 sqrtPriceLimitX96,
        address user,
        bytes calldata data,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // Dummy implementation for testing
    }

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

    function test_unwrapWETH(uint256 wethAmount) external {
        _unwrapWETH(wethAmount);
    }

    function test_isValidSignature(
        address user,
        address spender,
        uint256 amountIn,
        uint256 deadline,
        uint256 nonce,
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (bool) {
        return isValidSignature(user, spender, amountIn, deadline, nonce, domainSeparator, v, r, s);
    }

    function test_depositETH() external payable {}

    receive() external payable {}
}
