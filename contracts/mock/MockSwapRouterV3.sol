// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
}

contract MockSwapRouterV3 is ISwapRouter {
    address public immutable WETH9Address;
    uint256 public fixedPrice = 1 ether; // 1:1 for simplicity

    constructor(address _weth) {
        WETH9Address = _weth;
    }

    function WETH9() external view returns (address) {
        return WETH9Address;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut) {
        // Always return amountIn as amountOut for fixed price
        return params.amountIn;
    }
}
