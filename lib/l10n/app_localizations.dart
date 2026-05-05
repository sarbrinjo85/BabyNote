import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'베이비노트'**
  String get appTitle;

  /// No description provided for @homeWelcome.
  ///
  /// In ko, this message translates to:
  /// **'환영합니다'**
  String get homeWelcome;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// No description provided for @commonRegister.
  ///
  /// In ko, this message translates to:
  /// **'등록'**
  String get commonRegister;

  /// No description provided for @commonRegistering.
  ///
  /// In ko, this message translates to:
  /// **'등록 중…'**
  String get commonRegistering;

  /// No description provided for @commonSaving.
  ///
  /// In ko, this message translates to:
  /// **'저장 중…'**
  String get commonSaving;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @commonAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get commonAdd;

  /// No description provided for @commonOr.
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get commonOr;

  /// No description provided for @commonNoSelection.
  ///
  /// In ko, this message translates to:
  /// **'선택 안 함'**
  String get commonNoSelection;

  /// No description provided for @commonOptional.
  ///
  /// In ko, this message translates to:
  /// **'(선택)'**
  String get commonOptional;

  /// No description provided for @commonTapToSelect.
  ///
  /// In ko, this message translates to:
  /// **'탭해서 선택'**
  String get commonTapToSelect;

  /// No description provided for @commonNumberOnly.
  ///
  /// In ko, this message translates to:
  /// **'숫자만 입력해주세요.'**
  String get commonNumberOnly;

  /// No description provided for @commonPositiveOnly.
  ///
  /// In ko, this message translates to:
  /// **'양수만 입력해주세요.'**
  String get commonPositiveOnly;

  /// No description provided for @commonNoRecordYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록 없음'**
  String get commonNoRecordYet;

  /// No description provided for @commonNoEntryYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 없음'**
  String get commonNoEntryYet;

  /// No description provided for @commonDataInsufficient.
  ///
  /// In ko, this message translates to:
  /// **'데이터 부족'**
  String get commonDataInsufficient;

  /// No description provided for @commonRegisterChildFirst.
  ///
  /// In ko, this message translates to:
  /// **'먼저 자녀를 등록해주세요.'**
  String get commonRegisterChildFirst;

  /// No description provided for @commonGoRegisterChild.
  ///
  /// In ko, this message translates to:
  /// **'자녀 등록하러 가기'**
  String get commonGoRegisterChild;

  /// No description provided for @commonNotLoggedIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인되지 않았어요.'**
  String get commonNotLoggedIn;

  /// No description provided for @commonMemoOptional.
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get commonMemoOptional;

  /// No description provided for @errorFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패: {error}'**
  String errorFailed(Object error);

  /// No description provided for @errorChildrenLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'자녀 목록 로딩 실패: {error}'**
  String errorChildrenLoadFailed(Object error);

  /// No description provided for @errorChildLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'자녀 로딩 실패: {error}'**
  String errorChildLoadFailed(Object error);

  /// No description provided for @errorAuthStream.
  ///
  /// In ko, this message translates to:
  /// **'인증 스트림 에러: {error}'**
  String errorAuthStream(Object error);

  /// No description provided for @timeJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금 전'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 전'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간 전'**
  String timeHoursAgo(int n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 전'**
  String timeDaysAgo(int n);

  /// No description provided for @timeYesterdayAt.
  ///
  /// In ko, this message translates to:
  /// **'어제 {hhmm}'**
  String timeYesterdayAt(String hhmm);

  /// No description provided for @authStartTitle.
  ///
  /// In ko, this message translates to:
  /// **'베이비노트 시작'**
  String get authStartTitle;

  /// No description provided for @authLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get authLogin;

  /// No description provided for @authSignup.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get authSignup;

  /// No description provided for @authEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get authPassword;

  /// No description provided for @homeLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get homeLogout;

  /// No description provided for @homeMyChildren.
  ///
  /// In ko, this message translates to:
  /// **'내 자녀'**
  String get homeMyChildren;

  /// No description provided for @homeAddChild.
  ///
  /// In ko, this message translates to:
  /// **'자녀 추가'**
  String get homeAddChild;

  /// No description provided for @homeFirstChild.
  ///
  /// In ko, this message translates to:
  /// **'첫 자녀 등록'**
  String get homeFirstChild;

  /// No description provided for @homeNoChildYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록된 자녀가 없어요'**
  String get homeNoChildYet;

  /// No description provided for @homeChildSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'{gender} · 생후 {days}일'**
  String homeChildSubtitle(String gender, int days);

  /// No description provided for @homeLastActivity.
  ///
  /// In ko, this message translates to:
  /// **'마지막 활동'**
  String get homeLastActivity;

  /// No description provided for @homeTodayRecord.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 기록'**
  String get homeTodayRecord;

  /// No description provided for @homeInventory.
  ///
  /// In ko, this message translates to:
  /// **'재고 관리'**
  String get homeInventory;

  /// No description provided for @homeFormulaInventoryEntry.
  ///
  /// In ko, this message translates to:
  /// **'분유 재고 관리'**
  String get homeFormulaInventoryEntry;

  /// No description provided for @homeDiaperInventoryEntry.
  ///
  /// In ko, this message translates to:
  /// **'기저귀 재고 관리'**
  String get homeDiaperInventoryEntry;

  /// No description provided for @homeHospital.
  ///
  /// In ko, this message translates to:
  /// **'병원'**
  String get homeHospital;

  /// No description provided for @homeHospitalEntry.
  ///
  /// In ko, this message translates to:
  /// **'단골 병원 (전화 · 길찾기)'**
  String get homeHospitalEntry;

  /// No description provided for @homeVaccineEntry.
  ///
  /// In ko, this message translates to:
  /// **'예방접종 일정'**
  String get homeVaccineEntry;

  /// No description provided for @homeNoLogin.
  ///
  /// In ko, this message translates to:
  /// **'비로그인'**
  String get homeNoLogin;

  /// No description provided for @homeAnonymous.
  ///
  /// In ko, this message translates to:
  /// **'익명'**
  String get homeAnonymous;

  /// No description provided for @homeUser.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get homeUser;

  /// No description provided for @childRegisterTitle.
  ///
  /// In ko, this message translates to:
  /// **'자녀 등록'**
  String get childRegisterTitle;

  /// No description provided for @childName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get childName;

  /// No description provided for @childNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 김아기'**
  String get childNameHint;

  /// No description provided for @childNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'이름은 필수예요.'**
  String get childNameRequired;

  /// No description provided for @childGender.
  ///
  /// In ko, this message translates to:
  /// **'성별'**
  String get childGender;

  /// No description provided for @childGenderFemale.
  ///
  /// In ko, this message translates to:
  /// **'여아'**
  String get childGenderFemale;

  /// No description provided for @childGenderMale.
  ///
  /// In ko, this message translates to:
  /// **'남아'**
  String get childGenderMale;

  /// No description provided for @childGenderOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get childGenderOther;

  /// No description provided for @childGenderUnset.
  ///
  /// In ko, this message translates to:
  /// **'미지정'**
  String get childGenderUnset;

  /// No description provided for @childBirthDate.
  ///
  /// In ko, this message translates to:
  /// **'생년월일'**
  String get childBirthDate;

  /// No description provided for @childBirthDateHelp.
  ///
  /// In ko, this message translates to:
  /// **'자녀 생년월일 선택'**
  String get childBirthDateHelp;

  /// No description provided for @childBirthDateRequired.
  ///
  /// In ko, this message translates to:
  /// **'생년월일을 선택해주세요.'**
  String get childBirthDateRequired;

  /// No description provided for @childBirthWeightLabel.
  ///
  /// In ko, this message translates to:
  /// **'출생 시 무게 (kg, 선택)'**
  String get childBirthWeightLabel;

  /// No description provided for @childBirthWeightHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 3.45'**
  String get childBirthWeightHint;

  /// No description provided for @childBirthHeightLabel.
  ///
  /// In ko, this message translates to:
  /// **'출생 시 키 (cm, 선택)'**
  String get childBirthHeightLabel;

  /// No description provided for @childBirthHeightHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 51.5'**
  String get childBirthHeightHint;

  /// No description provided for @childRegisterFailed.
  ///
  /// In ko, this message translates to:
  /// **'등록 실패: {error}'**
  String childRegisterFailed(Object error);

  /// No description provided for @feedingTitle.
  ///
  /// In ko, this message translates to:
  /// **'수유 기록'**
  String get feedingTitle;

  /// No description provided for @feedingTabBreast.
  ///
  /// In ko, this message translates to:
  /// **'모유'**
  String get feedingTabBreast;

  /// No description provided for @feedingTabFormula.
  ///
  /// In ko, this message translates to:
  /// **'분유'**
  String get feedingTabFormula;

  /// No description provided for @feedingTabSolid.
  ///
  /// In ko, this message translates to:
  /// **'이유식'**
  String get feedingTabSolid;

  /// No description provided for @feedingSavedToast.
  ///
  /// In ko, this message translates to:
  /// **'수유 기록을 저장했어요 🍼'**
  String get feedingSavedToast;

  /// No description provided for @feedingSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {error}'**
  String feedingSaveFailed(Object error);

  /// No description provided for @feedingPhotoFailed.
  ///
  /// In ko, this message translates to:
  /// **'사진 선택 실패: {error}'**
  String feedingPhotoFailed(Object error);

  /// No description provided for @feedingBreastSide.
  ///
  /// In ko, this message translates to:
  /// **'어느 쪽?'**
  String get feedingBreastSide;

  /// No description provided for @feedingBreastLeft.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽'**
  String get feedingBreastLeft;

  /// No description provided for @feedingBreastRight.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽'**
  String get feedingBreastRight;

  /// No description provided for @feedingBreastBoth.
  ///
  /// In ko, this message translates to:
  /// **'양쪽'**
  String get feedingBreastBoth;

  /// No description provided for @feedingBreastAmountLabel.
  ///
  /// In ko, this message translates to:
  /// **'양 (ml, 선택)'**
  String get feedingBreastAmountLabel;

  /// No description provided for @feedingBreastAmountHint.
  ///
  /// In ko, this message translates to:
  /// **'직접 짠 모유면 입력'**
  String get feedingBreastAmountHint;

  /// No description provided for @feedingFormulaAmountLabel.
  ///
  /// In ko, this message translates to:
  /// **'양 (ml)'**
  String get feedingFormulaAmountLabel;

  /// No description provided for @feedingFormulaAmountHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 120'**
  String get feedingFormulaAmountHint;

  /// No description provided for @feedingFormulaBrandLabel.
  ///
  /// In ko, this message translates to:
  /// **'제품명/브랜드 (선택)'**
  String get feedingFormulaBrandLabel;

  /// No description provided for @feedingFormulaBrandHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 압타밀 1단계'**
  String get feedingFormulaBrandHint;

  /// No description provided for @feedingInUse.
  ///
  /// In ko, this message translates to:
  /// **'사용 중'**
  String get feedingInUse;

  /// No description provided for @feedingAutoSubtract.
  ///
  /// In ko, this message translates to:
  /// **'등록 시 자동 차감'**
  String get feedingAutoSubtract;

  /// No description provided for @feedingNoActiveFormula.
  ///
  /// In ko, this message translates to:
  /// **'사용 중인 분유 통이 없어요.\n등록 후 자동으로 차감됩니다.'**
  String get feedingNoActiveFormula;

  /// No description provided for @feedingSolidFoodLabel.
  ///
  /// In ko, this message translates to:
  /// **'음식 이름'**
  String get feedingSolidFoodLabel;

  /// No description provided for @feedingSolidFoodHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 쌀미음, 호박죽, 사과 갈은 것'**
  String get feedingSolidFoodHint;

  /// No description provided for @feedingSolidAmountLabel.
  ///
  /// In ko, this message translates to:
  /// **'양 (ml, 선택)'**
  String get feedingSolidAmountLabel;

  /// No description provided for @feedingSolidAmountHint.
  ///
  /// In ko, this message translates to:
  /// **'대략 분량'**
  String get feedingSolidAmountHint;

  /// No description provided for @feedingPhotoOptional.
  ///
  /// In ko, this message translates to:
  /// **'사진 (선택)'**
  String get feedingPhotoOptional;

  /// No description provided for @feedingPickFromGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 사진 선택'**
  String get feedingPickFromGallery;

  /// No description provided for @feedingMemoHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 트림 잘 함, 입맛 까다로움'**
  String get feedingMemoHint;

  /// No description provided for @sleepTitle.
  ///
  /// In ko, this message translates to:
  /// **'수면 기록'**
  String get sleepTitle;

  /// No description provided for @sleepStartedToast.
  ///
  /// In ko, this message translates to:
  /// **'수면 시작! 자장자장 💤'**
  String get sleepStartedToast;

  /// No description provided for @sleepFinishedToast.
  ///
  /// In ko, this message translates to:
  /// **'수면 기록 완료 ✅'**
  String get sleepFinishedToast;

  /// No description provided for @sleepNapNight.
  ///
  /// In ko, this message translates to:
  /// **'낮잠/밤잠'**
  String get sleepNapNight;

  /// No description provided for @sleepNap.
  ///
  /// In ko, this message translates to:
  /// **'낮잠'**
  String get sleepNap;

  /// No description provided for @sleepNight.
  ///
  /// In ko, this message translates to:
  /// **'밤잠'**
  String get sleepNight;

  /// No description provided for @sleepGoToSleep.
  ///
  /// In ko, this message translates to:
  /// **'잠들었어요'**
  String get sleepGoToSleep;

  /// No description provided for @sleepStarting.
  ///
  /// In ko, this message translates to:
  /// **'시작 중…'**
  String get sleepStarting;

  /// No description provided for @sleepWakeUp.
  ///
  /// In ko, this message translates to:
  /// **'지금 깼어요'**
  String get sleepWakeUp;

  /// No description provided for @sleepFinishing.
  ///
  /// In ko, this message translates to:
  /// **'종료 중…'**
  String get sleepFinishing;

  /// No description provided for @sleepStartLabel.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get sleepStartLabel;

  /// No description provided for @sleepElapsed.
  ///
  /// In ko, this message translates to:
  /// **'경과'**
  String get sleepElapsed;

  /// No description provided for @sleepKindLabel.
  ///
  /// In ko, this message translates to:
  /// **'구분'**
  String get sleepKindLabel;

  /// No description provided for @sleepInProgressLoadFailure.
  ///
  /// In ko, this message translates to:
  /// **'진행 중 수면 조회 실패: {error}'**
  String sleepInProgressLoadFailure(Object error);

  /// No description provided for @sleepMemoHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 안고 재움, 모빌 보다가 잠듦'**
  String get sleepMemoHint;

  /// No description provided for @sleepNapInProgress.
  ///
  /// In ko, this message translates to:
  /// **'낮잠 진행 중'**
  String get sleepNapInProgress;

  /// No description provided for @sleepNightInProgress.
  ///
  /// In ko, this message translates to:
  /// **'밤잠 진행 중'**
  String get sleepNightInProgress;

  /// No description provided for @sleepDurationMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String sleepDurationMinutes(int minutes);

  /// No description provided for @diaperTitle.
  ///
  /// In ko, this message translates to:
  /// **'기저귀 기록'**
  String get diaperTitle;

  /// No description provided for @diaperSavedToast.
  ///
  /// In ko, this message translates to:
  /// **'기저귀 기록을 저장했어요 💩'**
  String get diaperSavedToast;

  /// No description provided for @diaperType.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get diaperType;

  /// No description provided for @diaperPee.
  ///
  /// In ko, this message translates to:
  /// **'소변'**
  String get diaperPee;

  /// No description provided for @diaperPoop.
  ///
  /// In ko, this message translates to:
  /// **'대변'**
  String get diaperPoop;

  /// No description provided for @diaperBoth.
  ///
  /// In ko, this message translates to:
  /// **'둘다'**
  String get diaperBoth;

  /// No description provided for @diaperColor.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get diaperColor;

  /// No description provided for @diaperColorYellow.
  ///
  /// In ko, this message translates to:
  /// **'노랑'**
  String get diaperColorYellow;

  /// No description provided for @diaperColorBrown.
  ///
  /// In ko, this message translates to:
  /// **'갈색'**
  String get diaperColorBrown;

  /// No description provided for @diaperColorGreen.
  ///
  /// In ko, this message translates to:
  /// **'녹색'**
  String get diaperColorGreen;

  /// No description provided for @diaperColorBlack.
  ///
  /// In ko, this message translates to:
  /// **'검정'**
  String get diaperColorBlack;

  /// No description provided for @diaperColorRed.
  ///
  /// In ko, this message translates to:
  /// **'빨강'**
  String get diaperColorRed;

  /// No description provided for @diaperColorWhite.
  ///
  /// In ko, this message translates to:
  /// **'흰색'**
  String get diaperColorWhite;

  /// No description provided for @diaperColorUnknown.
  ///
  /// In ko, this message translates to:
  /// **'모름'**
  String get diaperColorUnknown;

  /// No description provided for @diaperColorAbnormalWarn.
  ///
  /// In ko, this message translates to:
  /// **'이상 색상이에요. 가능한 빨리 의사와 상담을 권해드려요.'**
  String get diaperColorAbnormalWarn;

  /// No description provided for @diaperConsistency.
  ///
  /// In ko, this message translates to:
  /// **'형태'**
  String get diaperConsistency;

  /// No description provided for @diaperLoose.
  ///
  /// In ko, this message translates to:
  /// **'묽음'**
  String get diaperLoose;

  /// No description provided for @diaperNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get diaperNormal;

  /// No description provided for @diaperFirm.
  ///
  /// In ko, this message translates to:
  /// **'단단함'**
  String get diaperFirm;

  /// No description provided for @diaperAmount.
  ///
  /// In ko, this message translates to:
  /// **'양'**
  String get diaperAmount;

  /// No description provided for @diaperSmall.
  ///
  /// In ko, this message translates to:
  /// **'조금'**
  String get diaperSmall;

  /// No description provided for @diaperLarge.
  ///
  /// In ko, this message translates to:
  /// **'많음'**
  String get diaperLarge;

  /// No description provided for @diaperMemoHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 평소보다 양 많음'**
  String get diaperMemoHint;

  /// No description provided for @diaperNoActivePack.
  ///
  /// In ko, this message translates to:
  /// **'사용 중인 기저귀 팩이 없어요.\n등록 후 자동으로 차감됩니다.'**
  String get diaperNoActivePack;

  /// No description provided for @growthTitle.
  ///
  /// In ko, this message translates to:
  /// **'성장 기록'**
  String get growthTitle;

  /// No description provided for @growthSavedToast.
  ///
  /// In ko, this message translates to:
  /// **'성장 기록을 저장했어요 📏'**
  String get growthSavedToast;

  /// No description provided for @growthDateHelp.
  ///
  /// In ko, this message translates to:
  /// **'측정 일자 선택'**
  String get growthDateHelp;

  /// No description provided for @growthAtLeastOneRequired.
  ///
  /// In ko, this message translates to:
  /// **'체중·키·머리둘레 중 하나는 입력해주세요.'**
  String get growthAtLeastOneRequired;

  /// No description provided for @growthDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'측정 일자'**
  String get growthDateLabel;

  /// No description provided for @growthWeightLabel.
  ///
  /// In ko, this message translates to:
  /// **'체중'**
  String get growthWeightLabel;

  /// No description provided for @growthWeightHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 8.45'**
  String get growthWeightHint;

  /// No description provided for @growthHeightLabel.
  ///
  /// In ko, this message translates to:
  /// **'키'**
  String get growthHeightLabel;

  /// No description provided for @growthHeightHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 75.5'**
  String get growthHeightHint;

  /// No description provided for @growthHeadLabel.
  ///
  /// In ko, this message translates to:
  /// **'머리둘레'**
  String get growthHeadLabel;

  /// No description provided for @growthHeadHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 45.0'**
  String get growthHeadHint;

  /// No description provided for @growthMemoHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 신생아실, 정기검진 등'**
  String get growthMemoHint;

  /// No description provided for @hospitalListTitle.
  ///
  /// In ko, this message translates to:
  /// **'단골 병원'**
  String get hospitalListTitle;

  /// No description provided for @hospitalRegisterTitle.
  ///
  /// In ko, this message translates to:
  /// **'병원 등록'**
  String get hospitalRegisterTitle;

  /// No description provided for @hospitalSavedToast.
  ///
  /// In ko, this message translates to:
  /// **'병원을 등록했어요 🏥'**
  String get hospitalSavedToast;

  /// No description provided for @hospitalLoadFailure.
  ///
  /// In ko, this message translates to:
  /// **'병원 목록 로딩 실패: {error}'**
  String hospitalLoadFailure(Object error);

  /// No description provided for @hospitalSpecialtyPediatrics.
  ///
  /// In ko, this message translates to:
  /// **'소아과'**
  String get hospitalSpecialtyPediatrics;

  /// No description provided for @hospitalSpecialtyDental.
  ///
  /// In ko, this message translates to:
  /// **'치과'**
  String get hospitalSpecialtyDental;

  /// No description provided for @hospitalSpecialtyER.
  ///
  /// In ko, this message translates to:
  /// **'응급실'**
  String get hospitalSpecialtyER;

  /// No description provided for @hospitalSpecialtyOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get hospitalSpecialtyOther;

  /// No description provided for @hospitalSetDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본으로 설정'**
  String get hospitalSetDefault;

  /// No description provided for @hospitalDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get hospitalDelete;

  /// No description provided for @hospitalCall.
  ///
  /// In ko, this message translates to:
  /// **'전화'**
  String get hospitalCall;

  /// No description provided for @hospitalDirections.
  ///
  /// In ko, this message translates to:
  /// **'길찾기'**
  String get hospitalDirections;

  /// No description provided for @hospitalCallFailed.
  ///
  /// In ko, this message translates to:
  /// **'전화 앱을 열 수 없어요.'**
  String get hospitalCallFailed;

  /// No description provided for @hospitalMapsFailed.
  ///
  /// In ko, this message translates to:
  /// **'지도 앱을 열 수 없어요.'**
  String get hospitalMapsFailed;

  /// No description provided for @hospitalDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'병원을 삭제할까요?'**
  String get hospitalDeleteConfirmTitle;

  /// No description provided for @hospitalDeleteConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'이 작업은 되돌릴 수 없어요.'**
  String get hospitalDeleteConfirmBody;

  /// No description provided for @hospitalNone.
  ///
  /// In ko, this message translates to:
  /// **'등록된 병원이 없어요'**
  String get hospitalNone;

  /// No description provided for @hospitalAdd.
  ///
  /// In ko, this message translates to:
  /// **'병원 추가'**
  String get hospitalAdd;

  /// No description provided for @hospitalNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'병원 이름'**
  String get hospitalNameLabel;

  /// No description provided for @hospitalNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 우리동네 소아과'**
  String get hospitalNameHint;

  /// No description provided for @hospitalNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'병원 이름은 필수예요.'**
  String get hospitalNameRequired;

  /// No description provided for @hospitalSpecialty.
  ///
  /// In ko, this message translates to:
  /// **'진료과'**
  String get hospitalSpecialty;

  /// No description provided for @hospitalPhone.
  ///
  /// In ko, this message translates to:
  /// **'전화번호'**
  String get hospitalPhone;

  /// No description provided for @hospitalPhoneHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 02-123-4567'**
  String get hospitalPhoneHint;

  /// No description provided for @hospitalAddress.
  ///
  /// In ko, this message translates to:
  /// **'주소'**
  String get hospitalAddress;

  /// No description provided for @hospitalAddressHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 서울 강남구 테헤란로 123'**
  String get hospitalAddressHint;

  /// No description provided for @hospitalMemoHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 야간 진료 가능, 친절한 의사'**
  String get hospitalMemoHint;

  /// No description provided for @hospitalDefaultTitle.
  ///
  /// In ko, this message translates to:
  /// **'기본 병원으로 설정'**
  String get hospitalDefaultTitle;

  /// No description provided for @hospitalDefaultSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'알림/원클릭 전화 등에서 우선 표시'**
  String get hospitalDefaultSubtitle;

  /// No description provided for @vaccineListTitle.
  ///
  /// In ko, this message translates to:
  /// **'예방접종 일정'**
  String get vaccineListTitle;

  /// No description provided for @vaccineSectionOverdue.
  ///
  /// In ko, this message translates to:
  /// **'지났는데 미접종'**
  String get vaccineSectionOverdue;

  /// No description provided for @vaccineSectionUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 / 미접종'**
  String get vaccineSectionUpcoming;

  /// No description provided for @vaccineSectionCompleted.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get vaccineSectionCompleted;

  /// No description provided for @vaccineRecordTitle.
  ///
  /// In ko, this message translates to:
  /// **'접종 기록'**
  String get vaccineRecordTitle;

  /// No description provided for @vaccineDoseDate.
  ///
  /// In ko, this message translates to:
  /// **'접종일'**
  String get vaccineDoseDate;

  /// No description provided for @vaccineDateHelp.
  ///
  /// In ko, this message translates to:
  /// **'접종일 선택'**
  String get vaccineDateHelp;

  /// No description provided for @vaccineRecommendedAge.
  ///
  /// In ko, this message translates to:
  /// **'권장 시기: 생후 {days}일'**
  String vaccineRecommendedAge(int days);

  /// No description provided for @vaccineHospitalLoadFailure.
  ///
  /// In ko, this message translates to:
  /// **'병원 로딩 실패: {error}'**
  String vaccineHospitalLoadFailure(Object error);

  /// No description provided for @vaccineHospitalNone.
  ///
  /// In ko, this message translates to:
  /// **'등록된 병원이 없어요. 나중에 추가하기'**
  String get vaccineHospitalNone;

  /// No description provided for @vaccineHospitalLabel.
  ///
  /// In ko, this message translates to:
  /// **'병원 (선택)'**
  String get vaccineHospitalLabel;

  /// No description provided for @vaccineMemoHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 부작용 없음'**
  String get vaccineMemoHint;

  /// No description provided for @vaccineRecordButton.
  ///
  /// In ko, this message translates to:
  /// **'접종 완료 기록'**
  String get vaccineRecordButton;

  /// No description provided for @vaccineScheduleLoadFailure.
  ///
  /// In ko, this message translates to:
  /// **'일정 로딩 실패: {error}'**
  String vaccineScheduleLoadFailure(Object error);

  /// No description provided for @vaccineRecordsLoadFailure.
  ///
  /// In ko, this message translates to:
  /// **'접종 기록 로딩 실패: {error}'**
  String vaccineRecordsLoadFailure(Object error);

  /// No description provided for @upcomingVaccineTitle.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 접종'**
  String get upcomingVaccineTitle;

  /// No description provided for @upcomingVaccineToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 권장'**
  String get upcomingVaccineToday;

  /// No description provided for @upcomingVaccineDays.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 후 권장'**
  String upcomingVaccineDays(int n);

  /// No description provided for @upcomingVaccineOverdue.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 지남'**
  String upcomingVaccineOverdue(int n);

  /// No description provided for @formulaInventoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'분유 재고'**
  String get formulaInventoryTitle;

  /// No description provided for @formulaRegisterTitle.
  ///
  /// In ko, this message translates to:
  /// **'분유 등록'**
  String get formulaRegisterTitle;

  /// No description provided for @formulaSavedToast.
  ///
  /// In ko, this message translates to:
  /// **'분유를 등록했어요 🍼'**
  String get formulaSavedToast;

  /// No description provided for @formulaProductName.
  ///
  /// In ko, this message translates to:
  /// **'제품명'**
  String get formulaProductName;

  /// No description provided for @formulaProductHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 압타밀 1단계'**
  String get formulaProductHint;

  /// No description provided for @formulaProductRequired.
  ///
  /// In ko, this message translates to:
  /// **'제품명은 필수예요.'**
  String get formulaProductRequired;

  /// No description provided for @formulaBrandLabel.
  ///
  /// In ko, this message translates to:
  /// **'브랜드 (선택)'**
  String get formulaBrandLabel;

  /// No description provided for @formulaBrandHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 압타밀, 매일유업'**
  String get formulaBrandHint;

  /// No description provided for @formulaCapacity.
  ///
  /// In ko, this message translates to:
  /// **'용량'**
  String get formulaCapacity;

  /// No description provided for @formulaCapacityHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 800'**
  String get formulaCapacityHint;

  /// No description provided for @formulaCapacityRequired.
  ///
  /// In ko, this message translates to:
  /// **'용량은 필수예요.'**
  String get formulaCapacityRequired;

  /// No description provided for @formulaCapacityTooLarge.
  ///
  /// In ko, this message translates to:
  /// **'용량이 너무 커요. 단위(g) 다시 확인해줘.'**
  String get formulaCapacityTooLarge;

  /// No description provided for @formulaPurchaseDateOptional.
  ///
  /// In ko, this message translates to:
  /// **'구매일 (선택)'**
  String get formulaPurchaseDateOptional;

  /// No description provided for @formulaPurchaseDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'구매일'**
  String get formulaPurchaseDateLabel;

  /// No description provided for @formulaOpenedDateOptional.
  ///
  /// In ko, this message translates to:
  /// **'개봉일 (선택, 비워두면 보관 중)'**
  String get formulaOpenedDateOptional;

  /// No description provided for @formulaNotOpenedYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 안 열었음'**
  String get formulaNotOpenedYet;

  /// No description provided for @formulaOpenedDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'개봉일'**
  String get formulaOpenedDateLabel;

  /// No description provided for @formulaPriceLabel.
  ///
  /// In ko, this message translates to:
  /// **'가격 (선택, 원)'**
  String get formulaPriceLabel;

  /// No description provided for @formulaPriceHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 35000'**
  String get formulaPriceHint;

  /// No description provided for @formulaPriceUnit.
  ///
  /// In ko, this message translates to:
  /// **'원'**
  String get formulaPriceUnit;

  /// No description provided for @formulaShopLabel.
  ///
  /// In ko, this message translates to:
  /// **'구매처 (선택)'**
  String get formulaShopLabel;

  /// No description provided for @formulaShopHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 쿠팡, 약국'**
  String get formulaShopHint;

  /// No description provided for @formulaSectionInUse.
  ///
  /// In ko, this message translates to:
  /// **'사용 중'**
  String get formulaSectionInUse;

  /// No description provided for @formulaSectionStored.
  ///
  /// In ko, this message translates to:
  /// **'보관 중'**
  String get formulaSectionStored;

  /// No description provided for @formulaSectionDepleted.
  ///
  /// In ko, this message translates to:
  /// **'소진'**
  String get formulaSectionDepleted;

  /// No description provided for @formulaActionOpen.
  ///
  /// In ko, this message translates to:
  /// **'개봉'**
  String get formulaActionOpen;

  /// No description provided for @formulaActionDeplete.
  ///
  /// In ko, this message translates to:
  /// **'소진'**
  String get formulaActionDeplete;

  /// No description provided for @formulaRemainCalcFailed.
  ///
  /// In ko, this message translates to:
  /// **'잔량 계산 실패: {error}'**
  String formulaRemainCalcFailed(Object error);

  /// No description provided for @formulaExpectedDays.
  ///
  /// In ko, this message translates to:
  /// **'약 {days}일 후 소진'**
  String formulaExpectedDays(String days);

  /// No description provided for @formulaInventoryLoadFailure.
  ///
  /// In ko, this message translates to:
  /// **'재고 목록 로딩 실패: {error}'**
  String formulaInventoryLoadFailure(Object error);

  /// No description provided for @formulaNone.
  ///
  /// In ko, this message translates to:
  /// **'등록된 분유가 없어요'**
  String get formulaNone;

  /// No description provided for @formulaAdd.
  ///
  /// In ko, this message translates to:
  /// **'분유 추가'**
  String get formulaAdd;

  /// No description provided for @formulaStatusTitle.
  ///
  /// In ko, this message translates to:
  /// **'분유 잔량'**
  String get formulaStatusTitle;

  /// No description provided for @formulaStatusDaysSupply.
  ///
  /// In ko, this message translates to:
  /// **'약 {days}일 분량 남음'**
  String formulaStatusDaysSupply(String days);

  /// No description provided for @formulaStatusDaysUntilEmpty.
  ///
  /// In ko, this message translates to:
  /// **'약 {days}일 후 소진!'**
  String formulaStatusDaysUntilEmpty(String days);

  /// No description provided for @diaperInventoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'기저귀 재고'**
  String get diaperInventoryTitle;

  /// No description provided for @diaperInventoryRegister.
  ///
  /// In ko, this message translates to:
  /// **'기저귀 등록'**
  String get diaperInventoryRegister;

  /// No description provided for @diaperInventorySavedToast.
  ///
  /// In ko, this message translates to:
  /// **'기저귀를 등록했어요 🧷'**
  String get diaperInventorySavedToast;

  /// No description provided for @diaperInventorySize.
  ///
  /// In ko, this message translates to:
  /// **'사이즈'**
  String get diaperInventorySize;

  /// No description provided for @diaperInventoryCount.
  ///
  /// In ko, this message translates to:
  /// **'매수'**
  String get diaperInventoryCount;

  /// No description provided for @diaperInventoryCountHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 60'**
  String get diaperInventoryCountHint;

  /// No description provided for @diaperInventoryCountUnit.
  ///
  /// In ko, this message translates to:
  /// **'매'**
  String get diaperInventoryCountUnit;

  /// No description provided for @diaperInventoryCountRequired.
  ///
  /// In ko, this message translates to:
  /// **'매수는 필수예요.'**
  String get diaperInventoryCountRequired;

  /// No description provided for @diaperInventoryCountTooMany.
  ///
  /// In ko, this message translates to:
  /// **'매수가 너무 많아요.'**
  String get diaperInventoryCountTooMany;

  /// No description provided for @diaperInventoryBrandHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 하기스, 마미포코'**
  String get diaperInventoryBrandHint;

  /// No description provided for @diaperInventoryUseType.
  ///
  /// In ko, this message translates to:
  /// **'사용 종류 (선택)'**
  String get diaperInventoryUseType;

  /// No description provided for @diaperInventoryDay.
  ///
  /// In ko, this message translates to:
  /// **'낮용'**
  String get diaperInventoryDay;

  /// No description provided for @diaperInventoryNight.
  ///
  /// In ko, this message translates to:
  /// **'밤용'**
  String get diaperInventoryNight;

  /// No description provided for @diaperInventoryAll.
  ///
  /// In ko, this message translates to:
  /// **'공용'**
  String get diaperInventoryAll;

  /// No description provided for @diaperInventoryNone.
  ///
  /// In ko, this message translates to:
  /// **'등록된 기저귀가 없어요'**
  String get diaperInventoryNone;

  /// No description provided for @diaperInventoryAdd.
  ///
  /// In ko, this message translates to:
  /// **'기저귀 추가'**
  String get diaperInventoryAdd;

  /// No description provided for @diaperInventoryLoadFailure.
  ///
  /// In ko, this message translates to:
  /// **'재고 로딩 실패: {error}'**
  String diaperInventoryLoadFailure(Object error);

  /// No description provided for @diaperSizeUpTitle.
  ///
  /// In ko, this message translates to:
  /// **'기저귀 사이즈업 예측'**
  String get diaperSizeUpTitle;

  /// No description provided for @diaperSizeUpDays.
  ///
  /// In ko, this message translates to:
  /// **'약 {days}일 후 {next} 사이즈 권장'**
  String diaperSizeUpDays(int days, String next);

  /// No description provided for @diaperSizeUpUrgent.
  ///
  /// In ko, this message translates to:
  /// **'{current} → {next}로 곧 변경 권장!'**
  String diaperSizeUpUrgent(String current, String next);

  /// No description provided for @diaperSizeUpOverdue.
  ///
  /// In ko, this message translates to:
  /// **'{next} 사이즈 권장 시점이 지났어요'**
  String diaperSizeUpOverdue(String next);

  /// No description provided for @diaperSizeUpCurrentWeight.
  ///
  /// In ko, this message translates to:
  /// **'현재 {kg}kg · {current} 적정 {max}kg까지'**
  String diaperSizeUpCurrentWeight(String kg, String current, String max);

  /// No description provided for @summaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 요약'**
  String get summaryTitle;

  /// No description provided for @summaryFeeding.
  ///
  /// In ko, this message translates to:
  /// **'수유'**
  String get summaryFeeding;

  /// No description provided for @summarySleep.
  ///
  /// In ko, this message translates to:
  /// **'수면'**
  String get summarySleep;

  /// No description provided for @summaryDiaper.
  ///
  /// In ko, this message translates to:
  /// **'기저귀'**
  String get summaryDiaper;

  /// No description provided for @summaryGrowth.
  ///
  /// In ko, this message translates to:
  /// **'성장'**
  String get summaryGrowth;

  /// No description provided for @lastActivityFeeding.
  ///
  /// In ko, this message translates to:
  /// **'수유'**
  String get lastActivityFeeding;

  /// No description provided for @lastActivitySleep.
  ///
  /// In ko, this message translates to:
  /// **'수면'**
  String get lastActivitySleep;

  /// No description provided for @lastActivityDiaper.
  ///
  /// In ko, this message translates to:
  /// **'기저귀'**
  String get lastActivityDiaper;

  /// No description provided for @lastActivityGrowth.
  ///
  /// In ko, this message translates to:
  /// **'성장'**
  String get lastActivityGrowth;

  /// No description provided for @familyTitle.
  ///
  /// In ko, this message translates to:
  /// **'가족 공유'**
  String get familyTitle;

  /// No description provided for @familyEntryHome.
  ///
  /// In ko, this message translates to:
  /// **'가족 공유'**
  String get familyEntryHome;

  /// No description provided for @familyChildPicker.
  ///
  /// In ko, this message translates to:
  /// **'자녀 선택'**
  String get familyChildPicker;

  /// No description provided for @familyCaregivers.
  ///
  /// In ko, this message translates to:
  /// **'함께 돌보는 사람'**
  String get familyCaregivers;

  /// No description provided for @familyMe.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get familyMe;

  /// No description provided for @familyRoleParent.
  ///
  /// In ko, this message translates to:
  /// **'부모'**
  String get familyRoleParent;

  /// No description provided for @familyRoleGrandparent.
  ///
  /// In ko, this message translates to:
  /// **'조부모'**
  String get familyRoleGrandparent;

  /// No description provided for @familyRoleNanny.
  ///
  /// In ko, this message translates to:
  /// **'시터'**
  String get familyRoleNanny;

  /// No description provided for @familyRoleOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get familyRoleOther;

  /// No description provided for @familyAcceptedAt.
  ///
  /// In ko, this message translates to:
  /// **'{date} 합류'**
  String familyAcceptedAt(String date);

  /// No description provided for @familyRemoveCaregiver.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get familyRemoveCaregiver;

  /// No description provided for @familyRemoveCaregiverConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 사람을 가족에서 제외할까요?'**
  String get familyRemoveCaregiverConfirm;

  /// No description provided for @familyLeave.
  ///
  /// In ko, this message translates to:
  /// **'가족에서 나가기'**
  String get familyLeave;

  /// No description provided for @familyInvites.
  ///
  /// In ko, this message translates to:
  /// **'활성 초대 코드'**
  String get familyInvites;

  /// No description provided for @familyInviteExpiresAt.
  ///
  /// In ko, this message translates to:
  /// **'만료: {date}'**
  String familyInviteExpiresAt(String date);

  /// No description provided for @familyCreateInvite.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드 만들기'**
  String get familyCreateInvite;

  /// No description provided for @familyShareCode.
  ///
  /// In ko, this message translates to:
  /// **'코드 공유'**
  String get familyShareCode;

  /// No description provided for @familyRevokeInvite.
  ///
  /// In ko, this message translates to:
  /// **'코드 회수'**
  String get familyRevokeInvite;

  /// No description provided for @familyJoinTitle.
  ///
  /// In ko, this message translates to:
  /// **'가족 참여'**
  String get familyJoinTitle;

  /// No description provided for @familyJoinHelp.
  ///
  /// In ko, this message translates to:
  /// **'받은 6자리 초대 코드를 입력하세요.'**
  String get familyJoinHelp;

  /// No description provided for @familyCodeLabel.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드'**
  String get familyCodeLabel;

  /// No description provided for @familyCodeHint.
  ///
  /// In ko, this message translates to:
  /// **'예: A3B7K9'**
  String get familyCodeHint;

  /// No description provided for @familyJoinButton.
  ///
  /// In ko, this message translates to:
  /// **'가족으로 참여'**
  String get familyJoinButton;

  /// No description provided for @familyJoined.
  ///
  /// In ko, this message translates to:
  /// **'가족에 합류했어요 🎉'**
  String get familyJoined;

  /// No description provided for @familyInviteCreated.
  ///
  /// In ko, this message translates to:
  /// **'코드를 발급했어요. 24시간 동안 유효해요.'**
  String get familyInviteCreated;

  /// No description provided for @familyInviteInvalid.
  ///
  /// In ko, this message translates to:
  /// **'유효하지 않은 코드예요.'**
  String get familyInviteInvalid;

  /// No description provided for @familyInviteExpired.
  ///
  /// In ko, this message translates to:
  /// **'만료된 코드예요. 새로 발급받으세요.'**
  String get familyInviteExpired;

  /// No description provided for @familyEntryJoin.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드로 참여'**
  String get familyEntryJoin;

  /// No description provided for @statsTitle.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get statsTitle;

  /// No description provided for @statsEntryHome.
  ///
  /// In ko, this message translates to:
  /// **'통계 보기'**
  String get statsEntryHome;

  /// No description provided for @statsFeedingDaily.
  ///
  /// In ko, this message translates to:
  /// **'일별 수유 횟수'**
  String get statsFeedingDaily;

  /// No description provided for @statsSleepDaily.
  ///
  /// In ko, this message translates to:
  /// **'일별 수면 시간'**
  String get statsSleepDaily;

  /// No description provided for @statsDiaperDaily.
  ///
  /// In ko, this message translates to:
  /// **'일별 기저귀 횟수'**
  String get statsDiaperDaily;

  /// No description provided for @statsGrowthCurve.
  ///
  /// In ko, this message translates to:
  /// **'성장 곡선 (체중)'**
  String get statsGrowthCurve;

  /// No description provided for @statsLast7Days.
  ///
  /// In ko, this message translates to:
  /// **'지난 7일'**
  String get statsLast7Days;

  /// No description provided for @statsLast7DaysHours.
  ///
  /// In ko, this message translates to:
  /// **'지난 7일 (시간)'**
  String get statsLast7DaysHours;

  /// No description provided for @statsAllRecords.
  ///
  /// In ko, this message translates to:
  /// **'전체 기록'**
  String get statsAllRecords;

  /// No description provided for @statsNotEnoughData.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 부족해요. 성장 기록을 2건 이상 등록해주세요.'**
  String get statsNotEnoughData;

  /// No description provided for @statsLegendChild.
  ///
  /// In ko, this message translates to:
  /// **'내 자녀'**
  String get statsLegendChild;

  /// No description provided for @statsLegendP50.
  ///
  /// In ko, this message translates to:
  /// **'WHO 평균 (P50)'**
  String get statsLegendP50;

  /// No description provided for @statsLegendP3P97.
  ///
  /// In ko, this message translates to:
  /// **'WHO 정상 범위 (P3~P97)'**
  String get statsLegendP3P97;

  /// No description provided for @notifFormulaLowTitle.
  ///
  /// In ko, this message translates to:
  /// **'분유 곧 소진'**
  String get notifFormulaLowTitle;

  /// No description provided for @notifFormulaLowBody.
  ///
  /// In ko, this message translates to:
  /// **'{product} 1일분 남았어요. 새 통 준비해주세요.'**
  String notifFormulaLowBody(String product);

  /// No description provided for @notifVaccineUpcomingTitle.
  ///
  /// In ko, this message translates to:
  /// **'예방접종 임박'**
  String get notifVaccineUpcomingTitle;

  /// No description provided for @notifVaccineUpcomingBody.
  ///
  /// In ko, this message translates to:
  /// **'내일 {vaccine} 권장일이에요.'**
  String notifVaccineUpcomingBody(String vaccine);

  /// No description provided for @childEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'자녀 정보 편집'**
  String get childEditTitle;

  /// No description provided for @childEditSaved.
  ///
  /// In ko, this message translates to:
  /// **'자녀 정보를 저장했어요'**
  String get childEditSaved;

  /// No description provided for @childDeleteAction.
  ///
  /// In ko, this message translates to:
  /// **'자녀 삭제'**
  String get childDeleteAction;

  /// No description provided for @childDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'자녀를 삭제할까요?'**
  String get childDeleteTitle;

  /// No description provided for @childDeleteWarning.
  ///
  /// In ko, this message translates to:
  /// **'{name} 자녀와 모든 기록(수유·수면·기저귀·성장·재고·접종)이 영구 삭제돼요. 되돌릴 수 없어요.'**
  String childDeleteWarning(String name);

  /// No description provided for @childDeleted.
  ///
  /// In ko, this message translates to:
  /// **'자녀를 삭제했어요'**
  String get childDeleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
