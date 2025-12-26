import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  RxBool isDark = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDark.value = prefs.getBool("isDark") ?? false;
  }

  Future<void> toggleTheme() async {
    isDark.value = !isDark.value;

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("isDark", isDark.value);
  }
}
