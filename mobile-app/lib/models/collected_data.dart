/// Model representing collected data from various sources
class CollectedData {
  final String id;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  CollectedData({
    required this.id,
    required this.type,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };

  factory CollectedData.fromJson(Map<String, dynamic> json) => CollectedData(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    type: json['type'] ?? 'unknown',
    timestamp: json['timestamp'] is String
        ? DateTime.parse(json['timestamp'])
        : json['timestamp'] ?? DateTime.now(),
    data: json['data'],
  );
}