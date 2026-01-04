import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ReviewApi {
  static const String baseUrl = "https://localhost:7051";

  static Future<void> postReview({
    required String token,
    required int productId,
    required int rating,
    String? comment,
    List<XFile>? images,
  }) async {
    final uri = Uri.parse("$baseUrl/api/reviews");

    final request = http.MultipartRequest("POST", uri);

    // 🔐 AUTH
    request.headers["Authorization"] = "Bearer $token";

    // 📦 FORM DATA
    request.fields["targetId"] = productId.toString();
    request.fields["rating"] = rating.toString();
    if (comment != null && comment.trim().isNotEmpty) {
      request.fields["comment"] = comment;
    }

    // 🖼 FILES (WEB)
    if (images != null) {
      for (final img in images) {
        final bytes = await img.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            "reviewImages",
            bytes,
            filename: img.name,
          ),
        );
      }
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception("POST REVIEW FAILED: $body");
    }
  }
}
