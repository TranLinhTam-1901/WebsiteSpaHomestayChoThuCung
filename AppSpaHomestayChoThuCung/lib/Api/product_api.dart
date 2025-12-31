import 'package:dio/dio.dart';
import '../model/product_detail_model.dart';
import '../model/product_model.dart';
import '../Api/auth_service.dart';

class ProductApi {
  final Dio _dio = Dio(
    BaseOptions(baseUrl:'https://localhost:7051'),
  );


  ProductApi() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthService.jwtToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<List<ProductModel>> getProducts() async {
    final res = await _dio.get(
      '/api/products',
      options: Options(
        headers: {
          'Accept': 'application/json',
        },
      ),
    );
    return (res.data as List)
        .map((e) => ProductModel.fromJson(e))
        .toList();
  }

  Future<ProductDetailModel> getProductDetail(int id) async {
    final res = await _dio.get('/api/products/$id');
    return ProductDetailModel.fromJson(res.data);
  }

  Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    final res = await _dio.get(
      '/api/products',
      queryParameters: {
        'categoryId': categoryId,
      },
      options: Options(
        headers: {'Accept': 'application/json'},
      ),
    );

    return (res.data as List)
        .map((e) => ProductModel.fromJson(e))
        .toList();
  }
}


