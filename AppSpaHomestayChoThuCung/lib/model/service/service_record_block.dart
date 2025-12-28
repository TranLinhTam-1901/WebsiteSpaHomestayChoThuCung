class ServiceRecordBlockModel {
  final int blockId;
  final int recordId;
  final String currentHash;
  final String? previousHash;
  final DateTime timestamp;

  ServiceRecordBlockModel({
    required this.blockId,
    required this.recordId,
    required this.currentHash,
    this.previousHash,
    required this.timestamp,
  });

  factory ServiceRecordBlockModel.fromJson(Map<String, dynamic> json) {
    return ServiceRecordBlockModel(
      blockId: json['blockId'],
      recordId: json['recordId'],
      currentHash: json['currentHash'],
      previousHash: json['previousHash'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}