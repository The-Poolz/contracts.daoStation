// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../SwapHelper.sol";
import "../mock/MockPermit2.sol";
import "../interfaces/IWETH.sol";

contract SwapHelperTest is SwapHelper {
    constructor(address universalRouterAddress, address wethAddress, address permit2Address) 
        Ownable(_msgSender())
    {
        if (universalRouterAddress == address(0)) {
            revert Errors.ZeroRouterAddress();
        }
        if (wethAddress == address(0)) {
            revert Errors.ZeroWETHAddress();
        }
        if (permit2Address == address(0)) {
            revert Errors.ZeroPermit2Address();
        }
        universalRouter = universalRouterAddress;
        WETH = wethAddress;
        permit2 = IPermit2(permit2Address);
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
        bytes calldata commands,
        bytes[] calldata inputs,
        uint256 deadline
    ) external returns (uint256 wethReceived) {
        return _swapToWETH(commands, inputs, deadline);
    }

    function test_unwrapWETH(uint256 wethAmount) external {
        IWETH(WETH).withdraw(wethAmount);
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
