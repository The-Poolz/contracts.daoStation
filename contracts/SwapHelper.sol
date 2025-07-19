// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC20PermitFull.sol";
import "./interfaces/ISwapRouter.sol";

/**
 * @title SwapHelper
 * @dev Helper functions for token preparation, swapping, and WETH operations
 */
abstract contract SwapHelper {
    using SafeERC20 for IERC20PermitFull;
    
    address public immutable uniswapRouter;
    address public immutable WETH;

    constructor(address _uniswapRouter) {
        require(_uniswapRouter != address(0), "Zero router address");
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
        token.safeIncreaseAllowance(uniswapRouter, amountIn);
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
    function _unwrapWETH(uint256 wethAmount) internal returns (uint256 ethBalance) {
        (bool success,) = WETH.call(abi.encodeWithSignature("withdraw(uint256)", wethAmount));
        require(success, "WETH withdraw failed");
        ethBalance = address(this).balance;
        require(ethBalance >= wethAmount, "No ETH");
    }
}
