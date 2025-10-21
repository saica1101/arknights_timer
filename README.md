## アークナイツタイマー (Arknights Timer)

理性（Sanity）の回復時間を計算・表示し、満タンになったら通知する Flutter 製アプリです。Windows と Android をサポートします。

### 主な機能

- 入力したレベル/現在理性から、満タンまでの回復予定時刻を表示
- プログレスリングで回復状況を可視化（6 分で +1 ずつ）
- 満タン時に通知
	- Android: バックグラウンド/アプリ終了時でも通知（スケジュール通知）
	- Windows: アプリ起動中の通知（スケジュールは未サポート）
- テーマ切替（ライト/ダーク/システム）と選択状態の永続化
- 入力フォームのバリデーション（数値のみ、IME の「完了」で計算）
- リセットボタン、分かりやすい UI（カード/ボタンの統一スタイル）

### 対応プラットフォーム

- Windows 10+（x64）
- Android 8.0+（API 26+）

---
## インストール
1. [Release]から最新の物をダウンロード
2. 解凍して中に含まれている「ArknightsTimer.exe」を実行
---

## セットアップ(開発者向け)

必要環境（推奨）

- Flutter 3.35.6 / Dart 3.9.2 以降
- Windows: Visual Studio 2022（C++ によるデスクトップ開発 + ATL/MFC）
- Android: Android SDK/NDK、エミュレータ（API 34 など）

依存パッケージ（主要）

- flutter_local_notifications（通知）
- timezone / flutter_timezone（タイムゾーン・スケジュール通知）
- provider（状態管理）
- shared_preferences（テーマモード永続化）
- permission_handler（通知権限）

依存の取得

```pwsh
flutter pub get
```

---

## 実行方法

Windows（デバッグ実行）

```pwsh
flutter run -d windows
```

Android（エミュレータ例）

```pwsh
# エミュレータを起動済みとして
flutter run -d emulator-5554
```

ビルド

```pwsh
# Windows 実行バイナリ
flutter build windows

# Android APK（デバッグ/リリースは適宜）
flutter build apk
```

ランチャーアイコン（必要時）

```pwsh
dart run flutter_launcher_icons
```

---

## 通知の挙動と権限（重要）

Android では、満タン時刻に通知が届くよう「スケジュール通知」を使用します。以下の権限/設定が必要です。

- Android 13+（Tiramisu）: POST_NOTIFICATIONS 権限（初回起動時にリクエスト）
- Android 12+（S/31）: 正確なアラーム（SCHEDULE_EXACT_ALARM）
	- 端末の設定画面で許可が必要な場合があります（アプリ情報 → アラームとリマインダー 等）
- 省電力/自動起動の制限が厳しい端末では、通知が遅延・抑止されることがあります

Windows は現状、アプリ実行中の即時通知のみ対応（スケジュールは未対応）です。

---

## テーマとデザイン

- システムテーマに追従（ThemeMode.system） + アプリ内のテーマ切替（ライト/ダーク）
- 選択状態は SharedPreferences で永続化
- カードやボタンのスタイルを ThemeData で統一（無効時の視認性に配慮）

---

## ディレクトリ構成（抜粋）

```
lib/
	main.dart                       # エントリーポイント（テーマ/ウィンドウ初期化等）
	core/constants/app_colors.dart  # カラーパレット
	data/services/notification_service.dart  # 通知の初期化/送信/スケジュール
	providers/
		stamina_provider.dart         # 回復計算/カウントダウン/表示更新
		theme_provider.dart           # テーマモードと永続化
	presentation/
		pages/home_page.dart          # メイン画面
		widgets/stamina_progress_ring.dart

android/
	app/src/main/AndroidManifest.xml  # アプリ名（ラベル）/権限

windows/
	CMakeLists.txt / runner/*         # Windows ビルド/ウィンドウ/メタ情報
```

---

## よくある問題と対処法（Troubleshooting）

- Windows ビルド時に `atlbase.h` が見つからない
	- Visual Studio の「C++ によるデスクトップ開発」ワークロードに ATL/MFC を追加
	- 本リポジトリでは CMake で ATL を補助的に解決する記述を追加済み

- Android ビルドで desugaring が必要と言われる
	- `android/app/build.gradle(.kts)` で core library desugaring を有効化し `desugar_jdk_libs` を 2.1.5 以上に設定（本プロジェクトは対応済み）

- Android で window_manager の MissingPlugin 例外
	- デスクトップ専用 API 呼び出しはプラットフォームガード（`kIsWeb`/`defaultTargetPlatform`）で保護済み

- Windows の日本語タイトルで C4819 警告（文字コード）
	- ソース内の日本語は Unicode エスケープにしてビルド通過（例: `\u30A2\u30FC...`）

- flutter_timezone の API 差異
	- v5 では `FlutterTimezone.getLocalTimezone()` が `TimezoneInfo` を返します。`identifier` を使用してください（本プロジェクトは対応済み）
---

## ライセンス

- **GNU General Public License version 3**(GPLv3)

---

## 更新履歴
| 日付 | バージョン | 変更履歴 |
| ---- | ---------- | -------- |
| 2025-10-21 | 1.0.0 | 公開 |