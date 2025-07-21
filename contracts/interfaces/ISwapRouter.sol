// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Uniswap V3 SwapRouter Interface
/// @notice Interface for the Uniswap V3 SwapRouter contract
/// @dev Provides functions for executing token swaps on Uniswap V3 protocol
interface ISwapRouter {
    /// @notice Parameters for exactInputSingle swaps
    /// @dev Used to specify all parameters needed for a single-hop exact input swap
    struct ExactInputSingleParams {
        /// @notice The address of the input token
        address tokenIn;
        /// @notice The address of the output token
        address tokenOut;
        /// @notice The fee tier of the pool (e.g., 3000 for 0.3%)
        uint24 fee;
        /// @notice The address that will receive the output tokens
        address recipient;
        /// @notice The deadline by which the swap must be executed
        uint256 deadline;
        /// @notice The exact amount of input tokens to swap
        uint256 amountIn;
        /// @notice The minimum amount of output tokens to receive
        uint256 amountOutMinimum;
        /// @notice The price limit for the swap (0 = no limit)
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Executes a single exact-input swap
    /// @dev Swaps an exact amount of input tokens for as many output tokens as possible
    /// @param params The swap parameters encapsulated in ExactInputSingleParams
    /// @return amountOut The amount of output tokens received from the swap
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    /// @notice Returns the address of the WETH9 token contract
    /// @dev Used to identify the canonical WETH token for the router
    /// @return The address of the WETH9 contract
    function WETH9() external pure returns (address);
}
