// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../TreasuryManager.sol";

contract TreasuryManagerTest is TreasuryManager {
    constructor(address universalRouterAddress, address wethAddress, address initialOwner) 
        PermitSwapExecutorState(universalRouterAddress, wethAddress)
        Ownable(initialOwner) 
    {
        // Constructor now properly calls parent constructors to set immutable variables
    }

    // Implement required interface functions as dummy implementations for testing
    function setMaintainer(address maintainer, bool allowed) external override {
        // Dummy implementation for testing
    }

    function executeSwap(
        address tokenIn,
        bytes calldata commands,
        bytes[] calldata inputs,
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
        address user
    )
        external
        returns (
            uint256 treasuryFee,
            uint256 userAmount,
            uint256 maintainerAmount
        )
    {
        return _distributeETH(ethBalance, user, msg.sender);
    }

    function test_depositETH() external payable {}

    receive() external payable {}
}
