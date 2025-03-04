import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployIDLEPlatform = buildModule("DeployIDLEPlatform", (m) => {
  const deployer = m.getAccount(0);

  const initialSupply = m.getParameter("initialSupply", 1_000_000_000);

  const idleToken = m.contract("IDLEToken", [deployer, initialSupply]);

  const factoryExchange = m.contract("FactoryExchange", [deployer, idleToken]);

  const aiInteraction = m.contract("AIInteraction", [idleToken]);

  // Transfer 300.000.000 IDLE ke FactoryExchange setelah deployment
  m.call(idleToken, "transfer", [factoryExchange, 300_000_000n * 10n ** 18n], {
    from: deployer,
  });

  m.call(idleToken, "approve", [factoryExchange, 300_000_000n * 10n ** 18n], { from: deployer });

  return { idleToken, factoryExchange, aiInteraction };
});

export default DeployIDLEPlatform;
