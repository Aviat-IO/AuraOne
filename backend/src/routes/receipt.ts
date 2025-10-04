import { Context } from 'hono';
import { upgradeToPro } from '../services/firestore';

/**
 * Validate App Store or Google Play receipt
 *
 * TODO: Implement actual receipt validation with Apple/Google APIs
 * For now, this is a placeholder that accepts any receipt
 */
export async function validateReceipt(c: Context) {
  try {
    const body = await c.req.json();
    const { device_id, receipt_data, platform } = body;

    if (!device_id || !receipt_data || !platform) {
      return c.json({
        error: 'Missing required fields: device_id, receipt_data, platform',
      }, 400);
    }

    if (platform !== 'apple' && platform !== 'google') {
      return c.json({
        error: 'Invalid platform. Must be "apple" or "google"',
      }, 400);
    }

    // TODO: Implement actual receipt validation
    // For Apple: Use App Store Server API
    // For Google: Use Google Play Developer API

    // For now, accept any receipt and upgrade to Pro
    await upgradeToPro(device_id, receipt_data, platform);

    return c.json({
      success: true,
      tier: 'pro',
      quota: 25,
      message: 'Receipt validated successfully. Upgraded to Pro tier.',
    });
  } catch (error) {
    console.error('Error validating receipt:', error);

    if (error instanceof Error) {
      return c.json({
        error: 'Failed to validate receipt',
        message: process.env.NODE_ENV === 'development' ? error.message : undefined,
      }, 500);
    }

    return c.json({ error: 'Internal server error' }, 500);
  }
}
