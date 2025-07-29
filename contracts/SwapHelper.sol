// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC20PermitFull.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniversalRouter.sol";
import "./TreasuryManager.sol";

/**
 * @title SwapHelper
 * @notice Helper contract for token preparation, Uniswap V3 swapping, and WETH operations
 * @dev Abstract contract that provides functionality for:
 *      - ERC-2612 permit processing and token transfers
 *      - Uniswap V3 token swaps to WETH
 *      - WETH unwrapping to ETH
 *      Works with any ERC-20 token that supports ERC-2612 permit functionality.
 *      Expects the inheriting contract to provide universalRouter and WETH variables.
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
        // Only approve permit2 if token is not WETH (since we won't swap WETH)  
        if (tokenIn != WETH) {
            token.safeIncreaseAllowance(address(permit2), amountIn);
        }
        permit2.approve(tokenIn, universalRouter, uint160(amountIn), uint48(deadline));
    }

    /// @notice Validates that inputs contain valid data for WETH swap
    /// @dev Internal function that checks inputs are not empty and path ends with WETH
    /// @param path The encoded path for the swap, must end with WETH address
    function _validateInputParams(bytes memory path) internal view {        
        if (path.length == 0) {
            revert Errors.InvalidSwapPath();
        }
        
        // Path should end with WETH (last 20 bytes)
        if (path.length < 20) {
            revert Errors.InvalidSwapPath();
        }
        
        // Extract the last 20 bytes of the path (output token)
        // Convert the last 20 bytes to an address
        bytes memory lastBytes = new bytes(20);
        for (uint256 i = 0; i < 20; i++) {
            lastBytes[i] = path[path.length - 20 + i];
        }
        
        address outputToken;
        assembly {
            outputToken := mload(add(lastBytes, 20))
        }
        
        if (outputToken != WETH) {
            revert Errors.InvalidOutputToken();
        }
    }

    /// @notice Executes a swap to receive ETH directly from Universal Router
    /// @dev Internal function that performs swap using provided commands and inputs.
    /// @param commands The encoded commands for UniversalRouter execution
    /// @param inputs The encoded inputs array corresponding to the commands
    /// @param deadline The expiration timestamp for the swap transaction
    /// @return ethReceived The actual amount of ETH received from the swap and unwrap
    function _swapToWETH(
        bytes memory commands,
        bytes[] memory inputs,
        uint256 deadline
    ) internal returns (uint256 ethReceived) {
        // Get initial ETH balance (since Universal Router returns ETH directly)
        uint256 initialETHBalance = address(this).balance;
        
        // Execute the swap through UniversalRouter
        IUniversalRouter(universalRouter).execute(commands, inputs, deadline);
        
        // Calculate the amount of ETH received
        uint256 finalETHBalance = address(this).balance;
        ethReceived = finalETHBalance - initialETHBalance;
    }
}
