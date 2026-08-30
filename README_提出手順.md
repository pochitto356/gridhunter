# GRID HUNTER — App Store 提出キット

このフォルダには、GRID HUNTER を iOS アプリとして App Store に提出するために必要な一式が入っています。

## フォルダ構成

```
appkit/
├── www/                    ← ゲーム本体(アプリ版: セーブ機能・オフライン対応済み)
│   ├── index.html          ← ゲーム(ベストスコア・実績を端末に自動保存)
│   ├── manifest.webmanifest ← PWA設定
│   ├── sw.js               ← オフライン用サービスワーカー
│   └── icons/              ← ホーム画面アイコン
├── assets/                 ← アイコン・スプラッシュの元画像(自動リサイズ用)
│   ├── icon.png            (1024x1024)
│   └── splash.png          (2732x2732)
├── capacitor.config.json   ← Capacitor設定
├── package.json            ← 依存パッケージ定義
└── README_提出手順.md      ← このファイル
```

## 事前に必要なもの

1. **Apple Developer Program への登録**(年間 99 米ドル ≒ 約14,000〜15,000円)
   https://developer.apple.com/programs/ から Apple ID で登録。個人でOK。
   審査(身分確認)に数日かかることがあるので最初に申し込んでおくのがおすすめ。
2. **appId の変更**: `capacitor.config.json` の `"appId": "com.example.gridhunter"` を
   自分のものに変更してください(例: `com.あなたの名前.gridhunter`)。世界で一意であれば何でもOK。

## Mac を持っていない場合の選択肢

iOS アプリのビルドと提出だけは Apple のツール(Xcode)が必要です。Mac がない場合:

| 方法 | 費用目安 | 向いている人 |
|---|---|---|
| **A. クラウドMacレンタル** (MacinCloud, Scaleway など) | 月 約30〜60ドル(時間課金あり) | 自分で全工程を触りたい |
| **B. CI ビルドサービス** (Codemagic など) | 無料枠あり | GitHubにコードを置ける |
| **C. 知人のMacを借りる** | 無料 | 数時間で終わらせたい(工程は下記の通り単純) |

初回は A か C が簡単です。B(Codemagic)は証明書の設定に慣れが必要ですが、2回目以降の更新が自動化できます。

## Mac での手順(所要 1〜2時間)

```bash
# 0. 準備: App Store から Xcode をインストール、Node.js をインストール (https://nodejs.org)

# 1. このフォルダで依存関係を入れる
npm install

# 2. iOSプロジェクトを生成
npx cap add ios

# 3. アイコンとスプラッシュを全サイズ自動生成
npx capacitor-assets generate --ios

# 4. ゲームをiOSプロジェクトに同期
npx cap sync

# 5. Xcodeで開く
npx cap open ios
```

### Xcode での設定

1. 左のツリーで **App** を選択 → **Signing & Capabilities** タブ
   → **Team** に自分の Apple Developer アカウントを選択(自動署名でOK)
2. **General** タブ → Deployment Info で
   **Landscape Left / Landscape Right のみチェック**(縦持ちを外すとゲームが遊びやすい)
3. 実機を USB 接続して ▶ ボタンで動作確認

### App Store への提出

1. https://appstoreconnect.apple.com で「新規アプリ」を作成
   (名前: GRID HUNTER、プライマリ言語: 日本語、Bundle ID: 上で決めた appId)
2. Xcode メニュー → **Product > Archive** → **Distribute App** → App Store Connect
3. App Store Connect でスクリーンショット(iPhone用 6.9インチ等)と説明文を登録
4. **TestFlight** で自分の端末に配信して最終確認(推奨)
5. 「審査へ提出」→ 通常1〜3日で結果が来ます

### 審査で聞かれる項目の答え方(このゲームの場合)

- **年齢レーティング**: 質問にすべて「なし」で回答 → **4+** になります(コミカルな表現の軽微な暴力を選んでも 9+ 程度)
- **プライバシー**: AdMob広告を入れているため「データを収集する」を選択し、
  以下を申告 → 「識別子(デバイスID)」「使用状況データ」を **広告目的で収集・トラッキングに使用**
  (AdMobのApple プライバシー詳細ページの最新指定に従ってください)
