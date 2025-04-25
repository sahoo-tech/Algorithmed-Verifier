// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract YieldVerifier is AccessControl, ReentrancyGuard {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    
    struct StrategyMetrics {
        uint256 totalYield;
        uint256 depositAmount;
        uint256 lastUpdateTimestamp;
        uint256 performanceScore;
        uint256 benchmarkYield;
        uint256 volatility;
        uint256 uptime;
    }

    struct HistoricalData {
        uint256 timestamp;
        uint256 yield;
        uint256 depositAmount;
        uint256 withdrawalAmount;
    }

    // Mapping of strategy address to its metrics
    mapping(address => StrategyMetrics) public strategyMetrics;
    
    // Historical data storage (strategy => timestamp => data)
    mapping(address => mapping(uint256 => HistoricalData)) public historicalData;
    mapping(address => uint256[]) public strategyTimestamps;

    // Constants
    uint256 public constant MINIMUM_HISTORY_PERIOD = 180 days;
    uint256 public constant PERFORMANCE_SCALE = 100;
    uint256 public constant DECAY_FACTOR = 95; // 95% weight for newer data

    event MetricsUpdated(
        address indexed strategy,
        uint256 performanceScore,
        uint256 benchmarkYield
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VERIFIER_ROLE, msg.sender);
    }

    function updateStrategyData(
        address strategy,
        uint256 yield,
        uint256 depositAmount,
        uint256 withdrawalAmount
    ) external onlyRole(VERIFIER_ROLE) nonReentrant {
        require(strategy != address(0), "Invalid strategy address");

        uint256 timestamp = block.timestamp;
        
        // Store historical data
        historicalData[strategy][timestamp] = HistoricalData({
            timestamp: timestamp,
            yield: yield,
            depositAmount: depositAmount,
            withdrawalAmount: withdrawalAmount
        });
        strategyTimestamps[strategy].push(timestamp);

        // Update metrics
        StrategyMetrics storage metrics = strategyMetrics[strategy];
        metrics.totalYield += yield;
        metrics.depositAmount = depositAmount;
        metrics.lastUpdateTimestamp = timestamp;

        // Calculate performance metrics
        calculatePerformanceMetrics(strategy);

        emit MetricsUpdated(
            strategy,
            metrics.performanceScore,
            metrics.benchmarkYield
        );
    }

    function calculatePerformanceMetrics(address strategy) internal {
        StrategyMetrics storage metrics = strategyMetrics[strategy];
        uint256[] storage timestamps = strategyTimestamps[strategy];

        require(timestamps.length > 0, "No historical data");

        // Calculate benchmark yield using exponential moving average
        uint256 totalWeight = 0;
        uint256 weightedYield = 0;
        uint256 volatilitySum = 0;
        uint256 previousYield = 0;

        for (uint256 i = 0; i < timestamps.length; i++) {
            HistoricalData storage data = historicalData[strategy][timestamps[i]];
            
            // Apply decay factor for weighted average
            uint256 weight = DECAY_FACTOR ** (timestamps.length - i - 1);
            weightedYield += data.yield * weight;
            totalWeight += weight;

            // Calculate volatility
            if (i > 0) {
                if (data.yield > previousYield) {
                    volatilitySum += data.yield - previousYield;
                } else {
                    volatilitySum += previousYield - data.yield;
                }
            }
            previousYield = data.yield;
        }

        // Update benchmark yield
        if (totalWeight > 0) {
            metrics.benchmarkYield = weightedYield / totalWeight;
        }

        // Calculate volatility score (inverse - lower volatility is better)
        uint256 volatilityScore = timestamps.length > 1 ?
            PERFORMANCE_SCALE - (volatilitySum * PERFORMANCE_SCALE / (metrics.totalYield * (timestamps.length - 1))) :
            PERFORMANCE_SCALE;

        // Calculate uptime score
        uint256 expectedUpdates = (block.timestamp - timestamps[0]) / 1 days;
        metrics.uptime = timestamps.length * PERFORMANCE_SCALE / expectedUpdates;

        // Calculate final performance score
        metrics.performanceScore = (
            (metrics.totalYield * 40) +
            (volatilityScore * 30) +
            (metrics.uptime * 30)
        ) / PERFORMANCE_SCALE;

        metrics.volatility = volatilityScore;
    }

    function getStrategyMetrics(address strategy)
        external
        view
        returns (StrategyMetrics memory)
    {
        return strategyMetrics[strategy];
    }

    function getHistoricalData(address strategy, uint256 timestamp)
        external
        view
        returns (HistoricalData memory)
    {
        return historicalData[strategy][timestamp];
    }

    function getStrategyTimestamps(address strategy)
        external
        view
        returns (uint256[] memory)
    {
        return strategyTimestamps[strategy];
    }
}