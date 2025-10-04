import { Context } from 'hono';
import { checkQuota } from '../services/firestore';

export async function getUsage(c: Context) {
  try {
    const deviceId = c.req.param('device_id');

    if (!deviceId) {
      return c.json({ error: 'Missing device_id parameter' }, 400);
    }

    const quotaStatus = await checkQuota(deviceId);

    return c.json({
      device_id: deviceId,
      tier: quotaStatus.tier,
      remaining: quotaStatus.remaining,
      has_quota: quotaStatus.hasQuota,
      reset_at: quotaStatus.resetAt.toISOString(),
    });
  } catch (error) {
    console.error('Error getting usage:', error);

    if (error instanceof Error) {
      return c.json({
        error: 'Failed to get usage',
        message: process.env.NODE_ENV === 'development' ? error.message : undefined,
      }, 500);
    }

    return c.json({ error: 'Internal server error' }, 500);
  }
}
