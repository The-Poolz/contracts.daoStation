// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC20PermitFull.sol";
import "./interfaces/IWETH.sol";
import "./TreasuryManager.sol";

/**
 * @title SwapHelper
 * @notice Helper contract for token preparation, Uniswap V3 swapping, and WETH operations
 * @dev Abstract contract that provides functionality for:
 *      - ERC-2612 permit processing and token transfers
 *      - Uniswap V3 token swaps to WETH
 *      - WETH unwrapping to ETH
 *      Works with any ERC-20 token that supports ERC-2612 permit functionality.
 *      Expects the inheriting contract to provide uniswapRouter and WETH variables.
 */
abstract contract SwapHelper is TreasuryManager{
    using SafeERC20 for IERC20PermitFull;

    /// @notice Validates permit signature before executing permit
    /// @dev Internal function that checks signature validity and reverts if invalid
    /// @param tokenIn The address of the ERC-20 token to validate permit for
    /// @param user The address of the token owner who signed the permit
    /// @param amountIn The amount of tokens in the permit
    /// @param deadline The expiration timestamp for the permit signature
    /// @param v The recovery byte of the permit signature
    /// @param r Half of the ECDSA permit signature pair
    /// @param s Half of the ECDSA permit signature pair
    function _validatePermitSignature(
        IERC20PermitFull tokenIn,
        address user,
        uint256 amountIn,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bool isValid = isValidSignature(
            user,
            address(this),
            amountIn,
            deadline,
            tokenIn.nonces(user),
            tokenIn.DOMAIN_SEPARATOR(),
            v,
            r,
            s
        );
        
        if (!isValid) {
            revert Errors.InvalidPermitSignature();
        }
    }

    /// @notice Processes permit signature, transfers tokens, and approves router in one call
    /// @dev Internal function that handles the complete token preparation flow.
    ///      Validates permit signature before execution to ensure security.
    /// @param tokenIn The address of the ERC-20 token to prepare
    /// @param user The address of the token owner who signed the permit
    /// @param amountIn The amount of tokens to transfer and approve
    /// @param deadline The expiration timestamp for the permit signature
    /// @param v The recovery byte of the permit signature
    /// @param r Half of the ECDSA permit signature pair
    /// @param s Half of the ECDSA permit signature pair
    function _prepareToken(
        address tokenIn,
        address user,
        uint256 amountIn,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        IERC20PermitFull token = IERC20PermitFull(tokenIn);
        
        // Validate permit signature before execution
        _validatePermitSignature(token, user, amountIn, deadline, v, r, s);
        
        try token.permit(user, address(this), amountIn, deadline, v, r, s) {} catch {}
        token.safeTransferFrom(user, address(this), amountIn);
        // Only approve router if token is not WETH (since we won't swap WETH)
        if (tokenIn != WETH) {
            token.safeIncreaseAllowance(uniswapRouter, amountIn);
        }
    }

    /// @notice Executes a Uniswap V3 exact input swap from any token to WETH
    /// @dev Internal function that performs a single-hop swap using Uniswap V3's exactInputSingle
    /// @param tokenIn The address of the input token to swap from
    /// @param poolFee The fee tier of the Uniswap V3 pool (e.g., 3000 for 0.3%)
    /// @param amountIn The exact amount of input tokens to swap
    /// @param amountOutMin The minimum amount of WETH to receive (slippage protection)
    /// @param sqrtPriceLimitX96 The price limit for the swap in sqrt(price) * 2^96 format (0 = no limit)
    /// @param deadline The expiration timestamp for the swap transaction
    /// @return wethReceived The actual amount of WETH tokens received from the swap
    function _swapToWETH(
        address tokenIn,
        uint24 poolFee,
        uint256 amountIn,
        uint256 amountOutMin,
        uint160 sqrtPriceLimitX96,
        uint256 deadline
    ) internal returns (uint256 wethReceived) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: WETH,
            fee: poolFee,
            recipient: address(this),
            deadline: deadline,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        wethReceived = ISwapRouter(uniswapRouter).exactInputSingle(params);
    }

    /// @notice Unwraps WETH tokens to native ETH
    /// @dev Internal function that converts WETH tokens held by this contract to ETH.
    ///      The ETH will be available in this contract's balance after unwrapping.
    /// @param wethAmount The amount of WETH tokens to unwrap
    function _unwrapWETH(uint256 wethAmount) internal {
        IWETH(WETH).withdraw(wethAmount);
    }
}
