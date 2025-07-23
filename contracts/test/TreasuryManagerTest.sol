// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../TreasuryManager.sol";

contract TreasuryManagerTest is TreasuryManager {
    constructor(address uniswapRouterAddress, address wethAddress, address initialOwner) 
        Ownable(initialOwner) 
    {
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

    function test_distributeETH(
        uint256 ethBalance,
        address user,
        address maintainer
    )
        external
        returns (
            uint256 treasuryFee,
            uint256 userAmount,
            uint256 maintainerAmount
        )
    {
        return _distributeETH(ethBalance, user, maintainer);
    }

    function test_depositETH() external payable {}

    receive() external payable {}
}
