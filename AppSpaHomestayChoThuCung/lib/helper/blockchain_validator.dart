import '../model/Blockchain/blockchain_record.dart';

class BlockchainValidator {
  static bool isChainValid(List<BlockchainRecord> records) {
    for (int i = 1; i < records.length; i++) {
      final current = records[i];
      final previous = records[i - 1];

      // 1. Kiểm tra PreviousHash của block hiện tại có khớp với Hash của block trước không
      if (current.previousHash != previous.hash) {
        return false;
      }

      // 2. Tái tính toán hash để kiểm tra dữ liệu có bị sửa đổi không
      // (Lưu ý: Logic chuỗi nối String để tính Hash ở Flutter phải giống hệt C#)
    }
    return true;
  }
}