const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("YieldVerifier", function () {
  let YieldVerifier;
  let verifier;
  let owner;
  let verifierRole;
  let strategy;

  beforeEach(async function () {
    [owner, strategy] = await ethers.getSigners();
    YieldVerifier = await ethers.getContractFactory("YieldVerifier");
    verifier = await YieldVerifier.deploy();
    await verifier.deployed();

    verifierRole = await verifier.VERIFIER_ROLE();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await verifier.hasRole(await verifier.DEFAULT_ADMIN_ROLE(), owner.address)).to.equal(true);
    });

    it("Should grant verifier role to owner", async function () {
      expect(await verifier.hasRole(verifierRole, owner.address)).to.equal(true);
    });
  });

  describe("Strategy Data Updates", function () {
    it("Should update strategy data correctly", async function () {
      const yield = ethers.utils.parseEther("100");
      const depositAmount = ethers.utils.parseEther("1000");
      const withdrawalAmount = ethers.utils.parseEther("0");

      await verifier.updateStrategyData(
        strategy.address,
        yield,
        depositAmount,
        withdrawalAmount
      );

      const metrics = await verifier.getStrategyMetrics(strategy.address);
      expect(metrics.totalYield).to.equal(yield);
      expect(metrics.depositAmount).to.equal(depositAmount);
    });

    it("Should calculate performance metrics correctly", async function () {
      // Add multiple data points
      for (let i = 0; i < 5; i++) {
        const yield = ethers.utils.parseEther(String(100 + i * 10));
        const depositAmount = ethers.utils.parseEther("1000");
        
        await verifier.updateStrategyData(
          strategy.address,
          yield,
          depositAmount,
          0
        );

        // Simulate time passing
        await ethers.provider.send("evm_increaseTime", [86400]); // 1 day
        await ethers.provider.send("evm_mine");
      }

      const metrics = await verifier.getStrategyMetrics(strategy.address);
      expect(metrics.performanceScore).to.be.gt(0);
      expect(metrics.benchmarkYield).to.be.gt(0);
    });

    it("Should store historical data correctly", async function () {
      const yield = ethers.utils.parseEther("100");
      const depositAmount = ethers.utils.parseEther("1000");

      await verifier.updateStrategyData(
        strategy.address,
        yield,
        depositAmount,
        0
      );

      const timestamps = await verifier.getStrategyTimestamps(strategy.address);
      expect(timestamps.length).to.equal(1);

      const historicalData = await verifier.getHistoricalData(strategy.address, timestamps[0]);
      expect(historicalData.yield).to.equal(yield);
      expect(historicalData.depositAmount).to.equal(depositAmount);
    });
  });

  describe("Access Control", function () {
    it("Should prevent non-verifiers from updating data", async function () {
      const [_, nonVerifier] = await ethers.getSigners();
      await expect(
        verifier.connect(nonVerifier).updateStrategyData(
          strategy.address,
          ethers.utils.parseEther("100"),
          ethers.utils.parseEther("1000"),
          0
        )
      ).to.be.revertedWith("AccessControl");
    });
  });
});