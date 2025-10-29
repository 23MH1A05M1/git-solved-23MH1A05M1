#!/usr/bin/env node
/**
 * DevOps Simulator - System Monitor
 * Resolution: production is primary; development features available via environment/profile
 *
 * Usage:
 *   MONITOR_ENV=development node monitor.js
 *   NODE_ENV=development node monitor.js
 *   node monitor.js   # defaults to production
 */

'use strict';

// --- Determine environment/profile ---
const ENV = (process.env.MONITOR_ENV || process.env.NODE_ENV || 'production').toLowerCase();
const IS_DEV = ENV === 'development';

// --- Base (production) config ---
const prodConfig = {
  version: '1.0.0',
  interval: 60000, // 1 minute
  alertThreshold: 80,
  metricsEndpoint: 'http://localhost:8080/metrics',
  debugMode: false,
  verboseLogging: false,
  memoryLogInterval: null // disabled in prod by default
};

// --- Development overrides ---
const devConfig = {
  version: '2.0.0-beta',
  interval: 5000, // 5 seconds (faster for development)
  alertThreshold: 90,
  metricsEndpoint: 'http://localhost:3000/metrics',
  debugMode: true,
  verboseLogging: true,
  memoryLogInterval: 30000 // log memory every 30s in dev
};

// --- Final merged config based on environment ---
const monitorConfig = Object.assign({}, prodConfig, IS_DEV ? devConfig : {});

// --- Header / startup logs ---
console.log('=================================');
console.log(`DevOps Simulator - Monitor ${monitorConfig.version}`);
console.log(`Mode: ${ENV.toUpperCase()}`);
console.log('=================================');

if (monitorConfig.debugMode) {
  console.log('Development Mode: ENABLED');
  console.log(`Metrics endpoint: ${monitorConfig.metricsEndpoint}`);
}
console.log(`Monitoring every ${monitorConfig.interval}ms`);
if (monitorConfig.verboseLogging) {
  console.log(`Alert threshold: ${monitorConfig.alertThreshold}%`);
}

// --- Health check function ---
function checkSystemHealth() {
  const timestamp = new Date().toISOString();

  if (monitorConfig.debugMode) {
    console.log(`\n[${timestamp}] === DETAILED HEALTH CHECK ===`);
  } else {
    console.log(`\n[${timestamp}] Checking system health...`);
  }

  // Simulated metrics (replace with real collectors in production)
  const cpuUsage = Math.random() * 100;
  const memUsage = Math.random() * 100;
  const diskUsage = Math.random() * 100;

  // Print CPU/Memory/Disk info (format depending on verbosity)
  if (monitorConfig.debugMode || monitorConfig.verboseLogging) {
    console.log(`✓ CPU usage: ${cpuUsage.toFixed(2)}%`);
    console.log(`✓ Memory usage: ${memUsage.toFixed(2)}%`);
    console.log(`✓ Disk usage: ${diskUsage.toFixed(2)}% used`);
  } else {
    // concise output for production
    console.log(`CPU: ${cpuUsage.toFixed(0)}% | MEM: ${memUsage.toFixed(0)}% | DISK: ${diskUsage.toFixed(0)}%`);
  }

  // Development-only info
  if (monitorConfig.debugMode) {
    console.log('✓ Hot reload: (dev stack dependent)');
    console.log('✓ Debug port: 9229 (if enabled in your runtime)');
    console.log('✓ Source maps: Enabled (if generated)');
  }

  // Determine overall status
  const maxUsage = Math.max(cpuUsage, memUsage, diskUsage);
  if (maxUsage > monitorConfig.alertThreshold) {
    console.log('⚠️  System Status: WARNING - High resource usage');
    // In a real implementation, trigger alerts/notifications here
  } else {
    console.log('✅ System Status: HEALTHY');
  }

  if (monitorConfig.verboseLogging) {
    console.log(`Next check in ${monitorConfig.interval}ms`);
  }
}

// --- Start monitoring ---
const mainInterval = setInterval(checkSystemHealth, monitorConfig.interval);

// Run first check immediately
checkSystemHealth();

// --- Optional development memory logging ---
let memoryInterval = null;
if (monitorConfig.memoryLogInterval && monitorConfig.debugMode) {
  memoryInterval = setInterval(() => {
    const mem = process.memoryUsage();
    console.log('\n--- Memory Usage (detailed) ---');
    console.log(`RSS: ${(mem.rss / 1024 / 1024).toFixed(2)} MB`);
    console.log(`Heap Total: ${(mem.heapTotal / 1024 / 1024).toFixed(2)} MB`);
    console.log(`Heap Used: ${(mem.heapUsed / 1024 / 1024).toFixed(2)} MB`);
    console.log(`External: ${(mem.external / 1024 / 1024).toFixed(2)} MB`);
  }, monitorConfig.memoryLogInterval);
}

// --- Graceful shutdown handler ---
function shutdown(signal) {
  console.log(`\nReceived ${signal}. Shutting down monitor...`);
  clearInterval(mainInterval);
  if (memoryInterval) clearInterval(memoryInterval);
  // allow other cleanup tasks here
  process.exit(0);
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

// Export for testing or embedding (optional)
module.exports = {
  monitorConfig,
  checkSystemHealth
};
