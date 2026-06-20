// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Style AI';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get confirm => '確認';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get retry => 'もう一度';

  @override
  String get close => '閉じる';

  @override
  String get edit => '編集';

  @override
  String get search => '検索';

  @override
  String get refresh => '更新';

  @override
  String get done => '完了';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get navChat => 'チャット';

  @override
  String get navWardrobe => 'ワードローブ';

  @override
  String get navCommunity => 'コミュニティ';

  @override
  String get navHairstyles => 'ヘアスタイル';

  @override
  String get navProfile => 'プロフィール';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get email => 'メール';

  @override
  String get password => 'パスワード';

  @override
  String get rememberMe => 'ログイン状態を保持';

  @override
  String get forgotPassword => 'パスワードをお忘れですか？';

  @override
  String get loginButton => 'ログイン';

  @override
  String get noAccount => 'アカウントをお持ちでない方は ';

  @override
  String get signUp => '登録する';

  @override
  String get registerTitle => 'アカウント作成';

  @override
  String get name => '名前';

  @override
  String get confirmPassword => 'パスワードの確認';

  @override
  String get alreadyHaveAccount => 'すでにアカウントをお持ちですか？ ';

  @override
  String get signIn => 'サインイン';

  @override
  String get registerButton => '登録する';

  @override
  String get settingsTitle => '設定';

  @override
  String get appearance => '外観';

  @override
  String get theme => 'テーマ';

  @override
  String get language => '言語';

  @override
  String get account => 'アカウント';

  @override
  String get profileTile => 'プロフィール';

  @override
  String get profileTileSub => 'プロフィールを表示・編集する';

  @override
  String get notifications => '通知';

  @override
  String get notificationsSub => 'プッシュ通知の設定';

  @override
  String get information => '情報';

  @override
  String get about => 'このアプリについて';

  @override
  String versionLabel(String version) {
    return 'バージョン $version';
  }

  @override
  String get terms => '利用規約';

  @override
  String get privacy => 'プライバシーポリシー';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutTitle => 'ログアウト';

  @override
  String get logoutConfirm => 'ログアウトしてもよろしいですか？';

  @override
  String get selectTheme => 'テーマを選択';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeSystemSub => 'デバイスの設定に従う';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeLightSub => '常にライトモード';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeDarkSub => '常にダークモード';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get langSpanish => 'Español';

  @override
  String get langSpanishSub => 'スペイン語に切り替え';

  @override
  String get langEnglish => 'English';

  @override
  String get langEnglishSub => 'Switch to English';

  @override
  String get langPortuguese => 'Português';

  @override
  String get langPortugueseSub => 'ポルトガル語に切り替え';

  @override
  String get aboutContent =>
      'AIによる個人ファッションアシスタント。完璧なコーディネートを作成し、ワードローブを整理し、コミュニティでスタイルをシェアしましょう。';

  @override
  String get subscriptionTitle => 'プレミアムサブスクリプション';

  @override
  String get premiumTitle => 'StyleAI Premium';

  @override
  String get subscribeNow => '今すぐ登録';

  @override
  String get whatsIncluded => 'プレミアムの内容は？';

  @override
  String get choosePlan => 'プランを選択';

  @override
  String get monthly => '月払い';

  @override
  String get annual => '年払い';

  @override
  String get perMonth => '月額';

  @override
  String get perYear => '年額';

  @override
  String get save33 => '33%節約';

  @override
  String get securePayment => 'Stripeで安全に決済。\nいつでもキャンセル可能です。';

  @override
  String get freePlan => '無料プラン';

  @override
  String get pastDue => '支払い遅延';

  @override
  String get cancelledPlan => 'キャンセル済み';

  @override
  String get activeBenefits => '有効な特典';

  @override
  String planRenews(String date) {
    return 'プランは $date に更新されます';
  }

  @override
  String get premiumActive => 'プレミアム会員';

  @override
  String get unlimitedAI => '無制限AIアシスタント';

  @override
  String get unlimitedAIDesc => '制限なしでAIコーデを生成';

  @override
  String get hairstyleRec => 'ヘアスタイルのおすすめ';

  @override
  String get hairstyleRecDesc => '顔分析とパーソナライズされた提案';

  @override
  String get virtualTryOn => 'バーチャルヘアスタイル体験';

  @override
  String get virtualTryOnDesc => '採用前にスタイルを確認';

  @override
  String get priorityAccess => '優先アクセス';

  @override
  String get priorityAccessDesc => '新機能への優先アクセス';

  @override
  String approxLocal(String price, String currency) {
    return '約 $price $currency';
  }

  @override
  String get chargedUSD => 'USD決済 · 為替レートは参考値';

  @override
  String get communityTitle => 'コミュニティ';

  @override
  String get publish => '投稿';

  @override
  String get forYou => 'おすすめ';

  @override
  String get following => 'フォロー中';

  @override
  String get searchPeople => 'ユーザーを検索';

  @override
  String get personalBranding => 'パーソナルブランディング';

  @override
  String get myProfile => 'マイプロフィール';

  @override
  String get editProfile => 'プロフィール編集';

  @override
  String get fashionProfile => 'ファッションプロフィール';

  @override
  String get gender => '性別';

  @override
  String get age => '年齢';

  @override
  String get height => '身長';

  @override
  String get weight => '体重';

  @override
  String get profession => '職業';

  @override
  String get skinTone => '肌のトーン';

  @override
  String get faceShape => '顔の形';

  @override
  String get notSpecified => '未指定';

  @override
  String get memberSince => 'メンバー歴';

  @override
  String get wardrobe => 'ワードローブ';

  @override
  String get closets => 'クローゼット';

  @override
  String get garments => '衣服';

  @override
  String get myOutfits => 'マイコーデ';

  @override
  String get hairstyles => 'ヘアスタイル';

  @override
  String get catalog => 'カタログ';

  @override
  String get aiRecommends => 'AIおすすめ';

  @override
  String get tryOn => '試着';

  @override
  String get all => 'すべて';

  @override
  String get favorites => 'お気に入り';

  @override
  String get aiAssistant => 'AIアシスタント';

  @override
  String get newConversation => '新しい会話';

  @override
  String get typeMessage => 'メッセージを入力...';

  @override
  String get recording => '録音中...';

  @override
  String get transcribing => '音声を文字起こし中...';
}
