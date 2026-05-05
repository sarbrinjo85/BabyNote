// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '베이비노트';

  @override
  String get homeWelcome => '환영합니다';

  @override
  String get commonSave => '저장';

  @override
  String get commonRegister => '등록';

  @override
  String get commonRegistering => '등록 중…';

  @override
  String get commonSaving => '저장 중…';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonAdd => '추가';

  @override
  String get commonOr => '또는';

  @override
  String get commonNoSelection => '선택 안 함';

  @override
  String get commonOptional => '(선택)';

  @override
  String get commonTapToSelect => '탭해서 선택';

  @override
  String get commonNumberOnly => '숫자만 입력해주세요.';

  @override
  String get commonPositiveOnly => '양수만 입력해주세요.';

  @override
  String get commonNoRecordYet => '아직 기록 없음';

  @override
  String get commonNoEntryYet => '아직 없음';

  @override
  String get commonDataInsufficient => '데이터 부족';

  @override
  String get commonRegisterChildFirst => '먼저 자녀를 등록해주세요.';

  @override
  String get commonGoRegisterChild => '자녀 등록하러 가기';

  @override
  String get commonNotLoggedIn => '로그인되지 않았어요.';

  @override
  String get commonMemoOptional => '메모 (선택)';

  @override
  String errorFailed(Object error) {
    return '실패: $error';
  }

  @override
  String errorChildrenLoadFailed(Object error) {
    return '자녀 목록 로딩 실패: $error';
  }

  @override
  String errorChildLoadFailed(Object error) {
    return '자녀 로딩 실패: $error';
  }

  @override
  String errorAuthStream(Object error) {
    return '인증 스트림 에러: $error';
  }

  @override
  String get timeJustNow => '방금 전';

  @override
  String timeMinutesAgo(int n) {
    return '$n분 전';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n시간 전';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n일 전';
  }

  @override
  String timeYesterdayAt(String hhmm) {
    return '어제 $hhmm';
  }

  @override
  String get authStartTitle => '베이비노트 시작';

  @override
  String get authLogin => '로그인';

  @override
  String get authSignup => '회원가입';

  @override
  String get authEmail => '이메일';

  @override
  String get authPassword => '비밀번호';

  @override
  String get homeLogout => '로그아웃';

  @override
  String get homeMyChildren => '내 자녀';

  @override
  String get homeAddChild => '자녀 추가';

  @override
  String get homeFirstChild => '첫 자녀 등록';

  @override
  String get homeNoChildYet => '아직 등록된 자녀가 없어요';

  @override
  String homeChildSubtitle(String gender, int days) {
    return '$gender · 생후 $days일';
  }

  @override
  String get homeLastActivity => '마지막 활동';

  @override
  String get homeTodayRecord => '오늘의 기록';

  @override
  String get homeInventory => '재고 관리';

  @override
  String get homeFormulaInventoryEntry => '분유 재고 관리';

  @override
  String get homeDiaperInventoryEntry => '기저귀 재고 관리';

  @override
  String get homeHospital => '병원';

  @override
  String get homeHospitalEntry => '단골 병원 (전화 · 길찾기)';

  @override
  String get homeVaccineEntry => '예방접종 일정';

  @override
  String get homeNoLogin => '비로그인';

  @override
  String get homeAnonymous => '익명';

  @override
  String get homeUser => '사용자';

  @override
  String get childRegisterTitle => '자녀 등록';

  @override
  String get childName => '이름';

  @override
  String get childNameHint => '예: 김아기';

  @override
  String get childNameRequired => '이름은 필수예요.';

  @override
  String get childGender => '성별';

  @override
  String get childGenderFemale => '여아';

  @override
  String get childGenderMale => '남아';

  @override
  String get childGenderOther => '기타';

  @override
  String get childGenderUnset => '미지정';

  @override
  String get childBirthDate => '생년월일';

  @override
  String get childBirthDateHelp => '자녀 생년월일 선택';

  @override
  String get childBirthDateRequired => '생년월일을 선택해주세요.';

  @override
  String get childBirthWeightLabel => '출생 시 무게 (kg, 선택)';

  @override
  String get childBirthWeightHint => '예: 3.45';

  @override
  String get childBirthHeightLabel => '출생 시 키 (cm, 선택)';

  @override
  String get childBirthHeightHint => '예: 51.5';

  @override
  String childRegisterFailed(Object error) {
    return '등록 실패: $error';
  }

  @override
  String get feedingTitle => '수유 기록';

  @override
  String get feedingTabBreast => '모유';

  @override
  String get feedingTabFormula => '분유';

  @override
  String get feedingTabSolid => '이유식';

  @override
  String get feedingSavedToast => '수유 기록을 저장했어요 🍼';

  @override
  String feedingSaveFailed(Object error) {
    return '저장 실패: $error';
  }

  @override
  String feedingPhotoFailed(Object error) {
    return '사진 선택 실패: $error';
  }

  @override
  String get feedingBreastSide => '어느 쪽?';

  @override
  String get feedingBreastLeft => '왼쪽';

  @override
  String get feedingBreastRight => '오른쪽';

  @override
  String get feedingBreastBoth => '양쪽';

  @override
  String get feedingBreastAmountLabel => '양 (ml, 선택)';

  @override
  String get feedingBreastAmountHint => '직접 짠 모유면 입력';

  @override
  String get feedingFormulaAmountLabel => '양 (ml)';

  @override
  String get feedingFormulaAmountHint => '예: 120';

  @override
  String get feedingFormulaBrandLabel => '제품명/브랜드 (선택)';

  @override
  String get feedingFormulaBrandHint => '예: 압타밀 1단계';

  @override
  String get feedingInUse => '사용 중';

  @override
  String get feedingAutoSubtract => '등록 시 자동 차감';

  @override
  String get feedingNoActiveFormula => '사용 중인 분유 통이 없어요.\n등록 후 자동으로 차감됩니다.';

  @override
  String get feedingSolidFoodLabel => '음식 이름';

  @override
  String get feedingSolidFoodHint => '예: 쌀미음, 호박죽, 사과 갈은 것';

  @override
  String get feedingSolidAmountLabel => '양 (ml, 선택)';

  @override
  String get feedingSolidAmountHint => '대략 분량';

  @override
  String get feedingPhotoOptional => '사진 (선택)';

  @override
  String get feedingPickFromGallery => '갤러리에서 사진 선택';

  @override
  String get feedingMemoHint => '예: 트림 잘 함, 입맛 까다로움';

  @override
  String get sleepTitle => '수면 기록';

  @override
  String get sleepStartedToast => '수면 시작! 자장자장 💤';

  @override
  String get sleepFinishedToast => '수면 기록 완료 ✅';

  @override
  String get sleepNapNight => '낮잠/밤잠';

  @override
  String get sleepNap => '낮잠';

  @override
  String get sleepNight => '밤잠';

  @override
  String get sleepGoToSleep => '잠들었어요';

  @override
  String get sleepStarting => '시작 중…';

  @override
  String get sleepWakeUp => '지금 깼어요';

  @override
  String get sleepFinishing => '종료 중…';

  @override
  String get sleepStartLabel => '시작';

  @override
  String get sleepElapsed => '경과';

  @override
  String get sleepKindLabel => '구분';

  @override
  String sleepInProgressLoadFailure(Object error) {
    return '진행 중 수면 조회 실패: $error';
  }

  @override
  String get sleepMemoHint => '예: 안고 재움, 모빌 보다가 잠듦';

  @override
  String get sleepNapInProgress => '낮잠 진행 중';

  @override
  String get sleepNightInProgress => '밤잠 진행 중';

  @override
  String sleepDurationMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String get diaperTitle => '기저귀 기록';

  @override
  String get diaperSavedToast => '기저귀 기록을 저장했어요 💩';

  @override
  String get diaperType => '종류';

  @override
  String get diaperPee => '소변';

  @override
  String get diaperPoop => '대변';

  @override
  String get diaperBoth => '둘다';

  @override
  String get diaperColor => '색상';

  @override
  String get diaperColorYellow => '노랑';

  @override
  String get diaperColorBrown => '갈색';

  @override
  String get diaperColorGreen => '녹색';

  @override
  String get diaperColorBlack => '검정';

  @override
  String get diaperColorRed => '빨강';

  @override
  String get diaperColorWhite => '흰색';

  @override
  String get diaperColorUnknown => '모름';

  @override
  String get diaperColorAbnormalWarn => '이상 색상이에요. 가능한 빨리 의사와 상담을 권해드려요.';

  @override
  String get diaperConsistency => '형태';

  @override
  String get diaperLoose => '묽음';

  @override
  String get diaperNormal => '보통';

  @override
  String get diaperFirm => '단단함';

  @override
  String get diaperAmount => '양';

  @override
  String get diaperSmall => '조금';

  @override
  String get diaperLarge => '많음';

  @override
  String get diaperMemoHint => '예: 평소보다 양 많음';

  @override
  String get diaperNoActivePack => '사용 중인 기저귀 팩이 없어요.\n등록 후 자동으로 차감됩니다.';

  @override
  String get growthTitle => '성장 기록';

  @override
  String get growthSavedToast => '성장 기록을 저장했어요 📏';

  @override
  String get growthDateHelp => '측정 일자 선택';

  @override
  String get growthAtLeastOneRequired => '체중·키·머리둘레 중 하나는 입력해주세요.';

  @override
  String get growthDateLabel => '측정 일자';

  @override
  String get growthWeightLabel => '체중';

  @override
  String get growthWeightHint => '예: 8.45';

  @override
  String get growthHeightLabel => '키';

  @override
  String get growthHeightHint => '예: 75.5';

  @override
  String get growthHeadLabel => '머리둘레';

  @override
  String get growthHeadHint => '예: 45.0';

  @override
  String get growthMemoHint => '예: 신생아실, 정기검진 등';

  @override
  String get hospitalListTitle => '단골 병원';

  @override
  String get hospitalRegisterTitle => '병원 등록';

  @override
  String get hospitalSavedToast => '병원을 등록했어요 🏥';

  @override
  String hospitalLoadFailure(Object error) {
    return '병원 목록 로딩 실패: $error';
  }

  @override
  String get hospitalSpecialtyPediatrics => '소아과';

  @override
  String get hospitalSpecialtyDental => '치과';

  @override
  String get hospitalSpecialtyER => '응급실';

  @override
  String get hospitalSpecialtyOther => '기타';

  @override
  String get hospitalSetDefault => '기본으로 설정';

  @override
  String get hospitalDelete => '삭제';

  @override
  String get hospitalCall => '전화';

  @override
  String get hospitalDirections => '길찾기';

  @override
  String get hospitalCallFailed => '전화 앱을 열 수 없어요.';

  @override
  String get hospitalMapsFailed => '지도 앱을 열 수 없어요.';

  @override
  String get hospitalDeleteConfirmTitle => '병원을 삭제할까요?';

  @override
  String get hospitalDeleteConfirmBody => '이 작업은 되돌릴 수 없어요.';

  @override
  String get hospitalNone => '등록된 병원이 없어요';

  @override
  String get hospitalAdd => '병원 추가';

  @override
  String get hospitalNameLabel => '병원 이름';

  @override
  String get hospitalNameHint => '예: 우리동네 소아과';

  @override
  String get hospitalNameRequired => '병원 이름은 필수예요.';

  @override
  String get hospitalSpecialty => '진료과';

  @override
  String get hospitalPhone => '전화번호';

  @override
  String get hospitalPhoneHint => '예: 02-123-4567';

  @override
  String get hospitalAddress => '주소';

  @override
  String get hospitalAddressHint => '예: 서울 강남구 테헤란로 123';

  @override
  String get hospitalMemoHint => '예: 야간 진료 가능, 친절한 의사';

  @override
  String get hospitalDefaultTitle => '기본 병원으로 설정';

  @override
  String get hospitalDefaultSubtitle => '알림/원클릭 전화 등에서 우선 표시';

  @override
  String get vaccineListTitle => '예방접종 일정';

  @override
  String get vaccineSectionOverdue => '지났는데 미접종';

  @override
  String get vaccineSectionUpcoming => '다가오는 / 미접종';

  @override
  String get vaccineSectionCompleted => '완료';

  @override
  String get vaccineRecordTitle => '접종 기록';

  @override
  String get vaccineDoseDate => '접종일';

  @override
  String get vaccineDateHelp => '접종일 선택';

  @override
  String vaccineRecommendedAge(int days) {
    return '권장 시기: 생후 $days일';
  }

  @override
  String vaccineHospitalLoadFailure(Object error) {
    return '병원 로딩 실패: $error';
  }

  @override
  String get vaccineHospitalNone => '등록된 병원이 없어요. 나중에 추가하기';

  @override
  String get vaccineHospitalLabel => '병원 (선택)';

  @override
  String get vaccineMemoHint => '예: 부작용 없음';

  @override
  String get vaccineRecordButton => '접종 완료 기록';

  @override
  String vaccineScheduleLoadFailure(Object error) {
    return '일정 로딩 실패: $error';
  }

  @override
  String vaccineRecordsLoadFailure(Object error) {
    return '접종 기록 로딩 실패: $error';
  }

  @override
  String get upcomingVaccineTitle => '다가오는 접종';

  @override
  String get upcomingVaccineToday => '오늘 권장';

  @override
  String upcomingVaccineDays(int n) {
    return '$n일 후 권장';
  }

  @override
  String upcomingVaccineOverdue(int n) {
    return '$n일 지남';
  }

  @override
  String get formulaInventoryTitle => '분유 재고';

  @override
  String get formulaRegisterTitle => '분유 등록';

  @override
  String get formulaSavedToast => '분유를 등록했어요 🍼';

  @override
  String get formulaProductName => '제품명';

  @override
  String get formulaProductHint => '예: 압타밀 1단계';

  @override
  String get formulaProductRequired => '제품명은 필수예요.';

  @override
  String get formulaBrandLabel => '브랜드 (선택)';

  @override
  String get formulaBrandHint => '예: 압타밀, 매일유업';

  @override
  String get formulaCapacity => '용량';

  @override
  String get formulaCapacityHint => '예: 800';

  @override
  String get formulaCapacityRequired => '용량은 필수예요.';

  @override
  String get formulaCapacityTooLarge => '용량이 너무 커요. 단위(g) 다시 확인해줘.';

  @override
  String get formulaPurchaseDateOptional => '구매일 (선택)';

  @override
  String get formulaPurchaseDateLabel => '구매일';

  @override
  String get formulaOpenedDateOptional => '개봉일 (선택, 비워두면 보관 중)';

  @override
  String get formulaNotOpenedYet => '아직 안 열었음';

  @override
  String get formulaOpenedDateLabel => '개봉일';

  @override
  String get formulaPriceLabel => '가격 (선택, 원)';

  @override
  String get formulaPriceHint => '예: 35000';

  @override
  String get formulaPriceUnit => '원';

  @override
  String get formulaShopLabel => '구매처 (선택)';

  @override
  String get formulaShopHint => '예: 쿠팡, 약국';

  @override
  String get formulaSectionInUse => '사용 중';

  @override
  String get formulaSectionStored => '보관 중';

  @override
  String get formulaSectionDepleted => '소진';

  @override
  String get formulaActionOpen => '개봉';

  @override
  String get formulaActionDeplete => '소진';

  @override
  String formulaRemainCalcFailed(Object error) {
    return '잔량 계산 실패: $error';
  }

  @override
  String formulaExpectedDays(String days) {
    return '약 $days일 후 소진';
  }

  @override
  String formulaInventoryLoadFailure(Object error) {
    return '재고 목록 로딩 실패: $error';
  }

  @override
  String get formulaNone => '등록된 분유가 없어요';

  @override
  String get formulaAdd => '분유 추가';

  @override
  String get formulaStatusTitle => '분유 잔량';

  @override
  String formulaStatusDaysSupply(String days) {
    return '약 $days일 분량 남음';
  }

  @override
  String formulaStatusDaysUntilEmpty(String days) {
    return '약 $days일 후 소진!';
  }

  @override
  String get diaperInventoryTitle => '기저귀 재고';

  @override
  String get diaperInventoryRegister => '기저귀 등록';

  @override
  String get diaperInventorySavedToast => '기저귀를 등록했어요 🧷';

  @override
  String get diaperInventorySize => '사이즈';

  @override
  String get diaperInventoryCount => '매수';

  @override
  String get diaperInventoryCountHint => '예: 60';

  @override
  String get diaperInventoryCountUnit => '매';

  @override
  String get diaperInventoryCountRequired => '매수는 필수예요.';

  @override
  String get diaperInventoryCountTooMany => '매수가 너무 많아요.';

  @override
  String get diaperInventoryBrandHint => '예: 하기스, 마미포코';

  @override
  String get diaperInventoryUseType => '사용 종류 (선택)';

  @override
  String get diaperInventoryDay => '낮용';

  @override
  String get diaperInventoryNight => '밤용';

  @override
  String get diaperInventoryAll => '공용';

  @override
  String get diaperInventoryNone => '등록된 기저귀가 없어요';

  @override
  String get diaperInventoryAdd => '기저귀 추가';

  @override
  String diaperInventoryLoadFailure(Object error) {
    return '재고 로딩 실패: $error';
  }

  @override
  String get diaperSizeUpTitle => '기저귀 사이즈업 예측';

  @override
  String diaperSizeUpDays(int days, String next) {
    return '약 $days일 후 $next 사이즈 권장';
  }

  @override
  String diaperSizeUpUrgent(String current, String next) {
    return '$current → $next로 곧 변경 권장!';
  }

  @override
  String diaperSizeUpOverdue(String next) {
    return '$next 사이즈 권장 시점이 지났어요';
  }

  @override
  String diaperSizeUpCurrentWeight(String kg, String current, String max) {
    return '현재 ${kg}kg · $current 적정 ${max}kg까지';
  }

  @override
  String get summaryTitle => '오늘의 요약';

  @override
  String get summaryFeeding => '수유';

  @override
  String get summarySleep => '수면';

  @override
  String get summaryDiaper => '기저귀';

  @override
  String get summaryGrowth => '성장';

  @override
  String get lastActivityFeeding => '수유';

  @override
  String get lastActivitySleep => '수면';

  @override
  String get lastActivityDiaper => '기저귀';

  @override
  String get lastActivityGrowth => '성장';

  @override
  String get familyTitle => '가족 공유';

  @override
  String get familyEntryHome => '가족 공유';

  @override
  String get familyChildPicker => '자녀 선택';

  @override
  String get familyCaregivers => '함께 돌보는 사람';

  @override
  String get familyMe => '나';

  @override
  String get familyRoleParent => '부모';

  @override
  String get familyRoleGrandparent => '조부모';

  @override
  String get familyRoleNanny => '시터';

  @override
  String get familyRoleOther => '기타';

  @override
  String familyAcceptedAt(String date) {
    return '$date 합류';
  }

  @override
  String get familyRemoveCaregiver => '내보내기';

  @override
  String get familyRemoveCaregiverConfirm => '이 사람을 가족에서 제외할까요?';

  @override
  String get familyLeave => '가족에서 나가기';

  @override
  String get familyInvites => '활성 초대 코드';

  @override
  String familyInviteExpiresAt(String date) {
    return '만료: $date';
  }

  @override
  String get familyCreateInvite => '초대 코드 만들기';

  @override
  String get familyShareCode => '코드 공유';

  @override
  String get familyRevokeInvite => '코드 회수';

  @override
  String get familyJoinTitle => '가족 참여';

  @override
  String get familyJoinHelp => '받은 6자리 초대 코드를 입력하세요.';

  @override
  String get familyCodeLabel => '초대 코드';

  @override
  String get familyCodeHint => '예: A3B7K9';

  @override
  String get familyJoinButton => '가족으로 참여';

  @override
  String get familyJoined => '가족에 합류했어요 🎉';

  @override
  String get familyInviteCreated => '코드를 발급했어요. 24시간 동안 유효해요.';

  @override
  String get familyInviteInvalid => '유효하지 않은 코드예요.';

  @override
  String get familyInviteExpired => '만료된 코드예요. 새로 발급받으세요.';

  @override
  String get familyEntryJoin => '초대 코드로 참여';

  @override
  String get statsTitle => '통계';

  @override
  String get statsEntryHome => '통계 보기';

  @override
  String get statsFeedingDaily => '일별 수유 횟수';

  @override
  String get statsSleepDaily => '일별 수면 시간';

  @override
  String get statsDiaperDaily => '일별 기저귀 횟수';

  @override
  String get statsGrowthCurve => '성장 곡선 (체중)';

  @override
  String get statsLast7Days => '지난 7일';

  @override
  String get statsLast7DaysHours => '지난 7일 (시간)';

  @override
  String get statsAllRecords => '전체 기록';

  @override
  String get statsNotEnoughData => '데이터가 부족해요. 성장 기록을 2건 이상 등록해주세요.';

  @override
  String get statsLegendChild => '내 자녀';

  @override
  String get statsLegendP50 => 'WHO 평균 (P50)';

  @override
  String get statsLegendP3P97 => 'WHO 정상 범위 (P3~P97)';

  @override
  String get notifFormulaLowTitle => '분유 곧 소진';

  @override
  String notifFormulaLowBody(String product) {
    return '$product 1일분 남았어요. 새 통 준비해주세요.';
  }

  @override
  String get notifVaccineUpcomingTitle => '예방접종 임박';

  @override
  String notifVaccineUpcomingBody(String vaccine) {
    return '내일 $vaccine 권장일이에요.';
  }
}
