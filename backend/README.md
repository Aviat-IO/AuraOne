# Aura One Backend Proxy Service

Secure backend proxy providing rate-limited access to Vertex AI Gemini 2.0 Flash for the Aura One mobile app.

## Architecture

- **Runtime**: Bun (TypeScript)
- **Framework**: Hono (lightweight web framework)
- **AI Model**: Vertex AI Gemini 2.0 Flash
- **Database**: Cloud Firestore (usage tracking & rate limiting)
- **Authentication**: Device ID-based (privacy-first)
- **Deployment**: Google Cloud Run

## Features

- ✅ Privacy-first anonymous authentication (device UUID only)
- ✅ Rate limiting: 3/day (free), 25/day (Pro)
- ✅ No API credentials in mobile app binary
- ✅ Secure Vertex AI proxy with Application Default Credentials
- ✅ Receipt validation for Pro tier activation
- ✅ Multi-device support via account linking (future)

## Prerequisites

- [Bun](https://bun.sh/) >= 1.0.0
- GCP Project with Vertex AI and Firestore enabled
- GCP credentials (service account key or Application Default Credentials)

## Local Development Setup

### 1. Install Bun

```bash
curl -fsSL https://bun.sh/install | bash
```

### 2. Install Dependencies

```bash
cd backend
bun install
```

### 3. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your GCP project details:

```env
GCP_PROJECT_ID=your-gcp-project-id
GCP_LOCATION=us-central1
NODE_ENV=development
PORT=5566
```

### 4. Set Up GCP Credentials

**Option A: Service Account Key (Development)**

1. Create service account in GCP Console
2. Grant roles: `Vertex AI User`, `Cloud Datastore User`
3. Download JSON key file
4. Save to `backend/credentials/gcp-key.json`
5. Set environment variable:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=./credentials/gcp-key.json
```

**Option B: Application Default Credentials (Recommended)**

```bash
gcloud auth application-default login
```

### 5. Run Development Server

```bash
bun run dev
```

Server starts on http://localhost:5566

## Docker Development

### Using docker-compose

```bash
# From project root
docker-compose up
```

This starts the backend on port 5566 with hot-reload enabled.

### Manual Docker Build

```bash
cd backend
docker build -t aura-one-backend .
docker run -p 5566:5566 \
  -e GCP_PROJECT_ID=your-project \
  -e GOOGLE_APPLICATION_CREDENTIALS=/app/credentials/gcp-key.json \
  -v $(pwd)/credentials:/app/credentials:ro \
  aura-one-backend
```

## API Endpoints

### Health Check

```http
GET /health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:30:00.000Z",
  "service": "aura-one-backend",
  "version": "1.0.0"
}
```

### Generate Summary

```http
POST /api/generate-summary
Content-Type: application/json
X-Device-ID: {device-uuid}

{
  "device_id": "device-uuid",
  "context": {
    "date": "2025-01-15",
    "timeline_events": [...],
    "location_summary": {...},
    "activity_summary": {...},
    "social_summary": {...},
    "photo_contexts": [...]
  }
}
```

Response:
```json
{
  "narrative": "Today was...",
  "model": "gemini-2.0-flash-exp",
  "remaining_quota": 2,
  "reset_time": "2025-01-16T00:00:00.000Z",
  "tier": "free"
}
```

Rate limit error (429):
```json
{
  "error": "Daily quota exceeded",
  "remaining_quota": 0,
  "reset_time": "2025-01-16T00:00:00.000Z",
  "tier": "free"
}
```

### Get Usage Status

```http
GET /api/usage/{device_id}
```

Response:
```json
{
  "device_id": "device-uuid",
  "tier": "free",
  "remaining": 3,
  "has_quota": true,
  "reset_at": "2025-01-16T00:00:00.000Z"
}
```

### Validate Receipt (Pro Upgrade)

```http
POST /api/validate-receipt
Content-Type: application/json

{
  "device_id": "device-uuid",
  "receipt_data": "base64-encoded-receipt",
  "platform": "apple"  // or "google"
}
```

Response:
```json
{
  "success": true,
  "tier": "pro",
  "quota": 25,
  "message": "Receipt validated successfully. Upgraded to Pro tier."
}
```

## Firestore Schema

### Usage Collection (`/usage/{device_id}`)

```typescript
{
  device_id: string;
  tier: 'free' | 'pro';
  usage_count: number;
  last_reset: Date;      // Midnight UTC
  created_at: Date;
  updated_at: Date;
}
```

### Accounts Collection (`/accounts/{account_id}`)

```typescript
{
  account_id: string;
  tier: 'pro';
  device_ids: string[];
  receipt_data: string;
  platform: 'apple' | 'google';
  created_at: Date;
  updated_at: Date;
}
```

## Deployment

### Cloud Run Deployment

1. Build container:
```bash
gcloud builds submit --tag gcr.io/{PROJECT_ID}/aura-one-backend
```

2. Deploy to Cloud Run:
```bash
gcloud run deploy aura-one-backend \
  --image gcr.io/{PROJECT_ID}/aura-one-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars GCP_PROJECT_ID={PROJECT_ID},GCP_LOCATION=us-central1
```

3. Update mobile app with Cloud Run URL in `ManagedCloudGeminiAdapter`

## Security

- ✅ No API credentials in mobile app
- ✅ Device-based rate limiting prevents abuse
- ✅ Firestore security rules enforce access control
- ✅ CORS configured for mobile app origins only
- ✅ Application Default Credentials (no service account keys in production)

## Monitoring

- Health endpoint: `/health`
- Cloud Run logs: `gcloud run logs read`
- Firestore metrics: GCP Console

## Testing

```bash
# Run tests
bun test

# Test health endpoint
curl http://localhost:5566/health

# Test quota check
curl http://localhost:5566/api/usage/test-device-123

# Test generation (requires valid context)
curl -X POST http://localhost:5566/api/generate-summary \
  -H "Content-Type: application/json" \
  -H "X-Device-ID: test-device-123" \
  -d @test-context.json
```

## Future Enhancements

- [ ] Implement Apple App Store receipt validation
- [ ] Implement Google Play receipt validation
- [ ] Multi-device account linking
- [ ] Usage analytics dashboard
- [ ] A/B testing for AI prompt variations
- [ ] Caching layer for repeated contexts

## License

Proprietary - Aura One
