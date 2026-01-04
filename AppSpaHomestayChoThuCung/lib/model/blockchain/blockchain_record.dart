import 'dart:convert';

class BlockchainRecord {
  final int id;
  final int blockNumber;
  final String recordType;
  final String operation;
  final String referenceId;
  final String dataJson;
  final String hash;
  final String previousHash;
  final DateTime timestamp;
  final String performedBy;
  final String? transactionHash;

  // Biến dùng để kiểm tra tính hợp lệ trên giao diện (không cần từ API)
  bool isValid;

  BlockchainRecord({
    required this.id,
    required this.blockNumber,
    required this.recordType,
    required this.operation,
    required this.referenceId,
    required this.dataJson,
    required this.hash,
    required this.previousHash,
    required this.timestamp,
    required this.performedBy,
    this.transactionHash,
    this.isValid = true, // Mặc định là true
  });

  // Getter để parse dataJson thành Map khi cần hiển thị chi tiết
  Map<String, dynamic> get details {
    try {
      return json.decode(dataJson);
    } catch (e) {
      return {};
    }
  }

  factory BlockchainRecord.fromJson(Map<String, dynamic> json) {
    return BlockchainRecord(
      id: json['id'] ?? 0,
      blockNumber: json['blockNumber'] ?? 0,
      recordType: json['recordType'] ?? 'Unknown',
      operation: json['operation'] ?? 'N/A',
      referenceId: json['referenceId']?.toString() ?? '',
      dataJson: json['dataJson'] ?? '',
      hash: json['hash'] ?? '',
      previousHash: json['previousHash'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      performedBy: json['performedBy'] ?? 'Hệ thống',
      transactionHash: json['transactionHash'],
    );
  }

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