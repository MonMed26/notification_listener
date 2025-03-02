import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _cardSizeKey = 'card_size';

  // 保存卡片大小设置
  Future<void> saveCardSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cardSizeKey, size);
  }

  // 获取卡片大小设置，默认为1.0
  Future<double> getCardSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_cardSizeKey) ?? 1.0;
  }
}