- **輸出コンプライアンス**: 標準的なHTTPS通信のみなので「免除に該当」(いいえ)
- **サードパーティコンテンツ**: なし

## 広告(AdMobバナー)と広告削除課金のセットアップ

ゲームには **画面下部のバナー広告** と **「広告を削除」の買い切り課金(復元ボタン付き)** が
組み込み済みです。Web/PWA版では自動的に無効になり、ネイティブアプリでのみ動作します。
有効化には以下の設定が必要です。

### 1. AdMob側の設定

1. https://admob.google.com でアカウント作成 → 「アプリを追加」(iOS)
2. **アプリID**(`ca-app-pub-xxxx~yyyy` の形式)と、
   **バナー広告ユニットID**(`ca-app-pub-xxxx/zzzz` の形式)を作成・控える
3. `www/index.html` 内の `MZ` 設定を書き換える:
   - `BANNER_AD_ID` → 自分のバナー広告ユニットID
   - `IS_TESTING` → 公開ビルドでは `false`
   (初期状態はGoogle公式のテストIDなので、そのままでもテスト広告が出ます)

### 2. Info.plist への追記(Xcodeで ios/App/App/Info.plist を開く)

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxx~yyyy</string>  <!-- 自分のAdMobアプリID -->
<key>NSUserTrackingUsageDescription</key>
<string>広告の品質向上のために使用されます。</string>
```

さらに **SKAdNetworkItems** の追加が必要です。項目一覧はAdMob公式ドキュメントの
「iOS SKAdNetwork」ページからコピーしてください(随時更新されるため)。

### 3. App Store Connect でアプリ内課金を作る

1. アプリのページ → 「アプリ内課金」→「+」→ **非消耗型 (Non-Consumable)**
2. プロダクトID: **`remove_ads`**(ゲーム側のコードと一致させる。変える場合は
   `www/index.html` の `PRODUCT_ID` も変更)
3. 価格(例: ¥300)、表示名「広告を削除」、説明、審査用スクリーンショットを登録
4. アプリの審査提出時に、この課金アイテムも一緒に提出する

### 4. 動作テスト

- App Store Connect → 「ユーザとアクセス」→ **Sandboxテスター** を作成
- 実機のiPhoneで 設定 → App Store → サンドボックスアカウント にそのテスターでログイン
- アプリ内で「広告を削除」を押すと **実際の請求なし** で購入フローをテストできます
- 「購入を復元」ボタンで、再インストール後も購入が引き継がれることを確認
  (復元ボタンはAppleの審査必須要件なので消さないでください)

### 挙動の仕様

- 広告バナーは画面下部に表示され、ゲーム画面は自動で上にずれて隠れません
- 購入完了(または復元)すると: バナー即時消滅、購入ボタン非表示、状態は端末に保存
- 通信オフライン時は広告が出ないだけでゲームは通常通り遊べます

## すぐに配布したい場合: PWA(App Store 不要)

`www/` フォルダを HTTPS の静的ホスティングに置くだけで、iPhone の Safari から
「共有 → ホーム画面に追加」でフルスクリーンのアプリとして遊べます。オフラインでも動きます。

無料ホスティングの例:
- **GitHub Pages**: リポジトリに www/ の中身を置いて Settings → Pages で公開
- **Netlify / Cloudflare Pages**: www/ フォルダをドラッグ&ドロップするだけ
- **itch.io**: ゲーム専門ポータル。zip をアップロードすれば HTML5 ゲームとして公開でき、
  ゲーマーに発見されやすい(ダウンロード数を稼ぐならまずここがおすすめ)

## アプリ版で追加されている機能

- ベストスコア・ベストタイム・実績・称号・ミュート設定が**端末に自動保存**され、アプリを閉じても消えません
- iPhone のノッチ/ホームバー(セーフエリア)を避けたレイアウト
- オフライン動作(機内モードでも遊べます)

## トラブルシューティング

- `npx cap add ios` で CocoaPods エラー → `sudo gem install cocoapods` を実行してから再試行
- Xcode で署名エラー → Signing & Capabilities の Team が選ばれているか、
  Bundle Identifier が App Store Connect の登録と一致しているか確認
- 実機で音が出ない → iPhone のサイレントスイッチを確認(仕様上、初回タップ後に音が有効になります)
