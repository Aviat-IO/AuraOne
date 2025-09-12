import 'package:flutter/foundation.dart';
import 'ai_service.dart';
import 'spatiotemporal_processor.dart';
import 'visual_context_processor.dart';

// Stage 3: Multimodal Fusion
class MultimodalFusionProcessor extends PipelineStage {
  final AIServiceConfig config;
  bool _initialized = false;

  MultimodalFusionProcessor(this.config);

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  Future<MultimodalData> fuse(
    SpatiotemporalData spatiotemporalData,
    VisualContextData visualContext,
  ) async {
    // Combine spatiotemporal events with visual context
    final enrichedEvents = <EnrichedEvent>[];

    for (final event in spatiotemporalData.events) {
      // Find all visual events that correlate with this spatiotemporal event
      final correlatedVisuals = visualContext.visualEvents
          .where((ve) => ve.correlatedEvent == event)
          .toList();

      // Create enriched event combining both modalities
      final enriched = EnrichedEvent(
        spatiotemporalEvent: event,
        visualEvents: correlatedVisuals,
        description: _generateEventDescription(event, correlatedVisuals),
      );

      enrichedEvents.add(enriched);
    }

    // Add orphaned visual events (photos without spatiotemporal correlation)
    final orphanedVisuals = visualContext.visualEvents
        .where((ve) => ve.correlatedEvent == null)
        .toList();

    for (final visual in orphanedVisuals) {
      enrichedEvents.add(EnrichedEvent(
        spatiotemporalEvent: null,
        visualEvents: [visual],
        description: _generateVisualOnlyDescription(visual),
      ));
    }

    // Sort events chronologically
    enrichedEvents.sort((a, b) {
      final aTime = a.spatiotemporalEvent?.startTime ?? a.visualEvents.first.timestamp;
      final bTime = b.spatiotemporalEvent?.startTime ?? b.visualEvents.first.timestamp;
      return aTime.compareTo(bTime);
    });

    return MultimodalData(
      date: spatiotemporalData.date,
      enrichedEvents: enrichedEvents,
      totalEvents: enrichedEvents.length,
      hasLocationData: spatiotemporalData.events.isNotEmpty,
      hasVisualData: visualContext.visualEvents.isNotEmpty,
    );
  }

  String _generateEventDescription(
    SpatiotemporalEvent event,
    List<VisualEvent> visuals,
  ) {
    final buffer = StringBuffer();

    // Describe the spatiotemporal aspect
    if (event.type == EventType.stay) {
      buffer.write('Stayed at location');
      if (event.activity != null) {
        buffer.write(' while ${_activityToString(event.activity!)}');
      }
    } else {
      buffer.write('Journey');
      if (event.activity != null) {
        buffer.write(' by ${_activityToString(event.activity!)}');
      }
    }

    // Add duration
    final duration = event.endTime.difference(event.startTime);
    buffer.write(' for ${_formatDuration(duration)}');

    // Add visual context if available
    if (visuals.isNotEmpty) {
      buffer.write('. ');
      if (visuals.length == 1) {
        buffer.write('Captured: ${visuals.first.caption}');
      } else {
        buffer.write('Captured ${visuals.length} photos');
        // Add dominant scene/objects
        final scenes = _extractDominantScenes(visuals);
        if (scenes.isNotEmpty) {
          buffer.write(' showing ${scenes.join(", ")}');
        }
      }
    }

    return buffer.toString();
  }

  String _generateVisualOnlyDescription(VisualEvent visual) {
    return 'Photo: ${visual.caption}';
  }

  String _activityToString(PhysicalActivity activity) {
    switch (activity) {
      case PhysicalActivity.stationary:
        return 'being stationary';
      case PhysicalActivity.walking:
        return 'walking';
      case PhysicalActivity.running:
        return 'running';
      case PhysicalActivity.driving:
        return 'driving';
      case PhysicalActivity.cycling:
        return 'cycling';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minutes';
    } else {
      return 'a few moments';
    }
  }

  List<String> _extractDominantScenes(List<VisualEvent> visuals) {
    final sceneCounts = <String, int>{};

    for (final visual in visuals) {
      for (final scene in visual.sceneLabels) {
        if (scene.confidence > 0.5) {
          sceneCounts[scene.label] = (sceneCounts[scene.label] ?? 0) + 1;
        }
      }
    }

    // Get top 3 scenes
    final sorted = sceneCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key.toLowerCase()).toList();
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }

  @override
  bool get isInitialized => _initialized;
}

// Data models for multimodal fusion
class EnrichedEvent {
  final SpatiotemporalEvent? spatiotemporalEvent;
  final List<VisualEvent> visualEvents;
  final String description;

  EnrichedEvent({
    this.spatiotemporalEvent,
    required this.visualEvents,
    required this.description,
  });

  DateTime get startTime {
    if (spatiotemporalEvent != null) {
      return spatiotemporalEvent!.startTime;
    }
    return visualEvents.first.timestamp;
  }

  DateTime get endTime {
    if (spatiotemporalEvent != null) {
      return spatiotemporalEvent!.endTime;
    }
    return visualEvents.last.timestamp;
  }
}

class MultimodalData {
  final DateTime date;
  final List<EnrichedEvent> enrichedEvents;
  final int totalEvents;
  final bool hasLocationData;
  final bool hasVisualData;

  MultimodalData({
    required this.date,
    required this.enrichedEvents,
    required this.totalEvents,
    required this.hasLocationData,
    required this.hasVisualData,
  });
}
