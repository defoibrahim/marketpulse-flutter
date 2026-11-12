// MarketPulse mock API: the REST endpoints and the WebSocket price feed the
// app calls, serving the demo data in assets/demo/demo_data.json.
//
//   cd mock_api && npm install && npm start      # http://localhost:3000
//
// Environment: PORT (3000), TICK_MS (1000, interval between price ticks),
// LATENCY_MS (0, delay added to every REST response).
import { readFileSync } from 'node:fs';
import { createServer as createHttpServer } from 'node:http';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { WebSocketServer } from 'ws';

const here = dirname(fileURLToPath(import.meta.url));
const fixturesPath = join(here, '..', 'assets', 'demo', 'demo_data.json');
const TIMEFRAMES = ['1h', '4h', '24h', '7d', '30d'];

const roundPrice = (price) => Number(price.toFixed(price >= 1 ? 2 : 4));

/**
 * Starts the mock API. Resolves to { port, close() }.
 * @param {{ port?: number, tickMs?: number, latencyMs?: number, random?: () => number }} options
 */
export async function startServer({
  port = 3000,
  tickMs = 1000,
  latencyMs = 0,
  random = Math.random,
} = {}) {
  const fixtures = JSON.parse(readFileSync(fixturesPath, 'utf8'));

  // Live market state: ticks move prices, and REST reads see the moves.
  const markets = fixtures.marketData.map((m) => ({
    ...m,
    open: m.price - m.change24h,
  }));
  const bySymbol = new Map(markets.map((m) => [m.symbol, m]));
  const publicMarket = ({ open, ...market }) => market;

  const send = (res, status, body) => {
    const payload = JSON.stringify(body);
    const write = () => {
      res.writeHead(status, {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-store',
      });
      res.end(payload);
    };
    latencyMs > 0 ? setTimeout(write, latencyMs) : write();
  };
  const ok = (res, data) => send(res, 200, { data });
  const notFound = (res, message) => send(res, 404, { error: message });

  const timeframeOf = (url) => {
    const timeframe = url.searchParams.get('timeframe') ?? '24h';
    return TIMEFRAMES.includes(timeframe) ? timeframe : null;
  };

  const server = createHttpServer((req, res) => {
    const url = new URL(req.url, 'http://localhost');
    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': '*',
      });
      return res.end();
    }
    if (req.method !== 'GET') return send(res, 405, { error: 'Method not allowed' });

    const path = url.pathname.replace(/\/+$/, '');
    const badTimeframe = () =>
      send(res, 400, { error: `timeframe must be one of ${TIMEFRAMES.join(', ')}` });

    if (path === '/health') return ok(res, { status: 'ok' });
    if (path === '/api/market-data') return ok(res, markets.map(publicMarket));

    // The app URL-encodes the symbol into one segment: BTC%2FUSD.
    const symbolMatch = path.match(/^\/api\/market-data\/([^/]+)$/);
    if (symbolMatch) {
      const market = bySymbol.get(decodeURIComponent(symbolMatch[1]).toUpperCase());
      return market ? ok(res, publicMarket(market)) : notFound(res, 'Unknown symbol');
    }

    if (path === '/api/analytics/overview') {
      return ok(res, { ...fixtures.analyticsOverview, lastUpdated: new Date().toISOString() });
    }
    if (path === '/api/analytics/trends') {
      const timeframe = timeframeOf(url);
      return timeframe ? ok(res, fixtures.trends[timeframe]) : badTimeframe();
    }
    if (path === '/api/portfolio') return ok(res, fixtures.portfolio);
    if (path === '/api/portfolio/holdings') return ok(res, fixtures.holdings);
    if (path === '/api/portfolio/performance') {
      const timeframe = timeframeOf(url);
      return timeframe ? ok(res, fixtures.performance[timeframe]) : badTimeframe();
    }
    return notFound(res, 'Not found');
  });

  // Live prices: every tick moves one random market and broadcasts it.
  const sockets = new WebSocketServer({ server });
  const tick = () => {
    const market = markets[Math.floor(random() * markets.length)];
    const move = (random() - 0.5) * 0.004; // up to +/-0.2%
    market.price = roundPrice(market.price * (1 + move));
    market.change24h = roundPrice(market.price - market.open);
    market.changePercent24h = Number(((market.price / market.open - 1) * 100).toFixed(2));
    market.volume = Math.round(market.volume * (1 + random() * 0.0005));
    market.high24h = Math.max(market.high24h, market.price);
    market.low24h = Math.min(market.low24h, market.price);
    market.lastUpdated = new Date().toISOString();
    const message = JSON.stringify({
      type: 'market_update',
      data: {
        symbol: market.symbol,
        price: market.price,
        change24h: market.change24h,
        changePercent24h: market.changePercent24h,
        volume: market.volume,
        timestamp: market.lastUpdated,
      },
    });
    for (const client of sockets.clients) {
      if (client.readyState === client.OPEN) client.send(message);
    }
  };
  const timer = setInterval(tick, tickMs);

  await new Promise((resolve) => server.listen(port, resolve));
  return {
    port: server.address().port,
    close: () =>
      new Promise((resolve) => {
        clearInterval(timer);
        for (const client of sockets.clients) client.terminate();
        sockets.close(() => server.close(() => resolve()));
      }),
  };
}

// `node server.mjs` starts it; importing it (the tests) does not.
if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const { port } = await startServer({
    port: Number(process.env.PORT ?? 3000),
    tickMs: Number(process.env.TICK_MS ?? 1000),
    latencyMs: Number(process.env.LATENCY_MS ?? 0),
  });
  console.log(`MarketPulse mock API on http://localhost:${port}/api (WebSocket ws://localhost:${port})`);
}
