import { Context } from 'hono';
import { checkQuota, incrementUsage } from '../services/firestore';
import { generateNarrativeSummary, DailyContext, model } from '../services/vertexai';

export async function generateSummary(c: Context) {
  try {
    const deviceId = c.req.header('X-Device-ID');

    if (!deviceId) {
      return c.json({ error: 'Missing X-Device-ID header' }, 400);
    }

    // Check quota
    const quotaStatus = await checkQuota(deviceId);

    if (!quotaStatus.hasQuota) {
      return c.json({
        error: 'Daily quota exceeded',
        remaining_quota: 0,
        reset_time: quotaStatus.resetAt.toISOString(),
        tier: quotaStatus.tier,
      }, 429);
    }

    // Parse request body
    const body = await c.req.json();
    const context = body.context as DailyContext;

    if (!context) {
      return c.json({ error: 'Missing context in request body' }, 400);
    }

    // Generate narrative using Vertex AI
    const narrative = await generateNarrativeSummary(context);

    // Increment usage count
    await incrementUsage(deviceId);

    // Get updated quota
    const updatedQuota = await checkQuota(deviceId);

    return c.json({
      narrative,
      model,
      remaining_quota: updatedQuota.remaining,
      reset_time: updatedQuota.resetAt.toISOString(),
      tier: updatedQuota.tier,
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
