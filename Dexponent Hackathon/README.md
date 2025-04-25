# Yield Verifier Algorithm

A smart contract implementation for performance scoring and yield benchmarking of DeFi yield farming strategies. This system calculates performance metrics and benchmark yields based on historical data to ensure fair reward distribution.

## Features

- Performance scoring based on multiple metrics:
  - Total yield generated
  - Volatility assessment
  - Strategy uptime
- Dynamic benchmark yield calculation using exponential moving averages
- Historical data tracking for strategies
- Role-based access control for verifiers
- Comprehensive test coverage

## Technical Architecture

- Smart Contracts: Solidity 0.8.19
- Development Framework: Hardhat
- Testing: Chai & Ethers.js
- External Dependencies:
  - OpenZeppelin Contracts
  - Chainlink Price Feeds
  - GraphQL for data indexing

## Setup

1. Install dependencies:
```bash
npm install
```

2. Compile contracts:
```bash
npm run compile
```

3. Run tests:
```bash
npm test
```

4. Deploy to testnet:
```bash
npm run deploy
```

## Contract Usage

### Updating Strategy Data
```solidity
function updateStrategyData(
    address strategy,
    uint256 yield,
    uint256 depositAmount,
    uint256 withdrawalAmount
) external onlyRole(VERIFIER_ROLE)
```

### Retrieving Metrics
```solidity
function getStrategyMetrics(address strategy) external view returns (StrategyMetrics memory)
function getHistoricalData(address strategy, uint256 timestamp) external view returns (HistoricalData memory)
function getStrategyTimestamps(address strategy) external view returns (uint256[] memory)
```

## Performance Scoring

The performance score is calculated using a weighted combination of:
- Total yield (40%)
- Volatility score (30%)
- Uptime score (30%)

Benchmark yields are computed using exponential moving averages with a decay factor to prioritize recent performance while maintaining historical context.

## Security Considerations

- Role-based access control for verifiers
- Reentrancy protection
- Arithmetic overflow protection (Solidity 0.8.x)
- No direct handling of user funds

## License

MIT