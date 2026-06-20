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

  @override
  String get emailRequired => 'メールアドレスを入力してください';

  @override
  String get emailInvalid => '有効なメールアドレスを入力してください';

  @override
  String get passwordRequired => 'パスワードを入力してください';

  @override
  String get passwordTooShort => 'パスワードは6文字以上必要です';

  @override
  String get nameRequired => '名前を入力してください';

  @override
  String get confirmPasswordRequired => 'パスワードを確認してください';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get mustAcceptTerms => '利用規約に同意する必要があります';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get chooseFromGallery => 'ギャラリーから選択';

  @override
  String get changePhoto => '写真を変更';

  @override
  String get removePhoto => '写真を削除';

  @override
  String get uploadSelectedPhoto => '選択した写真をアップロード';

  @override
  String get displayName => '表示名';

  @override
  String get yourName => 'あなたの名前';

  @override
  String get nameMinChars => '最低2文字';

  @override
  String get nameMaxChars => '最大60文字';

  @override
  String get chooseAvatar => 'アバターを選択';

  @override
  String get avatarWillReplacePhoto => 'アバターを選択するとプロフィール写真が削除されます';

  @override
  String get photoUpdated => '写真を更新しました';

  @override
  String get errorUploadingPhoto => '写真のアップロードに失敗しました';

  @override
  String get photoDeleted => '写真を削除しました';

  @override
  String get errorDeletingPhoto => '写真の削除に失敗しました';

  @override
  String get nameUpdated => '名前を更新しました';

  @override
  String get errorUpdatingName => '名前の更新に失敗しました';

  @override
  String get avatarUpdated => 'アバターを更新しました';

  @override
  String get errorChangingAvatar => 'アバターの変更に失敗しました';

  @override
  String get outfitNoName => '名前なしコーデ';

  @override
  String get noGarmentImages => 'アイテムなし';

  @override
  String get noOutfitsSaved => 'まだコーデが保存されていません';

  @override
  String get noOutfitsDescription => 'AIでコーデを生成するか、+ボタンで手動作成してください';

  @override
  String get createOutfit => 'コーデを作成';

  @override
  String get newOutfit => '新しいコーデ';

  @override
  String get outfitName => 'コーデ名';

  @override
  String get outfitCreated => 'コーデを作成しました';

  @override
  String get deleteOutfitTitle => 'コーデを削除';

  @override
  String deleteOutfitConfirm(String name) {
    return '\"$name\"を削除しますか？この操作は元に戻せません。';
  }

  @override
  String get noGarmentsInWardrobe => 'ワードローブにアイテムがありません';

  @override
  String get garmentNoName => '名前なしアイテム';

  @override
  String get howItLooksOnYou => 'あなたに似合う';

  @override
  String get tryOnThisOutfit => 'このコーデを試着';

  @override
  String get tryOnDescription => '実際に着た姿のリアルな画像を生成';

  @override
  String get regenerate => '再生成';

  @override
  String get needBodyPhoto => '全身写真が必要です';

  @override
  String get bodyPhotoDescription => 'コーデが似合うか確認するため、プロフィールに全身写真をアップロードしてください';

  @override
  String get goToMyProfile => 'マイプロフィールへ';

  @override
  String get couldNotGenerateImage => '画像を生成できませんでした';

  @override
  String get imageSavedToGallery => '画像をギャラリーに保存しました';

  @override
  String get couldNotSave => '保存できませんでした';

  @override
  String get errorDownloadingImage => '画像のダウンロードに失敗しました';

  @override
  String get shareInCommunity => 'コミュニティでシェア';

  @override
  String get outfitCaptionHint => 'コーデについて何か書いてください（任意）...';

  @override
  String get publishing => '投稿中...';

  @override
  String get publishedInCommunity => 'コミュニティに投稿しました！';

  @override
  String selectedGarmentsCount(int count) {
    return 'アイテムを選択（$count件選択済み）';
  }

  @override
  String get preparingLook => 'ルックを準備中...';

  @override
  String get applyingGarments => 'アイテムを適用中...';

  @override
  String get adjustingDetails => 'ディテールを調整中...';

  @override
  String get almostReady => 'もうすぐ完成！';

  @override
  String get oneMoreMoment => 'もう少しお待ちください...';

  @override
  String get aiGeneratingImage => 'AIがFLUX.2であなたの画像を生成中';

  @override
  String get closetDeleted => 'クローゼットを削除しました';

  @override
  String get editGarment => 'アイテムを編集';

  @override
  String get garmentDeleted => 'アイテムを削除しました';

  @override
  String get editCloset => 'クローゼットを編集';

  @override
  String get deleteCloset => 'クローゼットを削除';

  @override
  String get addGarment => 'アイテムを追加';

  @override
  String get createMyCloset => 'クローゼットを作成';

  @override
  String get addFirstGarment => '最初のアイテムを追加';

  @override
  String get closetNameRequired => '名前は必須です';

  @override
  String get closetUpdated => 'クローゼットを更新しました';

  @override
  String get garmentAdded => 'アイテムを追加しました';

  @override
  String get mustAddGarment => '少なくとも1つのアイテムを追加してください';

  @override
  String get closetCreated => 'クローゼットを作成しました';

  @override
  String get next => '次へ';

  @override
  String get back => '戻る';

  @override
  String get createCloset => 'クローゼットを作成';

  @override
  String get errorLoading => '読み込みエラー';

  @override
  String get premiumRequired => 'この機能にはプレミアムが必要です';

  @override
  String get findYourStyle => 'あなたのスタイルを見つけよう';

  @override
  String get whatDoYouWantToDo => '何をしますか？';

  @override
  String get recommendedForYou => 'あなたへのおすすめ';

  @override
  String get otherCompatibleStyles => '他の似合うスタイル';

  @override
  String get tryThisStyle => 'このスタイルを試す';

  @override
  String get hairstyleCatalog => 'ヘアスタイルカタログ';

  @override
  String get noHairstylesAvailable => 'ヘアスタイルがありません';

  @override
  String get howToUploadPhoto => '写真のアップロード方法は？';

  @override
  String get fromGallery => 'ギャラリーから';

  @override
  String get selectExistingPhoto => '既存の写真を選択';

  @override
  String get facialDetectionCamera => '顔認識カメラを使用';

  @override
  String get tryAnotherStyle => '別のスタイルを試す';

  @override
  String get analyzingFace => '顔を分析中...';

  @override
  String get reportPost => '投稿を報告';

  @override
  String get deletePost => '投稿を削除';

  @override
  String get reportSent => '報告を送信しました。コミュニティを安全に保っていただきありがとうございます。';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get commentsTitle => 'コメント';

  @override
  String get noCommentsYet => 'まだコメントがありません';

  @override
  String get newPost => '新しい投稿';

  @override
  String get whatDoYouWantToShare => '何をシェアしますか？';

  @override
  String get changeType => 'タイプを変更';

  @override
  String get chooseOutfit => 'コーデを選択';

  @override
  String get tapToChoosePhoto => 'タップして写真を選択';

  @override
  String get writeFashionTip => 'ファッションのヒントを書く';

  @override
  String get descriptionOptional => '説明（任意）';

  @override
  String get reactions => 'リアクション';

  @override
  String get noReactions => 'リアクションなし';

  @override
  String get loginToPublish => 'ログインして投稿';

  @override
  String get postedSuccessfully => '✅ 投稿しました';

  @override
  String get clearFilters => 'フィルターをクリア';

  @override
  String get captionCopied => 'キャプションをクリップボードにコピーしました';

  @override
  String get copyCaption => 'キャプションをコピー';

  @override
  String get colorPalette => 'カラーパレット';

  @override
  String get keywords => 'キーワード';

  @override
  String get contentTypes => 'コンテンツタイプ';

  @override
  String get postIdeas => '投稿アイデア';

  @override
  String get noHashtagsAvailable => 'ハッシュタグがありません';

  @override
  String get allHashtagsCopied => 'すべてのハッシュタグをコピーしました';

  @override
  String get copyAll => 'すべてコピー';

  @override
  String get idealMoments => '最適な投稿時間';

  @override
  String get avoidPosting => '投稿を避ける時間';

  @override
  String generatingGuideFor(String network) {
    return '$network のガイドを生成中...';
  }

  @override
  String generateGuideFor(String network) {
    return '$network のガイドを生成';
  }

  @override
  String hashtagCopied(String tag) {
    return '$tag をコピーしました';
  }

  @override
  String get create => '作成';

  @override
  String get preparingPhoto => '写真を準備中...';

  @override
  String get applyingHairstyle => 'ヘアスタイルを適用中...';

  @override
  String get adjustingStyle => 'スタイルを調整中...';
}
