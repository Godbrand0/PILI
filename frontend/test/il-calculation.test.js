// Test file for IL calculation in frontend
const {
  sqrtPriceX96ToPrice,
  calculateImpermanentLoss,
  calculateImpermanentLossFromPrices,
} = require("../lib/utils");

// Test constants (use BigInt to avoid precision loss)
const Q96 = BigInt(2) ** BigInt(96);
const Q192 = Q96 * Q96; // 2^192

// Helper to create sqrtPriceX96 from price
function priceToSqrtPriceX96(price) {
  // price = (sqrtPriceX96 / 2^96)^2
  // sqrtPriceX96 = sqrt(price) * 2^96
  const sqrtPrice = Math.sqrt(price);
  return BigInt(Math.floor(sqrtPrice * Number(Q96)));
}

console.log("🧪 Testing IL Calculation Implementation\n");

// Test 1: No price change (should have 0% IL)
console.log("\n--- Test 1: No price change ---");
const entryPrice1 = 1e18;
const currentPrice1 = 1e18;
const entrySqrt1 = priceToSqrtPriceX96(entryPrice1);
const currentSqrt1 = priceToSqrtPriceX96(currentPrice1);

console.log("Entry price:", entryPrice1);
console.log("Current price:", currentPrice1);
console.log("Entry sqrtPriceX96:", entrySqrt1.toString());
console.log("Current sqrtPriceX96:", currentSqrt1.toString());

const il1 = calculateImpermanentLoss(entrySqrt1, currentSqrt1);
console.log("Calculated IL:", il1);
console.log("Expected IL: 0");
console.log("✅ Test 1 passed:", Math.abs(il1) < 0.001);

// Test 2: 10% price decrease (should have ~0.47% IL)
console.log("\n--- Test 2: 10% price decrease ---");
const entryPrice2 = 1e18;
const currentPrice2 = 0.9e18;
const entrySqrt2 = priceToSqrtPriceX96(entryPrice2);
const currentSqrt2 = priceToSqrtPriceX96(currentPrice2);

console.log("Entry price:", entryPrice2);
console.log("Current price:", currentPrice2);
console.log("Entry sqrtPriceX96:", entrySqrt2.toString());
console.log("Current sqrtPriceX96:", currentSqrt2.toString());

const il2 = calculateImpermanentLoss(entrySqrt2, currentSqrt2);
console.log("Calculated IL:", il2);
console.log("Expected IL: ~-0.0047");
console.log("✅ Test 2 passed:", Math.abs(il2 + 0.0047) < 0.001);

// Test 3: 50% price decrease (should have ~5.72% IL)
console.log("\n--- Test 3: 50% price decrease ---");
const entryPrice3 = 1e18;
const currentPrice3 = 0.5e18;
const entrySqrt3 = priceToSqrtPriceX96(entryPrice3);
const currentSqrt3 = priceToSqrtPriceX96(currentPrice3);

console.log("Entry price:", entryPrice3);
console.log("Current price:", currentPrice3);
console.log("Entry sqrtPriceX96:", entrySqrt3.toString());
console.log("Current sqrtPriceX96:", currentSqrt3.toString());

const il3 = calculateImpermanentLoss(entrySqrt3, currentSqrt3);
console.log("Calculated IL:", il3);
console.log("Expected IL: ~-0.0572");
console.log("✅ Test 3 passed:", Math.abs(il3 + 0.0572) < 0.001);

// Test 4: sqrtPriceX96 to price conversion
console.log("\n--- Test 4: sqrtPriceX96 to price conversion ---");
const testPrices = [0.5e18, 1e18, 2e18, 10e18];
testPrices.forEach((price) => {
  const sqrtPrice = priceToSqrtPriceX96(price);
  const convertedPrice = sqrtPriceX96ToPrice(BigInt(sqrtPrice));
  const error = Math.abs(convertedPrice - price) / price;

  console.log(
    `Price: ${price}, Converted: ${convertedPrice}, Error: ${(
      error * 100
    ).toFixed(2)}%`
  );
  console.log("✅ Conversion accurate:", error < 0.01);
});

console.log("\n🎉 All frontend IL calculation tests completed!");
