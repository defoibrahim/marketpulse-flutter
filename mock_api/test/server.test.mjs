// Contract tests: the mock API answers exactly the requests the app makes.
//   cd mock_api && npm test
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { startServer } from '../server.mjs';

let server;
let base;

before(async () => {
  server = await startServer({ port: 0, tickMs: 20 });
  base = `http://localhost:${server.port}`;
});
after(() => server.close());

const get = async (path) => {
  const res = await fetch(`${base}${path}`);
  return { status: res.status, body: await res.json(), headers: res.headers };
};

const isNumber = (v) => typeof v === 'number' && Number.isFinite(v);
const isIsoDate = (v) => typeof v === 'string' && !Number.isNaN(Date.parse(v));

test('GET /api/market-data lists markets in the shape MarketData.fromJson reads', async () => {
  const { status, body, headers } = await get('/api/market-data');
  assert.equal(status, 200);
  assert.equal(headers.get('access-control-allow-origin'), '*');
  assert.ok(body.data.length >= 5);
  for (const m of body.data) {
    assert.match(m.symbol, /^[A-Z]+\/USD$/);
    assert.equal(typeof m.description, 'string');
    for (const key of ['price', 'change24h', 'changePercent24h', 'volume', 'high24h', 'low24h', 'marketCap']) {
      assert.ok(isNumber(m[key]), `${m.symbol}.${key}`);
    }
    assert.ok(isIsoDate(m.lastUpdated));
    assert.equal(m.open, undefined, 'internal state must not leak');
  }
});

test('GET /api/market-data/:symbol takes the URL-encoded symbol', async () => {
  const { status, body } = await get('/api/market-data/BTC%2FUSD');
  assert.equal(status, 200);
  assert.equal(body.data.symbol, 'BTC/USD');

  const missing = await get('/api/market-data/NOPE%2FUSD');
  assert.equal(missing.status, 404);
});

test('GET /api/analytics/overview has movers and dominance', async () => {
  const { body } = await get('/api/analytics/overview');
  const o = body.data;
  assert.ok(isNumber(o.totalMarketCap) && isNumber(o.totalVolume24h));
  assert.ok(Number.isInteger(o.activeMarkets));
  for (const mover of [o.topGainer, o.topLoser]) {
    assert.equal(typeof mover.symbol, 'string');
    assert.ok(isNumber(mover.change) && isNumber(mover.price));
  }
  assert.ok(o.topGainer.change > o.topLoser.change);
  const { btc, eth, others } = o.marketDominance;
  assert.ok(Math.abs(btc + eth + others - 100) < 0.01);
  assert.ok(isIsoDate(o.lastUpdated));
});

test('GET /api/analytics/trends serves every timeframe and rejects others', async () => {
  for (const timeframe of ['1h', '4h', '24h', '7d', '30d']) {
    const { status, body } = await get(`/api/analytics/trends?timeframe=${timeframe}`);
    assert.equal(status, 200);
    assert.equal(body.data.timeframe, timeframe);
    assert.ok(body.data.data.length > 5);
    for (const point of body.data.data) {
      assert.ok(isIsoDate(point.timestamp));
      assert.ok(isNumber(point.marketCap) && isNumber(point.volume) && isNumber(point.priceIndex));
    }
    assert.ok(isNumber(body.data.summary.change) && isNumber(body.data.summary.volatility));
  }
  assert.equal((await get('/api/analytics/trends?timeframe=1y')).status, 400);
});

test('portfolio endpoints are consistent with each other', async () => {
  const overview = (await get('/api/portfolio')).body.data;
  const holdings = (await get('/api/portfolio/holdings')).body.data;
  assert.equal(overview.totalHoldings, holdings.length);
  const total = holdings.reduce((sum, h) => sum + h.value, 0);
  assert.ok(Math.abs(total - overview.totalValue) < 0.05);
  const allocation = holdings.reduce((sum, h) => sum + h.allocation, 0);
  assert.ok(Math.abs(allocation - 100) < 0.5);
  for (const h of holdings) {
    assert.equal(typeof h.id, 'string');
    for (const key of ['quantity', 'averagePrice', 'currentPrice', 'value', 'pnl', 'pnlPercent', 'allocation']) {
      assert.ok(isNumber(h[key]), `${h.symbol}.${key}`);
    }
  }

  const performance = (await get('/api/portfolio/performance?timeframe=7d')).body.data;
  assert.equal(performance.timeframe, '7d');
  assert.ok(Math.abs(performance.summary.endValue - overview.totalValue) < 0.05);
});

test('unknown routes are 404 JSON', async () => {
  const { status, body } = await get('/api/nope');
  assert.equal(status, 404);
  assert.equal(body.error, 'Not found');
});

test('the WebSocket streams market_update ticks that REST reads reflect', async () => {
  const ws = new WebSocket(`ws://localhost:${server.port}`);
  const message = await new Promise((resolve, reject) => {
    ws.onmessage = (event) => resolve(JSON.parse(event.data));
    ws.onerror = reject;
  });
  ws.close();

  assert.equal(message.type, 'market_update');
  const { symbol, price, change24h, changePercent24h, volume, timestamp } = message.data;
  assert.match(symbol, /\/USD$/);
  assert.ok([price, change24h, changePercent24h, volume].every(isNumber));
  assert.ok(isIsoDate(timestamp));

  const { body } = await get(`/api/market-data/${encodeURIComponent(symbol)}`);
  assert.ok(isNumber(body.data.price));
});
