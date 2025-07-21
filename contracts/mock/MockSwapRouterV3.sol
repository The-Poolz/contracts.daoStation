// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Uniswap V3 SwapRouter Interface for Mock Implementation
/// @notice Minimal interface needed for the mock swap router
/// @dev Contains only the structs and functions needed for testing
interface ISwapRouter {
    /// @notice Parameters for exactInputSingle swaps
    /// @dev Struct used to encapsulate swap parameters
    struct ExactInputSingleParams {
        /// @notice The address of the input token
        address tokenIn;
        /// @notice The address of the output token
        address tokenOut;
        /// @notice The fee tier of the pool
        uint24 fee;
        /// @notice The address that will receive the output tokens
        address recipient;
        /// @notice The deadline by which the swap must be executed
        uint256 deadline;
        /// @notice The exact amount of input tokens to swap
        uint256 amountIn;
        /// @notice The minimum amount of output tokens to receive
        uint256 amountOutMinimum;
        /// @notice The price limit for the swap
        uint160 sqrtPriceLimitX96;
    }
}

/// @title Mock Uniswap V3 SwapRouter
/// @notice A simplified mock implementation of Uniswap V3 SwapRouter for testing
/// @dev Provides basic swap functionality with 1:1 exchange rate for simplicity
///      WARNING: This is for testing only and should never be used in production
contract MockSwapRouterV3 is ISwapRouter {
    /// @notice The address of the WETH token this router uses
    /// @dev Set during construction and returned by the WETH9() function
    address public immutable WETH9Address;
    
    /// @notice Fixed exchange rate used for all swaps (1:1 for simplicity)
    /// @dev In a real router, this would be determined by pool prices and liquidity
    uint256 public fixedPrice = 1 ether; // 1:1 for simplicity

    /// @notice Creates a new mock swap router
    /// @dev Sets the WETH address that will be used for all WETH-related operations
    /// @param _weth The address of the WETH token contract
    constructor(address _weth) {
        WETH9Address = _weth;
    }

    /// @notice Returns the address of the WETH token
    /// @dev Implementation of ISwapRouter interface function
    /// @return The address of the WETH9 contract
    function WETH9() external view returns (address) {
        return WETH9Address;
    }

    /// @notice Executes a mock token swap with 1:1 exchange rate
    /// @dev Simplified swap implementation for testing. Always uses 1:1 exchange rate
    ///      regardless of the actual tokens involved. Transfers input token from recipient
    ///      and sends output token back to recipient.
    /// @param params The swap parameters containing token addresses, amounts, and recipient
    /// @return amountOut The amount of output tokens sent (always equals amountIn in this mock)
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut) {
        // Transfer input token from recipient (should be this contract)
        IERC20 tokenIn = IERC20(params.tokenIn);
        tokenIn.transferFrom(params.recipient, address(this), params.amountIn);
        
        // Calculate output amount (1:1 for simplicity)
        amountOut = params.amountIn;
        
        // Transfer WETH to recipient
        IERC20 weth = IERC20(params.tokenOut);
        require(weth.transfer(params.recipient, amountOut), "WETH transfer failed");
        
        return amountOut;
    }
}
