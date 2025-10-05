import { VertexAI } from '@google-cloud/vertexai';

// Initialize Vertex AI with Application Default Credentials
const projectId = process.env.GCP_PROJECT_ID || 'aura-one';
const location = process.env.GCP_LOCATION || 'us-central1';

const vertexAI = new VertexAI({
  project: projectId,
  location: location,
});

const model = 'gemini-2.5-pro';

export interface DailyContext {
  date: string;
  timeline_events: Array<{
    timestamp: string;
    place_name?: string;
    description?: string;
    objects_seen?: string[];
  }>;
  location_summary: {
    significant_places: string[];
    total_distance_meters: number;
  };
  activity_summary: {
    primary_activities: string[];
  };
  social_summary: {
    total_people_detected: number;
    social_contexts: string[];
  };
  photo_contexts: Array<{
    timestamp: string;
    detected_objects: string[];
  }>;
}

/**
 * Generate a narrative summary from daily context using Vertex AI
 */
export async function generateNarrativeSummary(context: DailyContext): Promise<string> {
  const prompt = buildNarrativePrompt(context);

  const generativeModel = vertexAI.getGenerativeModel({
    model: model,
    generationConfig: {
      temperature: 0.3, // Lower temperature for factual, grounded narratives
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 8192,
    },
  });

  const result = await generativeModel.generateContent({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
  });

  const response = result.response;
  const narrative = response.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!narrative) {
    throw new Error('Empty response from Vertex AI');
  }

  return narrative;
}

/**
 * Build narrative prompt from daily context
 */
function buildNarrativePrompt(context: DailyContext): string {
  const lines: string[] = [];

  lines.push('Write a brief, natural journal entry in first person describing this day.');
  lines.push('Write like a real person would - casual, conversational, and human.');
  lines.push('Use ONLY the facts from the data and images provided below.');
  lines.push('');
  lines.push('IMPORTANT RULES:');
  lines.push('- Write in natural paragraphs, NOT bullet points or lists');
  lines.push('- NEVER include coordinates, latitude/longitude, or technical data');
  lines.push('- Use place names naturally (e.g., "went to the park" not "visited 37.7749° N")');
  lines.push('- Write like you\'re texting a friend - brief but personal');
  lines.push('- Do NOT include the date in your output');
  lines.push('');
  lines.push('Data about today:');
  lines.push('');

  // Timeline events
  if (context.timeline_events.length > 0) {
    lines.push('Timeline Events:');
    for (const event of context.timeline_events) {
      const time = new Date(event.timestamp);
      const timeStr = `${time.getHours()}:${time.getMinutes().toString().padStart(2, '0')}`;
      let line = `- ${timeStr}`;

      if (event.place_name) {
        line += ` at ${event.place_name}`;
      }
      if (event.description) {
        line += `: ${event.description}`;
      }
      if (event.objects_seen && event.objects_seen.length > 0) {
        line += ` (${event.objects_seen.slice(0, 3).join(', ')})`;
      }

      lines.push(line);
    }
    lines.push('');
  }

  // Location summary
  if (context.location_summary.significant_places.length > 0) {
    lines.push('Places visited:');
    for (const place of context.location_summary.significant_places) {
      lines.push(`- ${place}`);
    }
    lines.push('');
  }

  // Activity summary
  if (context.activity_summary.primary_activities.length > 0) {
    lines.push('Activities:');
    lines.push(`- ${context.activity_summary.primary_activities.join(', ')}`);
    lines.push('');
  }

  // Social summary
  if (context.social_summary.total_people_detected > 0) {
    lines.push('Social:');
    lines.push(`- ${context.social_summary.total_people_detected} people detected`);
    if (context.social_summary.social_contexts.length > 0) {
      lines.push(`- Context: ${context.social_summary.social_contexts.join(', ')}`);
    }
    lines.push('');
  }

  // Photo contexts
  if (context.photo_contexts.length > 0) {
    lines.push('Photos:');
    lines.push(`- ${context.photo_contexts.length} photos taken`);
    const allObjects = new Set<string>();
    for (const photo of context.photo_contexts) {
      for (const obj of photo.detected_objects) {
        allObjects.add(obj);
      }
    }
    const objectsList = Array.from(allObjects).slice(0, 5);
    if (objectsList.length > 0) {
      lines.push(`- Common subjects: ${objectsList.join(', ')}`);
    }
    lines.push('');
  }

  lines.push('Now write your journal entry:');
  lines.push('- Use natural paragraphs (2-4 sentences each)');
  lines.push('- Be conversational and human');
  lines.push('- NEVER use coordinates or technical data');
  lines.push('- Only mention what actually happened based on the data above');

  return lines.join('\n');
}

export { model };
