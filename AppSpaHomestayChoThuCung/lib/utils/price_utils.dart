import 'package:intl/intl.dart';

String formatPrice(num price) {
  final formatter = NumberFormat('#,###', 'vi_VN');
  return '${formatter.format(price)} đ';
}