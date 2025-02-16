import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployFactoryExchange = buildModule("DeployFactoryExchange", (m) => {
  const deployer = m.getAccount(0);
  const idleTokenAddress = "0x208554bF4BaA0fd678e5EA500253a84c64C72DaF"; // Ganti dengan IDLE Token yang sesuai

  const factoryExchange = m.contract("FactoryExchange", [idleTokenAddress, deployer]);

  return { factoryExchange };
});

export default DeployFactoryExchange;
