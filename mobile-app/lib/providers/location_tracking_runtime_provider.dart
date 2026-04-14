import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Bridge provider for runtime tracker state changes emitted by the background
/// location service.
final locationTrackingRuntimeStateProvider = StateProvider<bool?>(
  (ref) => null,
);
