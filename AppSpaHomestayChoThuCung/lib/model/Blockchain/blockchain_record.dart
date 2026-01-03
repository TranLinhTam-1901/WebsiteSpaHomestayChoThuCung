class BlockchainRecord {
  final int? id;
  final int blockNumber;
  final String recordType;
  final String operation;
  final String referenceId;
  final String dataJson;
  final String hash;
  final String previousHash;
  final DateTime timestamp;
  final String? performedBy;
  final String? transactionHash;

  BlockchainRecord({
    this.id,
    required this.blockNumber,
    required this.recordType,
    required this.operation,
    required this.referenceId,
    required this.dataJson,
    required this.hash,
    required this.previousHash,
    required this.timestamp,
    this.performedBy,
    this.transactionHash,
  });

  // Chuyển từ JSON (API) sang Object Flutter
  factory BlockchainRecord.fromJson(Map<String, dynamic> json) {
    return BlockchainRecord(
      id: json['id'],
      blockNumber: json['blockNumber'] ?? 0,
      recordType: json['recordType'] ?? '',
      operation: json['operation'] ?? '',
      referenceId: json['referenceId'] ?? '',
      dataJson: json['dataJson'] ?? '',
      hash: json['hash'] ?? '',
      previousHash: json['previousHash'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      performedBy: json['performedBy'],
      transactionHash: json['transactionHash'],
    );
  }

  // Chuyển từ Object sang Map (để gửi ngược lên API nếu cần)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blockNumber': blockNumber,
      'recordType': recordType,
      'operation': operation,
      'referenceId': referenceId,
      'dataJson': dataJson,
      'hash': hash,
      'previousHash': previousHash,
      'timestamp': timestamp.toIso8601String(),
      'performedBy': performedBy,
      'transactionHash': transactionHash,
    };
  }
}