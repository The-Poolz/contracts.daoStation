// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC20PermitFull.sol";
import "./interfaces/ISwapRouter.sol";


contract PermitSwapExecutor is Ownable {
    using SafeERC20 for IERC20PermitFull;
    address public immutable uniswapRouter;
    address public immutable treasury;
    address public immutable WETH;
    mapping(address => bool) public isMaintainer;

    event MaintainerSet(address indexed maintainer, bool allowed);
    event SwapExecuted(
        address indexed user,
        address indexed tokenIn,
        uint amountIn,
        uint ethOut,
        address referrer,
        address maintainer
    );

    modifier onlyMaintainer() {
        require(isMaintainer[msg.sender], "Not maintainer");
        _;
    }

    constructor(address _uniswapRouter, address _treasury, address initialOwner) Ownable(initialOwner) {
        require(_uniswapRouter != address(0) && _treasury != address(0), "Zero address");
        uniswapRouter = _uniswapRouter;
        treasury = _treasury;
        WETH = ISwapRouter(_uniswapRouter).WETH9();
    }

    function setMaintainer(address maintainer, bool allowed) external onlyOwner {
        isMaintainer[maintainer] = allowed;
        emit MaintainerSet(maintainer, allowed);
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
    ) private {
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
    ) private returns (uint256 wethReceived) {
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
    ) external onlyMaintainer {
        require(user != address(0), "Zero user");
        require(block.timestamp <= deadline, "Expired");
        // prepare token: permit, transfer, and approve        
        _prepareToken(tokenIn, user, amountIn, deadline, v, r, s);
        // 4. Swap to WETH (Uniswap V3)
        uint wethReceived = _swapToWETH(tokenIn, poolFee, amountIn, amountOutMin, sqrtPriceLimitX96, deadline);
        // 5. Unwrap WETH to ETH
        (bool success,) = WETH.call(abi.encodeWithSignature("withdraw(uint256)", wethReceived));
        require(success, "WETH withdraw failed");
        uint ethBalance = address(this).balance;
        require(ethBalance > 0, "No ETH");
        // 6. Split ETH
        uint referrerAmt = ethBalance / 100;
        uint maintainerAmt = ethBalance / 100;
        uint treasuryAmt = ethBalance / 100;
        uint userAmt = ethBalance - referrerAmt - maintainerAmt - treasuryAmt;
        if (referrer != address(0)) {
            (bool sent1,) = referrer.call{value: referrerAmt}("");
            require(sent1, "Referrer send failed");
        } else {
            userAmt += referrerAmt;
        }
        (bool sent2,) = msg.sender.call{value: maintainerAmt}("");
        require(sent2, "Maintainer send failed");
        (bool sent3,) = treasury.call{value: treasuryAmt}("");
        require(sent3, "Treasury send failed");
        (bool sent4,) = user.call{value: userAmt}("");
        require(sent4, "User send failed");
        emit SwapExecuted(user, tokenIn, amountIn, ethBalance, referrer, msg.sender);
    }

    receive() external payable {}
    fallback() external payable {}
}
