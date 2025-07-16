// Hardhat Ignition module for deploying PermitSwapExecutor
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const PermitSwapExecutorModule = buildModule("PermitSwapExecutorModule", (m) => {
  // Parameters for deployment
  const uniswapRouter = m.getParameter("uniswapRouter");
  const treasury = m.getParameter("treasury");
  const initialOwner = m.getParameter("initialOwner");

  const permitSwapExecutor = m.contract("PermitSwapExecutor", [uniswapRouter, treasury, initialOwner]);

  return { permitSwapExecutor };
});

export default PermitSwapExecutorModule;
