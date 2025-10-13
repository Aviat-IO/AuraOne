class OptimizationManager {
  static final OptimizationManager instance = OptimizationManager._();
  
  OptimizationManager._();
  
  Future<void> initialize() async {
  }
  
  Future<void> dispose() async {
  }
  
  ProcessingQuality getRecommendedQuality() {
    return ProcessingQuality.medium;
  }
  
  bool get isUnderMemoryPressure => false;
}

enum ProcessingQuality {
  maximum,
  high,
  medium,
  low,
  minimal,
}
