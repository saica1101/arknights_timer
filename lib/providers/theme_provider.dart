import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリのテーマモードを管理するプロバイダ。
/// 既定はシステム設定に追従。ユーザー操作で Light/Dark に明示切替可能。
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    _persist();
  }

  /// 現在の実効の明暗（Theme.of(context).brightness）に対して
  /// 反対側のテーマへ明示的に切り替える。
  void toggleByBrightness(Brightness currentBrightness) {
    setMode(
      currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  /// 3 状態の循環（system -> light -> dark -> system）を使いたい場合の補助。
  void cycle() {
    switch (_mode) {
      case ThemeMode.system:
        setMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        setMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setMode(ThemeMode.system);
        break;
    }
  }

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final value = sp.getString('theme_mode');
    switch (value) {
      case 'light':
        _mode = ThemeMode.light;
        break;
      case 'dark':
        _mode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    final value = switch (_mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await sp.setString('theme_mode', value);
  }
}
