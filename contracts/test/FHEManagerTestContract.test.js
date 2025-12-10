const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FHEManagerTestContract", function () {
  let testContract;
  let owner;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    
    const FHEManagerTestContract = await ethers.getContractFactory("FHEManagerTestContract");
    testContract = await FHEManagerTestContract.deploy();
    await testContract.waitForDeployment();
  });

  describe("Encryption Tests", function () {
    it("Should encrypt basis points successfully", async function () {
      const basisPoints = 500; // 5%
      const tx = await testContract.testEncryptBasisPoints(basisPoints);
      const receipt = await tx.wait();
      
      // Check event was emitted
      const event = receipt.logs.find(log => {
        try {
          return testContract.interface.parseLog(log).name === "BasisPointsEncrypted";
        } catch {
          return false;
        }
      });
      
      expect(event).to.not.be.undefined;
    });

    it("Should revert on invalid basis points (> 10000)", async function () {
      const invalidBasisPoints = 10001;
      await expect(
        testContract.testEncryptBasisPoints(invalidBasisPoints)
      ).to.be.revertedWith("FHEManager: Invalid basis points");
    });

    it("Should encrypt price successfully", async function () {
      const price = ethers.parseEther("2000"); // $2000
      const encrypted = await testContract.testEncryptPrice(price);
      expect(encrypted).to.not.equal(0);
    });
  });

  describe("Threshold Comparison Tests", function () {
    it("Should return true when IL exceeds threshold", async function () {
      const currentIL = 600; // 6%
      const threshold = 500; // 5%
      
      const shouldExit = await testContract.testCompareThresholds(currentIL, threshold);
      expect(shouldExit).to.be.true;
    });

    it("Should return false when IL is below threshold", async function () {
      const currentIL = 300; // 3%
      const threshold = 500; // 5%
      
      const shouldExit = await testContract.testCompareThresholds(currentIL, threshold);
      expect(shouldExit).to.be.false;
    });

    it("Should return false when IL equals threshold", async function () {
      const currentIL = 500; // 5%
      const threshold = 500; // 5%
      
      const shouldExit = await testContract.testCompareThresholds(currentIL, threshold);
      expect(shouldExit).to.be.false;
    });
  });

  describe("FHE.req Tests (Approach 2)", function () {
    it("Should not revert when threshold is breached", async function () {
      const currentIL = 600; // 6%
      const threshold = 500; // 5%
      
      await expect(
        testContract.testRequireThresholdBreached(currentIL, threshold)
      ).to.not.be.reverted;
    });

    it("Should revert when threshold is not breached", async function () {
      const currentIL = 300; // 3%
      const threshold = 500; // 5%
      
      await expect(
        testContract.testRequireThresholdBreached(currentIL, threshold)
      ).to.be.reverted;
    });
  });

  describe("Price Bounds Tests", function () {
    it("Should return false when price is within bounds", async function () {
      const currentPrice = ethers.parseEther("2500");
      const upperBound = ethers.parseEther("3000");
      const lowerBound = ethers.parseEther("2000");
      
      const isOutOfBounds = await testContract.testComparePriceBounds(
        currentPrice,
        upperBound,
        lowerBound
      );
      
      expect(isOutOfBounds).to.be.false;
    });

    it("Should return true when price is above upper bound", async function () {
      const currentPrice = ethers.parseEther("3500");
      const upperBound = ethers.parseEther("3000");
      const lowerBound = ethers.parseEther("2000");
      
      const isOutOfBounds = await testContract.testComparePriceBounds(
        currentPrice,
        upperBound,
        lowerBound
      );
      
      expect(isOutOfBounds).to.be.true;
    });

    it("Should return true when price is below lower bound", async function () {
      const currentPrice = ethers.parseEther("1500");
      const upperBound = ethers.parseEther("3000");
      const lowerBound = ethers.parseEther("2000");
      
      const isOutOfBounds = await testContract.testComparePriceBounds(
        currentPrice,
        upperBound,
        lowerBound
      );
      
      expect(isOutOfBounds).to.be.true;
    });
  });

  describe("Comprehensive Tests", function () {
    it("Should pass all tests in runAllTests", async function () {
      const results = await testContract.runAllTests();
      
      // All tests should pass (return true)
      expect(results[0]).to.be.true; // Encryption test
      expect(results[1]).to.be.true; // 600 > 500 comparison
      expect(results[2]).to.be.true; // 300 < 500 comparison (negated)
      expect(results[3]).to.be.true; // Validation test
      expect(results[4]).to.be.true; // Price encryption test
    });
  });

  describe("Validation Tests", function () {
    it("Should validate encrypted threshold", async function () {
      const encrypted = await testContract.testEncryptBasisPoints(500);
      const isValid = await testContract.testValidateEncryptedThreshold(encrypted);
      expect(isValid).to.be.true;
    });
  });
});
