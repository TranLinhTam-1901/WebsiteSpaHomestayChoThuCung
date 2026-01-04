import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/category_model.dart';


class CategoryService {
  static const String baseUrl = 'https://localhost:7051';


  static Future<List<CategoryModel>> getCategories() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/categories'),
    );

    if (res.statusCode != 200) {
      throw Exception('Không tải được danh mục');
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => CategoryModel.fromJson(e)).toList();
  }
}
