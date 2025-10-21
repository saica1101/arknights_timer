import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class StaminaRepository {
  final Map<int, int> _staminaData = {};

  Future<void> loadCsv() async {
    final csv = await rootBundle.loadString('assets/stamina_data.csv');
    for (final line in LineSplitter.split(csv)) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      final level = int.tryParse(parts[0]) ?? 0;
      final stamina = int.tryParse(parts[1]) ?? 0;
      if (level > 0) _staminaData[level] = stamina;
    }
  }

  bool validateLevel(int level) => _staminaData.containsKey(level);
  bool validateStamina(int current, int max) => current >= 0 && current <= max;
  int getMaxStamina(int level) => _staminaData[level] ?? 0;

  DateTime? calculateRecoveryTime(int current, int max) {
    if (current >= max) return null;
    final diff = max - current;
    return DateTime.now().add(Duration(minutes: diff * 6));
  }

  String formatDateTime(DateTime dt) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
}
