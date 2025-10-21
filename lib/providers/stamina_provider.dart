import 'dart:async';
import 'package:flutter/material.dart';
import '../data/repositories/stamina_repository.dart';
import '../data/services/notification_service.dart';
import '../domain/entities/stamina.dart';

class StaminaProvider extends ChangeNotifier {
  final StaminaRepository _repo = StaminaRepository();
  final NotificationService _notifier = NotificationService();

  Stamina stamina = Stamina(level: 0, current: 0, max: 0);
  DateTime? recoveryTime;
  Timer? countdown;

  double progress = 0.0;
  String countdownText = "";
  String recoveryLabel = "回復予定時刻: --";

  // カウントダウン動作フラグとスナップショット
  bool isCounting = false;
  bool hasCalculated = false; // 計算ボタン押下後かどうか
  int _baseCurrent = 0;
  int _baseMax = 0;

  bool _initialized = false;

  StaminaProvider() {
    _init();
  }

  Future<void> _init() async {
    await _repo.loadCsv();
    _initialized = true;
    notifyListeners();
  }

  bool get isInitialized => _initialized;

  bool get canCalculate =>
      _repo.validateLevel(stamina.level) &&
      _repo.validateStamina(stamina.current, stamina.max);

  void updateLevel(String value) {
    final lv = int.tryParse(value) ?? 0;
    if (lv >= 1 && lv <= 120 && _repo.validateLevel(lv)) {
      stamina = stamina.copyWith(level: lv, max: _repo.getMaxStamina(lv));
    } else {
      stamina = stamina.copyWith(level: 0, max: 0);
    }
    // 入力中はUIに反映するだけ。カウントダウン中はスナップショットに影響させない。
    notifyListeners();
  }

  void updateStamina(String value) {
    stamina = stamina.copyWith(current: int.tryParse(value) ?? 0);
    notifyListeners();
  }

  void calculate() {
    // 計算開始時点のスナップショットを固定
    _baseCurrent = stamina.current;
    _baseMax = stamina.max;
    isCounting = true;
    hasCalculated = true;

    recoveryTime = _repo.calculateRecoveryTime(_baseCurrent, _baseMax);
    if (recoveryTime == null) {
      recoveryLabel = "理性は既に満タンです";
      progress = 1.0;
      isCounting = false;
      // 表示が初期入力値のままにならないよう、現在理性を上限に合わせる
      stamina = stamina.copyWith(current: stamina.max);
    } else {
      recoveryLabel = "回復予定時刻: ${_repo.formatDateTime(recoveryTime!)}";
      _startCountdown();
      // バックグラウンド/終了時でも通知されるよう予約
      _notifier.cancelScheduledRecoveryNotification();
      _notifier.scheduleRecoveryNotification(recoveryTime!);
    }
    notifyListeners();
  }

  void _startCountdown() {
    countdown?.cancel();
    countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (recoveryTime == null || !isCounting) return;

      final remaining = recoveryTime!.difference(DateTime.now());
      if (remaining.isNegative) {
        progress = 1.0;
        countdownText = "完了！";
        // 完了時に現在理性を上限へ更新して表示を max/max にする
        stamina = stamina.copyWith(current: stamina.max);
        recoveryLabel = "理性は満タンです";
        // 予約済み通知があれば解除してから即時通知
        _notifier.cancelScheduledRecoveryNotification();
        _notifier.sendRecoveryNotification();
        countdown?.cancel();
        isCounting = false;
        recoveryTime = null;
      } else {
        // 6分(=360秒) で理性が1回復。スナップショットで固定。
        final total = (_baseMax - _baseCurrent) * 360;
        final elapsed = total - remaining.inSeconds;
        final recovered = (elapsed ~/ 360);
        final display = (_baseCurrent + recovered).clamp(0, _baseMax);
        progress = _baseMax == 0 ? 0.0 : display / _baseMax;
        final h = remaining.inHours.toString().padLeft(2, '0');
        final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
        final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
        countdownText = "$h:$m:$s";
      }
      notifyListeners();
    });
  }

  // 表示用：カウント中はスナップショットベースで現在理性を算出
  int get displayCurrentStamina {
    if (!isCounting || recoveryTime == null) return stamina.current;
    final remaining = recoveryTime!.difference(DateTime.now());
    if (remaining.isNegative) return _baseMax;
    final total = (_baseMax - _baseCurrent) * 360;
    final elapsed = total - remaining.inSeconds;
    final recovered = (elapsed ~/ 360);
    return (_baseCurrent + recovered).clamp(0, _baseMax);
  }

  void reset() {
    countdown?.cancel();
    isCounting = false;
    hasCalculated = false;
    recoveryTime = null;
    progress = 0.0;
    countdownText = "";
    recoveryLabel = "回復予定時刻: --";
    // 既存のスケジュール通知を解除
    _notifier.cancelScheduledRecoveryNotification();
    notifyListeners();
  }

  @override
  void dispose() {
    countdown?.cancel();
    super.dispose();
  }
}
