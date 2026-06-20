// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Style AI';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get confirm => '확인';

  @override
  String get loading => '로딩 중...';

  @override
  String get error => '오류';

  @override
  String get retry => '다시 시도';

  @override
  String get close => '닫기';

  @override
  String get edit => '편집';

  @override
  String get search => '검색';

  @override
  String get refresh => '새로고침';

  @override
  String get done => '완료';

  @override
  String get yes => '예';

  @override
  String get no => '아니요';

  @override
  String get navChat => '채팅';

  @override
  String get navWardrobe => '옷장';

  @override
  String get navCommunity => '커뮤니티';

  @override
  String get navHairstyles => '헤어스타일';

  @override
  String get navProfile => '프로필';

  @override
  String get loginTitle => '로그인';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get rememberMe => '로그인 상태 유지';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get loginButton => '로그인';

  @override
  String get noAccount => '계정이 없으신가요? ';

  @override
  String get signUp => '회원가입';

  @override
  String get registerTitle => '계정 만들기';

  @override
  String get name => '이름';

  @override
  String get confirmPassword => '비밀번호 확인';

  @override
  String get alreadyHaveAccount => '이미 계정이 있으신가요? ';

  @override
  String get signIn => '로그인';

  @override
  String get registerButton => '가입하기';

  @override
  String get settingsTitle => '설정';

  @override
  String get appearance => '화면';

  @override
  String get theme => '테마';

  @override
  String get language => '언어';

  @override
  String get account => '계정';

  @override
  String get profileTile => '프로필';

  @override
  String get profileTileSub => '프로필 보기 및 편집';

  @override
  String get notifications => '알림';

  @override
  String get notificationsSub => '푸시 알림 설정';

  @override
  String get information => '정보';

  @override
  String get about => '앱 정보';

  @override
  String versionLabel(String version) {
    return '버전 $version';
  }

  @override
  String get terms => '이용약관';

  @override
  String get privacy => '개인정보처리방침';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutTitle => '로그아웃';

  @override
  String get logoutConfirm => '정말 로그아웃하시겠습니까?';

  @override
  String get selectTheme => '테마 선택';

  @override
  String get themeSystem => '시스템';

  @override
  String get themeSystemSub => '기기 설정 따르기';

  @override
  String get themeLight => '라이트';

  @override
  String get themeLightSub => '항상 라이트 모드';

  @override
  String get themeDark => '다크';

  @override
  String get themeDarkSub => '항상 다크 모드';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get langSpanish => 'Español';

  @override
  String get langSpanishSub => '스페인어로 전환';

  @override
  String get langEnglish => 'English';

  @override
  String get langEnglishSub => 'Switch to English';

  @override
  String get langPortuguese => 'Português';

  @override
  String get langPortugueseSub => '포르투갈어로 전환';

  @override
  String get aboutContent =>
      'AI 기반 개인 패션 어시스턴트. 완벽한 코디를 만들고, 옷장을 정리하고, 커뮤니티에 스타일을 공유하세요.';

  @override
  String get subscriptionTitle => '프리미엄 구독';

  @override
  String get premiumTitle => 'StyleAI Premium';

  @override
  String get subscribeNow => '지금 구독하기';

  @override
  String get whatsIncluded => '프리미엄에 포함된 것은?';

  @override
  String get choosePlan => '플랜 선택';

  @override
  String get monthly => '월간';

  @override
  String get annual => '연간';

  @override
  String get perMonth => '매월';

  @override
  String get perYear => '매년';

  @override
  String get save33 => '33% 절약';

  @override
  String get securePayment => 'Stripe로 안전하게 결제.\n언제든지 취소 가능합니다.';

  @override
  String get freePlan => '무료 플랜';

  @override
  String get pastDue => '결제 연체';

  @override
  String get cancelledPlan => '취소됨';

  @override
  String get activeBenefits => '활성 혜택';

  @override
  String planRenews(String date) {
    return '플랜이 $date에 갱신됩니다';
  }

  @override
  String get premiumActive => '프리미엄 회원입니다';

  @override
  String get unlimitedAI => '무제한 AI 어시스턴트';

  @override
  String get unlimitedAIDesc => '제한 없이 AI로 코디 생성';

  @override
  String get hairstyleRec => '헤어스타일 추천';

  @override
  String get hairstyleRecDesc => '얼굴 분석 및 맞춤형 제안';

  @override
  String get virtualTryOn => '가상 헤어스타일 체험';

  @override
  String get virtualTryOnDesc => '적용 전 스타일 미리보기';

  @override
  String get priorityAccess => '우선 접근';

  @override
  String get priorityAccessDesc => '새로운 기능에 가장 먼저 접근';

  @override
  String approxLocal(String price, String currency) {
    return '약 $price $currency';
  }

  @override
  String get chargedUSD => 'USD로 청구 · 환율은 근사값';

  @override
  String get communityTitle => '커뮤니티';

  @override
  String get publish => '게시';

  @override
  String get forYou => '추천';

  @override
  String get following => '팔로잉';

  @override
  String get searchPeople => '사람 검색';

  @override
  String get personalBranding => '퍼스널 브랜딩';

  @override
  String get myProfile => '내 프로필';

  @override
  String get editProfile => '프로필 편집';

  @override
  String get fashionProfile => '나의 패션 프로필';

  @override
  String get gender => '성별';

  @override
  String get age => '나이';

  @override
  String get height => '키';

  @override
  String get weight => '체중';

  @override
  String get profession => '직업';

  @override
  String get skinTone => '피부톤';

  @override
  String get faceShape => '얼굴형';

  @override
  String get notSpecified => '미지정';

  @override
  String get memberSince => '가입일';

  @override
  String get wardrobe => '옷장';

  @override
  String get closets => '옷장들';

  @override
  String get garments => '의류';

  @override
  String get myOutfits => '나의 코디';

  @override
  String get hairstyles => '헤어스타일';

  @override
  String get catalog => '카탈로그';

  @override
  String get aiRecommends => 'AI 추천';

  @override
  String get tryOn => '입어보기';

  @override
  String get all => '전체';

  @override
  String get favorites => '즐겨찾기';

  @override
  String get aiAssistant => 'AI 어시스턴트';

  @override
  String get newConversation => '새 대화';

  @override
  String get typeMessage => '메시지 입력...';

  @override
  String get recording => '녹음 중...';

  @override
  String get transcribing => '오디오 변환 중...';

  @override
  String get emailRequired => '이메일을 입력해 주세요';

  @override
  String get emailInvalid => '유효한 이메일을 입력해 주세요';

  @override
  String get passwordRequired => '비밀번호를 입력해 주세요';

  @override
  String get passwordTooShort => '비밀번호는 6자 이상이어야 합니다';

  @override
  String get nameRequired => '이름을 입력해 주세요';

  @override
  String get confirmPasswordRequired => '비밀번호를 확인해 주세요';

  @override
  String get passwordsDoNotMatch => '비밀번호가 일치하지 않습니다';

  @override
  String get mustAcceptTerms => '이용약관에 동의해야 합니다';

  @override
  String get takePhoto => '사진 촬영';

  @override
  String get chooseFromGallery => '갤러리에서 선택';

  @override
  String get changePhoto => '사진 변경';

  @override
  String get removePhoto => '사진 삭제';

  @override
  String get uploadSelectedPhoto => '선택한 사진 업로드';

  @override
  String get displayName => '표시 이름';

  @override
  String get yourName => '이름';

  @override
  String get nameMinChars => '최소 2자';

  @override
  String get nameMaxChars => '최대 60자';

  @override
  String get chooseAvatar => '아바타 선택';

  @override
  String get avatarWillReplacePhoto => '아바타를 선택하면 프로필 사진이 삭제됩니다';

  @override
  String get photoUpdated => '사진이 업데이트되었습니다';

  @override
  String get errorUploadingPhoto => '사진 업로드 오류';

  @override
  String get photoDeleted => '사진이 삭제되었습니다';

  @override
  String get errorDeletingPhoto => '사진 삭제 오류';

  @override
  String get nameUpdated => '이름이 업데이트되었습니다';

  @override
  String get errorUpdatingName => '이름 업데이트 오류';

  @override
  String get avatarUpdated => '아바타가 업데이트되었습니다';

  @override
  String get errorChangingAvatar => '아바타 변경 오류';

  @override
  String get outfitNoName => '이름 없는 코디';

  @override
  String get noGarmentImages => '의류 없음';

  @override
  String get noOutfitsSaved => '저장된 코디가 없습니다';

  @override
  String get noOutfitsDescription => 'AI로 코디를 생성하거나 + 버튼으로 직접 만들어 보세요';

  @override
  String get createOutfit => '코디 만들기';

  @override
  String get newOutfit => '새 코디';

  @override
  String get outfitName => '코디 이름';

  @override
  String get outfitCreated => '코디가 생성되었습니다';

  @override
  String get deleteOutfitTitle => '코디 삭제';

  @override
  String deleteOutfitConfirm(String name) {
    return '\"$name\"을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.';
  }

  @override
  String get noGarmentsInWardrobe => '옷장에 의류가 없습니다';

  @override
  String get garmentNoName => '이름 없는 의류';

  @override
  String get howItLooksOnYou => '착용 모습';

  @override
  String get tryOnThisOutfit => '이 코디 입어보기';

  @override
  String get tryOnDescription => '착용했을 때의 실제 이미지 생성';

  @override
  String get regenerate => '재생성';

  @override
  String get needBodyPhoto => '전신 사진이 필요합니다';

  @override
  String get bodyPhotoDescription => '코디 착용 모습을 보려면 프로필에 전신 사진을 업로드해 주세요';

  @override
  String get goToMyProfile => '내 프로필로 이동';

  @override
  String get couldNotGenerateImage => '이미지를 생성할 수 없습니다';

  @override
  String get imageSavedToGallery => '이미지가 갤러리에 저장되었습니다';

  @override
  String get couldNotSave => '저장할 수 없습니다';

  @override
  String get errorDownloadingImage => '이미지 다운로드 오류';

  @override
  String get shareInCommunity => '커뮤니티에 공유';

  @override
  String get outfitCaptionHint => '코디에 대해 이야기해 주세요 (선택)...';

  @override
  String get publishing => '게시 중...';

  @override
  String get publishedInCommunity => '커뮤니티에 게시되었습니다!';

  @override
  String selectedGarmentsCount(int count) {
    return '의류 선택 ($count개 선택됨)';
  }

  @override
  String get preparingLook => '룩 준비 중...';

  @override
  String get applyingGarments => '의류 적용 중...';

  @override
  String get adjustingDetails => '세부 조정 중...';

  @override
  String get almostReady => '거의 완성!';

  @override
  String get oneMoreMoment => '잠시만 기다려 주세요...';

  @override
  String get aiGeneratingImage => 'AI가 FLUX.2로 이미지를 생성 중입니다';

  @override
  String get closetDeleted => '옷장이 삭제되었습니다';

  @override
  String get editGarment => '의류 편집';

  @override
  String get garmentDeleted => '의류가 삭제되었습니다';

  @override
  String get editCloset => '옷장 편집';

  @override
  String get deleteCloset => '옷장 삭제';

  @override
  String get addGarment => '의류 추가';

  @override
  String get createMyCloset => '내 옷장 만들기';

  @override
  String get addFirstGarment => '첫 번째 의류 추가';

  @override
  String get closetNameRequired => '이름은 필수입니다';

  @override
  String get closetUpdated => '옷장이 업데이트되었습니다';

  @override
  String get garmentAdded => '의류가 추가되었습니다';

  @override
  String get mustAddGarment => '최소 하나의 의류를 추가해야 합니다';

  @override
  String get closetCreated => '옷장이 성공적으로 만들어졌습니다';

  @override
  String get next => '다음';

  @override
  String get back => '뒤로';

  @override
  String get createCloset => '옷장 만들기';

  @override
  String get errorLoading => '로딩 오류';

  @override
  String get premiumRequired => '이 기능은 프리미엄이 필요합니다';

  @override
  String get findYourStyle => '나만의 스타일 찾기';

  @override
  String get whatDoYouWantToDo => '무엇을 하시겠습니까?';

  @override
  String get recommendedForYou => '추천 스타일';

  @override
  String get otherCompatibleStyles => '다른 어울리는 스타일';

  @override
  String get tryThisStyle => '이 스타일 시도하기';

  @override
  String get hairstyleCatalog => '헤어스타일 카탈로그';

  @override
  String get noHairstylesAvailable => '헤어스타일 없음';

  @override
  String get howToUploadPhoto => '사진을 어떻게 업로드하시겠습니까?';

  @override
  String get fromGallery => '갤러리에서';

  @override
  String get selectExistingPhoto => '기존 사진 선택';

  @override
  String get facialDetectionCamera => '얼굴 인식 카메라 사용';

  @override
  String get tryAnotherStyle => '다른 스타일 시도';

  @override
  String get analyzingFace => '얼굴 분석 중...';

  @override
  String get reportPost => '게시물 신고';

  @override
  String get deletePost => '게시물 삭제';

  @override
  String get reportSent => '신고가 접수되었습니다. 커뮤니티를 안전하게 유지해 주셔서 감사합니다.';

  @override
  String get copiedToClipboard => '클립보드에 복사되었습니다';

  @override
  String get commentsTitle => '댓글';

  @override
  String get noCommentsYet => '아직 댓글이 없습니다';

  @override
  String get newPost => '새 게시물';

  @override
  String get whatDoYouWantToShare => '무엇을 공유하시겠습니까?';

  @override
  String get changeType => '유형 변경';

  @override
  String get chooseOutfit => '코디 선택';

  @override
  String get tapToChoosePhoto => '탭하여 사진 선택';

  @override
  String get writeFashionTip => '패션 팁 작성';

  @override
  String get descriptionOptional => '설명 (선택)';

  @override
  String get reactions => '반응';

  @override
  String get noReactions => '반응 없음';

  @override
  String get loginToPublish => '게시하려면 로그인하세요';

  @override
  String get postedSuccessfully => '✅ 게시되었습니다';

  @override
  String get clearFilters => '필터 초기화';

  @override
  String get captionCopied => '캡션이 클립보드에 복사되었습니다';

  @override
  String get copyCaption => '캡션 복사';

  @override
  String get colorPalette => '색상 팔레트';

  @override
  String get keywords => '키워드';

  @override
  String get contentTypes => '콘텐츠 유형';

  @override
  String get postIdeas => '게시물 아이디어';

  @override
  String get noHashtagsAvailable => '해시태그 없음';

  @override
  String get allHashtagsCopied => '모든 해시태그가 복사되었습니다';

  @override
  String get copyAll => '모두 복사';

  @override
  String get idealMoments => '최적 게시 시간';

  @override
  String get avoidPosting => '게시 피해야 할 시간';

  @override
  String generatingGuideFor(String network) {
    return '$network 가이드 생성 중...';
  }

  @override
  String generateGuideFor(String network) {
    return '$network 가이드 생성';
  }

  @override
  String hashtagCopied(String tag) {
    return '$tag 복사됨';
  }

  @override
  String get create => '만들기';

  @override
  String get preparingPhoto => '사진 준비 중...';

  @override
  String get applyingHairstyle => '헤어스타일 적용 중...';

  @override
  String get adjustingStyle => '스타일 조정 중...';
}
