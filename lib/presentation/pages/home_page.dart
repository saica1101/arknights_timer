import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/stamina_provider.dart';
import '../../../providers/theme_provider.dart';
import '../widgets/stamina_progress_ring.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _levelCtrl;
  late final TextEditingController _staminaCtrl;

  @override
  void initState() {
    super.initState();
    _levelCtrl = TextEditingController();
    _staminaCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _levelCtrl.dispose();
    _staminaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaminaProvider>();

    String? levelValidator(String? value) {
      if (value == null || value.isEmpty) return 'レベルを入力してください';
      final lv = int.tryParse(value);
      if (lv == null) return '数字のみを入力してください';
      if (lv < 1 || lv > 120) return 'レベルは 1 〜 120 の範囲で入力してください';
      return null;
    }

    String? staminaValidator(String? value) {
      if (value == null || value.isEmpty) return '現在の理性を入力してください';
      final cur = int.tryParse(value);
      if (cur == null) return '数字のみを入力してください';
      final max = provider.stamina.max;
      if (max <= 0) return '先に有効なプレイヤーレベルを入力してください';
      if (cur < 0) return '0 以上で入力してください';
      if (cur > max) return '現在の理性は上限($max)以下で入力してください';
      return null;
    }

    void tryCalculate() {
      if (provider.isCounting) return;
      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) return;
      FocusScope.of(context).unfocus();
      provider.calculate();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("アークナイツタイマー"),
        centerTitle: true,
        actions: [
          Tooltip(
            message: 'ライト/ダークを切り替え',
            child: IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                final theme = context.read<ThemeProvider>();
                theme.toggleByBrightness(Theme.of(context).brightness);
              },
            ),
          ),
        ],
      ),
      body: provider.isInitialized
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "理性回復管理",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _levelCtrl,
                                          enabled: !provider.isCounting,
                                          decoration: const InputDecoration(
                                            labelText: "プレイヤーレベル",
                                            hintText: "1-120の範囲で入力",
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          validator: levelValidator,
                                          onChanged: provider.updateLevel,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "上限: ${provider.stamina.max > 0 ? provider.stamina.max : '--'}",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _staminaCtrl,
                                    enabled: !provider.isCounting,
                                    decoration: const InputDecoration(
                                      labelText: "現在の理性",
                                      hintText: "現在の理性を入力",
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: staminaValidator,
                                    onChanged: provider.updateStamina,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => tryCalculate(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Builder(
                              builder: (context) {
                                bool looksValid() {
                                  final lv = int.tryParse(_levelCtrl.text);
                                  if (lv == null || lv < 1 || lv > 120) {
                                    return false;
                                  }
                                  final cur = int.tryParse(_staminaCtrl.text);
                                  if (cur == null) {
                                    return false;
                                  }
                                  final max = provider.stamina.max;
                                  if (max <= 0) {
                                    return false;
                                  }
                                  if (cur < 0 || cur > max) {
                                    return false;
                                  }
                                  return true;
                                }

                                String tooltipMessage() {
                                  if (provider.isCounting) {
                                    return '計算中は入力の変更・再計算はできません。リセットしてください。';
                                  }
                                  final valid = looksValid();
                                  if (!valid) {
                                    return '入力値を確認してください(レベル1-120、現在の理性は上限以下)';
                                  }
                                  if (!provider.canCalculate) {
                                    return '入力条件を満たしていません';
                                  }
                                  return '回復時間を計算します';
                                }

                                final canPress =
                                    provider.canCalculate &&
                                    !provider.isCounting;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Tooltip(
                                        message: tooltipMessage(),
                                        child: ElevatedButton(
                                          onPressed: canPress
                                              ? tryCalculate
                                              : null,
                                          // ボタンのスタイルはテーマに委譲
                                          style: null,
                                          child: const Text("タイマースタート"),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Tooltip(
                                      message: provider.isCounting
                                          ? '計算を中止して初期状態に戻します'
                                          : '計算中のみ有効',
                                      child: OutlinedButton(
                                        onPressed: provider.isCounting
                                            ? provider.reset
                                            : null,
                                        // ボタンのスタイルはテーマに委譲
                                        style: null,
                                        child: const Text("リセット"),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.recoveryLabel,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: StaminaProgressRing(
                            value: provider.progress,
                            staminaText: provider.hasCalculated
                                ? "${provider.displayCurrentStamina}/${provider.stamina.max}"
                                : "", // 計算後のみ表示
                            countdownText: provider.countdownText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
