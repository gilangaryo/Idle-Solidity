import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployIDLEPlatform = buildModule("DeployIDLEPlatform", (m) => {
  const deployer = m.getAccount(0);

  const idleToken = m.contract("IDLEToken", [
    deployer,
    m.getParameter("initialSupply", 1_000_000_000),
  ]);

  const factoryExchange = m.contract("FactoryExchange", [deployer, idleToken]);

  const aiInteraction = m.contract("AIInteraction", [idleToken]);

  return { idleToken, factoryExchange, aiInteraction };
});

export default DeployIDLEPlatform;
