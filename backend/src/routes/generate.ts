import { Context } from 'hono';
import { checkQuota, incrementUsage } from '../services/firestore';
import { generateNarrativeSummary, DailyContext, model } from '../services/vertexai';

export async function generateSummary(c: Context) {
  try {
    const deviceId = c.req.header('X-Device-ID');

    if (!deviceId) {
      return c.json({ error: 'Missing X-Device-ID header' }, 400);
    }

    // Check quota (skip in development mode)
    const isDevelopment = process.env.NODE_ENV === 'development';

    if (!isDevelopment) {
      const quotaStatus = await checkQuota(deviceId);

      if (!quotaStatus.hasQuota) {
        return c.json({
          error: 'Daily quota exceeded',
          remaining_quota: 0,
          reset_time: quotaStatus.resetAt.toISOString(),
          tier: quotaStatus.tier,
        }, 429);
      }
    }

    // Parse request body
    const body = await c.req.json();
    const context = body.context as DailyContext;

    if (!context) {
      return c.json({ error: 'Missing context in request body' }, 400);
    }

    // Generate narrative using Vertex AI
    const narrative = await generateNarrativeSummary(context);

    // Increment usage count and get quota (skip in development mode)
    if (!isDevelopment) {
      await incrementUsage(deviceId);
      const updatedQuota = await checkQuota(deviceId);

      return c.json({
        narrative,
        model,
        remaining_quota: updatedQuota.remaining,
        reset_time: updatedQuota.resetAt.toISOString(),
        tier: updatedQuota.tier,
      });
    }

    // Development mode: return unlimited quota
    return c.json({
      narrative,
      model,
      remaining_quota: 999999,
      reset_time: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      tier: 'development',
    });
  } catch (error) {
    console.error('Error generating summary:', error);

    if (error instanceof Error) {
      return c.json({
        error: 'Failed to generate summary',
        message: process.env.NODE_ENV === 'development' ? error.message : undefined,
      }, 500);
    }

    return c.json({ error: 'Internal server error' }, 500);
  }
}
