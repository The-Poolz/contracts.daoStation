// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TreasuryManager.sol";
import "./SwapHelper.sol";

/**
 * @title PermitSwapExecutor
 * @dev Main contract for executing permit-based token swaps to ETH with fee distribution
 */
contract PermitSwapExecutor is TreasuryManager, SwapHelper {
    mapping(address => bool) public isMaintainer;

    event MaintainerSet(address indexed maintainer, bool allowed);
    event SwapExecuted(
        address indexed user,
        address indexed tokenIn,
        uint amountIn,
        uint ethOut,
        uint userAmount,
        uint maintainerAmount,
        uint treasuryAmount,
        address referrer,
        address maintainer
    );

    modifier onlyMaintainer() {
        require(isMaintainer[msg.sender], "Not maintainer");
        _;
    }

    constructor(address _uniswapRouter, address initialOwner) 
        TreasuryManager()
        SwapHelper(_uniswapRouter)
        Ownable(initialOwner) 
    {
        // All validation is done in parent constructors
    }

    function setMaintainer(address maintainer, bool allowed) external onlyOwner {
        isMaintainer[maintainer] = allowed;
        emit MaintainerSet(maintainer, allowed);
    }

    function executeSwap(
        address tokenIn,
        uint24 poolFee,
        uint amountIn,
        uint amountOutMin,
        uint160 sqrtPriceLimitX96,
        address user,
        address referrer,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyMaintainer nonReentrant {
        require(user != address(0), "Zero user");
        require(block.timestamp <= deadline, "Expired");
        
        // prepare token: permit, transfer, and approve        
        _prepareToken(tokenIn, user, amountIn, deadline, v, r, s);
        
        uint wethReceived;
        // If input token is WETH, skip swap
        if (tokenIn == WETH) {
            wethReceived = amountIn;
        } else {
            // Swap to WETH (Uniswap V3)
            wethReceived = _swapToWETH(tokenIn, poolFee, amountIn, amountOutMin, sqrtPriceLimitX96, deadline);
        }
        
        // Unwrap WETH to ETH
        _unwrapWETH(wethReceived);
        
        // Distribute ETH (configurable fees to maintainer and treasury, rest to user)
        (uint256 treasuryFee, uint256 userAmt, uint256 maintainerAmt) = _distributeETH(wethReceived, user, msg.sender);
        
        emit SwapExecuted(user, tokenIn, amountIn, wethReceived, userAmt, maintainerAmt, treasuryFee, referrer, msg.sender);
    }

    receive() external payable {}
    fallback() external payable {}
}
