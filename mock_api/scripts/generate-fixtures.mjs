// Writes assets/demo/demo_data.json: the demo data shared by the mock API
// (mock_api/server.mjs) and the app's offline demo mode (--dart-define=DEMO=true).
// Deterministic: the same seed always produces the same file.
//
//   node mock_api/scripts/generate-fixtures.mjs
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const out = join(root, 'assets', 'demo', 'demo_data.json');
const asOf = Date.parse('2026-01-16T12:00:00Z');

// mulberry32: small seeded PRNG.
function prng(seed) {
  return () => {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const random = prng(Number(process.env.SEED ?? 28));
const gaussian = () => {
  const u = 1 - random();
  const v = random();
  return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
};
const round = (value, digits = 2) => Number(value.toFixed(digits));
const priceDigits = (price) => (price >= 1 ? 2 : 4);
const iso = (ms) => new Date(ms).toISOString();

const markets = [
  ['BTC/USD', 'Bitcoin', 43250.2, 2.5, 1.25e9, 44500, 42000, 8.5e11,
    'Bitcoin (BTC) is the first and largest cryptocurrency by market capitalization. Created in 2009 by Satoshi Nakamoto, it introduced the concept of decentralized digital currency using blockchain technology. Bitcoin is often referred to as "digital gold" and serves as a store of value and medium of exchange.'],
  ['ETH/USD', 'Ethereum', 2651.97, -1.2, 8.5e8, 2750, 2600, 3.2e11,
    'Ethereum (ETH) is the native currency of the Ethereum network, a programmable blockchain for smart contracts and decentralized applications. It moved from proof of work to proof of stake in 2022.'],
  ['SOL/USD', 'Solana', 98.2, 5.3, 4.5e8, 102, 92, 4.5e10,
    'Solana (SOL) powers a high-throughput blockchain that combines proof of stake with a proof-of-history clock to process thousands of transactions per second at low fees.'],
  ['DOT/USD', 'Polkadot', 7.85, -0.5, 9.5e7, 8.1, 7.6, 9.5e9,
    'Polkadot (DOT) connects specialised blockchains, called parachains, to a shared relay chain so they can exchange data and share security.'],
  ['ADA/USD', 'Cardano', 0.5199, 1.8, 1.2e8, 0.54, 0.5, 1.8e10,
    'Cardano (ADA) is a proof-of-stake blockchain developed with a research-first approach, with peer-reviewed protocol design and formal methods.'],
  ['XRP/USD', 'XRP', 0.6214, 0.85, 1.1e9, 0.635, 0.61, 3.4e10,
    'XRP is the native asset of the XRP Ledger, an open-source ledger built for fast, low-cost payments and currency exchange.'],
  ['LINK/USD', 'Chainlink', 14.82, 3.1, 3.1e8, 15.1, 14.2, 8.4e9,
    'Chainlink (LINK) runs a decentralized oracle network that brings off-chain data, such as prices, to smart contracts.'],
  ['AVAX/USD', 'Avalanche', 36.41, -2.35, 5.2e8, 37.9, 35.8, 1.35e10,
    'Avalanche (AVAX) is a smart-contract platform with fast finality and support for custom subnets.'],
  ['DOGE/USD', 'Dogecoin', 0.0823, -0.95, 4.8e8, 0.0841, 0.0812, 1.18e10,
    'Dogecoin (DOGE) started in 2013 as a joke based on the "Doge" meme and grew into one of the most widely held cryptocurrencies.'],
  ['MATIC/USD', 'Polygon', 0.8412, 1.25, 2.9e8, 0.855, 0.826, 7.8e9,
    'Polygon (MATIC) scales Ethereum with sidechains and rollups that settle back to the Ethereum mainnet.'],
];

const marketData = markets.map(
  ([symbol, name, price, pct, volume, high, low, cap, description]) => ({
    symbol,
    name,
    description,
    price,
    change24h: round(price - price / (1 + pct / 100), priceDigits(price)),
    changePercent24h: pct,
    volume,
    high24h: high,
    low24h: low,
    marketCap: cap,
    lastUpdated: iso(asOf),
  }),
);
// The app reads `description`; `name` is only there for people reading the file.
for (const m of marketData) delete m.name;

const bySymbol = Object.fromEntries(marketData.map((m) => [m.symbol, m]));
const sorted = [...marketData].sort((a, b) => b.changePercent24h - a.changePercent24h);
const mover = (m) => ({ symbol: m.symbol, change: m.changePercent24h, price: m.price });

const analyticsOverview = {
  totalMarketCap: 2.5e12,
  totalVolume24h: 8.5e10,
  activeMarkets: marketData.length,
  topGainer: mover(sorted[0]),
  topLoser: mover(sorted[sorted.length - 1]),
  marketDominance: { btc: 42.5, eth: 28.3, others: 29.2 },
  lastUpdated: iso(asOf),
};

// timeframe -> [points, step in ms, volatility per step in %]
const timeframes = {
  '1h': [12, 5 * 60e3, 0.25],
  '4h': [24, 10 * 60e3, 0.35],
  '24h': [24, 60 * 60e3, 0.9],
  '7d': [28, 6 * 60 * 60e3, 1.6],
  '30d': [30, 24 * 60 * 60e3, 2.4],
};

const stats = (series) => {
  const returns = series.slice(1).map((v, i) => (v / series[i] - 1) * 100);
  const mean = returns.reduce((a, b) => a + b, 0) / returns.length;
  const variance = returns.reduce((a, b) => a + (b - mean) ** 2, 0) / returns.length;
  return {
    change: round((series[series.length - 1] / series[0] - 1) * 100),
    volatility: round(Math.sqrt(variance)),
  };
};

const walk = (points, sigma, start) => {
  const series = [start];
  for (let i = 1; i < points; i++) {
    series.push(series[i - 1] * (1 + (gaussian() * sigma + sigma / 10) / 100));
  }
  return series;
};

const trends = {};
for (const [tf, [points, step, sigma]] of Object.entries(timeframes)) {
  const series = walk(points, sigma, 100);
  trends[tf] = {
    timeframe: tf,
    data: series.map((index, i) => ({
      timestamp: iso(asOf - (points - 1 - i) * step),
      marketCap: round(2.5e12 * (index / series[series.length - 1]), 0),
      volume: round(7e10 + random() * 2.5e10, 0),
      priceIndex: round(index),
    })),
    summary: stats(series),
  };
}

const positions = [
  ['BTC/USD', 0.5, 41500],
  ['ETH/USD', 5, 2700],
  ['SOL/USD', 100, 85],
  ['ADA/USD', 4000, 0.55],
  ['LINK/USD', 35, 12.4],
];
const totalValue = positions.reduce((sum, [s, q]) => sum + q * bySymbol[s].price, 0);
const holdings = positions.map(([symbol, quantity, averagePrice], i) => {
  const currentPrice = bySymbol[symbol].price;
  const value = quantity * currentPrice;
  const cost = quantity * averagePrice;
  return {
    id: String(i + 1),
    symbol,
    quantity,
    averagePrice,
    currentPrice,
    value: round(value),
    pnl: round(value - cost),
    pnlPercent: round((value / cost - 1) * 100),
    allocation: round((value / totalValue) * 100, 1),
    lastUpdated: iso(asOf),
  };
});
const totalPnl = holdings.reduce((sum, h) => sum + h.pnl, 0);
const portfolio = {
  totalValue: round(totalValue),
  totalPnl: round(totalPnl),
  totalPnlPercent: round((totalPnl / (totalValue - totalPnl)) * 100),
  totalHoldings: holdings.length,
  lastUpdated: iso(asOf),
};

const performance = {};
for (const [tf, [points, step, sigma]] of Object.entries(timeframes)) {
  // Walk backwards from today's value so the series ends at the balance.
  const series = walk(points, sigma * 0.8, 100);
  const scale = totalValue / series[series.length - 1];
  const values = series.map((v) => v * scale);
  const start = values[0];
  performance[tf] = {
    timeframe: tf,
    data: values.map((value, i) => ({
      timestamp: iso(asOf - (points - 1 - i) * step),
      value: round(value),
      pnl: round(value - start),
      pnlPercent: round((value / start - 1) * 100),
    })),
    summary: {
      startValue: round(start),
      endValue: round(values[values.length - 1]),
      totalReturn: round((values[values.length - 1] / start - 1) * 100),
    },
  };
}

const data = {
  _about: 'Demo data for MarketPulse. Generated by mock_api/scripts/generate-fixtures.mjs; not real market data.',
  asOf: iso(asOf),
  marketData,
  analyticsOverview,
  trends,
  portfolio,
  holdings,
  performance,
};
mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, `${JSON.stringify(data, null, 2)}\n`);
console.log(`Wrote ${out}`);
