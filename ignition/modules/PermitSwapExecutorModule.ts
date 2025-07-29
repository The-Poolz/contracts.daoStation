// Hardhat Ignition module for deploying PermitSwapExecutor
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const PermitSwapExecutorModule = buildModule("PermitSwapExecutorModule", (m) => {
  // Parameters for deployment - updated to match constructor signature
  const universalRouter = m.getParameter("universalRouter");
  const weth = m.getParameter("weth");
  const permit2 = m.getParameter("permit2");

  const permitSwapExecutor = m.contract("PermitSwapExecutor", [universalRouter, weth, permit2]);

  return { permitSwapExecutor };
});

export default PermitSwapExecutorModule;
