import { FieldValue, Firestore } from "@google-cloud/firestore";

// Initialize Firestore with Application Default Credentials
const firestore = new Firestore({
  projectId: process.env.GCP_PROJECT_ID,
});

export interface UsageRecord {
  device_id: string;
  tier: "free" | "pro";
  usage_count: number;
  last_reset: Date;
  created_at: Date;
  updated_at: Date;
}

export interface AccountRecord {
  account_id: string;
  tier: "pro";
  device_ids: string[];
  receipt_data: string;
  platform: "apple" | "google";
  created_at: Date;
  updated_at: Date;
}

const QUOTA_LIMITS = {
  free: 3,
  pro: 25,
};

/**
 * Get usage record for a device
 */
export async function getUsageRecord(
  deviceId: string
): Promise<UsageRecord | null> {
  const docRef = firestore.collection("usage").doc(deviceId);
  const doc = await docRef.get();

  if (!doc.exists) {
    return null;
  }

  return doc.data() as UsageRecord;
}

/**
 * Create or reset usage record for a device
 */
export async function createUsageRecord(
  deviceId: string,
  tier: "free" | "pro" = "free"
): Promise<UsageRecord> {
  const now = new Date();
  const record: UsageRecord = {
    device_id: deviceId,
    tier,
    usage_count: 0,
    last_reset: now,
    created_at: now,
    updated_at: now,
  };

  await firestore.collection("usage").doc(deviceId).set(record);
  return record;
}

/**
 * Check if device has remaining quota
 */
export async function checkQuota(deviceId: string): Promise<{
  hasQuota: boolean;
  remaining: number;
  resetAt: Date;
  tier: "free" | "pro";
}> {
  let record = await getUsageRecord(deviceId);

  // Create new record if doesn't exist
  if (!record) {
    record = await createUsageRecord(deviceId);
  }

  // Check if we need to reset (daily reset at midnight UTC)
  const now = new Date();
  const lastReset = new Date(record.last_reset);
  const todayMidnight = new Date(now.toISOString().split("T")[0]);

  if (lastReset < todayMidnight) {
    // Reset usage for new day
    record.usage_count = 0;
    record.last_reset = todayMidnight;
    record.updated_at = now;
    await firestore.collection("usage").doc(deviceId).update({
      usage_count: 0,
      last_reset: todayMidnight,
      updated_at: now,
    });
  }

  const limit = QUOTA_LIMITS[record.tier];
  const remaining = Math.max(0, limit - record.usage_count);
  const hasQuota = remaining > 0;

  // Calculate next reset time (tomorrow midnight UTC)
  const resetAt = new Date(todayMidnight);
  resetAt.setDate(resetAt.getDate() + 1);

  return {
    hasQuota,
    remaining,
    resetAt,
    tier: record.tier,
  };
}

/**
 * Increment usage count for a device
 */
export async function incrementUsage(deviceId: string): Promise<number> {
  const docRef = firestore.collection("usage").doc(deviceId);

  await docRef.update({
    usage_count: FieldValue.increment(1),
    updated_at: new Date(),
  });

  const updated = await docRef.get();
  const data = updated.data() as UsageRecord;

  return data.usage_count;
}

/**
 * Upgrade device to pro tier
 */
export async function upgradeToPro(
  deviceId: string,
  receiptData: string,
  platform: "apple" | "google"
): Promise<void> {
  const now = new Date();

  // Update usage record
  await firestore.collection("usage").doc(deviceId).update({
    tier: "pro",
    updated_at: now,
  });

  // Create account record (for multi-device support in future)
  const accountId = `account_${deviceId}`;
  const accountRecord: AccountRecord = {
    account_id: accountId,
    tier: "pro",
    device_ids: [deviceId],
    receipt_data: receiptData,
    platform,
    created_at: now,
    updated_at: now,
  };

  await firestore.collection("accounts").doc(accountId).set(accountRecord);
}

export default firestore;
