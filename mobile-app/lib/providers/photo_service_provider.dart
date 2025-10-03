// Photo service provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/photo_service.dart';

// Photo Service Provider
final photoServiceProvider = Provider<PhotoService>((ref) {
  return PhotoService(ref);
});