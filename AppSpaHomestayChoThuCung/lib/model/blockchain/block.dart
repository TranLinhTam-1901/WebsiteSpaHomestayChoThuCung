import 'dart:convert';
import 'package:crypto/crypto.dart';

class Block {
  final int index;
  final DateTime timestamp;
  final String data;
  final String previousHash;
  late String hash;

  Block({
    required this.index,
    required this.timestamp,
    required this.data,
    required this.previousHash,
  }) {
    hash = calculateHash();
  }

  // Hàm tính toán Hash SHA256 tương đương C#
  String calculateHash() {
    var rawData = "$index-$timestamp-$data-$previousHash";
    var bytes = utf8.encode(rawData); // Chuyển String sang bytes
    var digest = sha256.convert(bytes); // Tính hash SHA256
    return base64.encode(digest.bytes); // Trả về Base64 giống Convert.ToBase64String
  }
}