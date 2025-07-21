// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC20PermitFull.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/Errors.sol";

/**
 * @title SwapHelper
 * @dev Helper functions for token preparation, swapping, and WETH operations
 */
abstract contract SwapHelper {
    using SafeERC20 for IERC20PermitFull;
    
    address public immutable uniswapRouter;
    address public immutable WETH;

    constructor(address _uniswapRouter) {
        if (_uniswapRouter == address(0)) {
            revert Errors.ZeroRouterAddress();
        }
        uniswapRouter = _uniswapRouter;
        WETH = ISwapRouter(_uniswapRouter).WETH9();
    }

    /// @dev Permit, transfer from user, and approve router in one call
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
        token.permit(user, address(this), amountIn, deadline, v, r, s);
        token.safeTransferFrom(user, address(this), amountIn);
        // Only approve router if token is not WETH (since we won't swap WETH)
        if (tokenIn != WETH) {
            token.safeIncreaseAllowance(uniswapRouter, amountIn);
        }
    }

    /// @dev Executes a Uniswap V3 exactInputSingle swap of `amountIn` tokenIn for WETH
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

    /// @dev Unwraps WETH to ETH and returns the ETH balance
    function _unwrapWETH(uint256 wethAmount) internal {
        IWETH(WETH).withdraw(wethAmount);
    }
}
