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
}
