import { expect } from "chai";
import { ethers } from "hardhat";
import { IDLEToken, FactoryExchange, AIToken } from "../typechain-types";

describe("FactoryExchange & AIToken Integration Test", function () {
  let owner: any;
  let user: any;
  let idleToken: IDLEToken;
  let factoryExchange: FactoryExchange;
  let aiToken: AIToken;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy IDLE Token
    const IdleToken = await ethers.getContractFactory("IDLEToken");
    idleToken = (await IdleToken.deploy(owner.address, ethers.parseEther("1000000000"))) as IDLEToken;
    await idleToken.waitForDeployment();

    // Deploy FactoryExchange
    const FactoryExchange = await ethers.getContractFactory("FactoryExchange");
    factoryExchange = (await FactoryExchange.deploy(owner.address, await idleToken.getAddress())) as FactoryExchange;
    await factoryExchange.waitForDeployment();

    // Create AI Token
    const initialAiSupply = 1000000;
    const createTx = await factoryExchange.createToken("AI Token", "AIT", initialAiSupply);
    await createTx.wait();

    const aiTokenAddress = await factoryExchange.userTokens(owner.address);
    aiToken = (await ethers.getContractAt("AIToken", aiTokenAddress)) as AIToken;
  });

  it("should allow user to buy AI tokens with IDLE tokens", async function () {
    const idleAmountToBuy = ethers.parseEther("10");

    await idleToken.connect(owner).transfer(user.address, idleAmountToBuy);
    await idleToken.connect(user).approve(await factoryExchange.getAddress(), idleAmountToBuy);

    await expect(factoryExchange.connect(user).buyToken(await aiToken.getAddress(), idleAmountToBuy))
      .to.emit(factoryExchange, "TokenPurchased");

    const userAiBalance = await aiToken.balanceOf(user.address);
    console.log("User AI Token Balance:", userAiBalance.toString());
    expect(userAiBalance).to.equal(idleAmountToBuy * BigInt(150000));
  });
});
