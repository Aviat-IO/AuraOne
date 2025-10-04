import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { generateSummary } from './routes/generate';
import { getUsage } from './routes/usage';
import { validateReceipt } from './routes/receipt';

const app = new Hono();

// Middleware
app.use('*', logger());
app.use('*', cors({
  origin: ['http://localhost:*', 'https://*.auraone.app'],
  allowMethods: ['GET', 'POST', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'X-Device-ID'],
}));

// Health check endpoint
app.get('/health', (c) => {
  return c.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'aura-one-backend',
    version: '1.0.0',
  });
});

// API routes
app.post('/api/generate-summary', generateSummary);
app.get('/api/usage/:device_id', getUsage);
app.post('/api/validate-receipt', validateReceipt);

// 404 handler
app.notFound((c) => {
  return c.json({ error: 'Not Found' }, 404);
});

// Error handler
app.onError((err, c) => {
  console.error('Unhandled error:', err);
  return c.json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  }, 500);
});

const port = process.env.PORT || 5566;

console.log(`🚀 Aura One backend starting on port ${port}...`);

export default {
  port,
  fetch: app.fetch,
};
