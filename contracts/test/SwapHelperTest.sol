// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../SwapHelper.sol";

contract SwapHelperTest is SwapHelper {
    constructor(address universalRouterAddress, address wethAddress, address initialOwner) 
        PermitSwapExecutorState(universalRouterAddress, wethAddress)
        Ownable(initialOwner) 
    {
        if (universalRouterAddress == address(0)) {
            revert Errors.ZeroRouterAddress();
        }
        // Constructor now properly calls parent constructors to set immutable variables
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
        uint256 deadline
    ) external returns (uint256 wethReceived) {
        return _swapToWETH(tokenIn, poolFee, amountIn, amountOutMin, deadline);
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
