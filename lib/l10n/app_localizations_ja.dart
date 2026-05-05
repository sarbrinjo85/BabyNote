// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ベビーノート';

  @override
  String get homeWelcome => 'ようこそ';

  @override
  String get commonSave => '保存';

  @override
  String get commonRegister => '登録';

  @override
  String get commonRegistering => '登録中…';

  @override
  String get commonSaving => '保存中…';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDelete => '削除';

  @override
  String get commonAdd => '追加';

  @override
  String get commonOr => 'または';

  @override
  String get commonNoSelection => '選択しない';

  @override
  String get commonOptional => '(任意)';

  @override
  String get commonTapToSelect => 'タップして選択';

  @override
  String get commonNumberOnly => '数字のみ入力してください。';

  @override
  String get commonPositiveOnly => '正の数のみ入力してください。';

  @override
  String get commonNoRecordYet => 'まだ記録がありません';

  @override
  String get commonNoEntryYet => 'まだありません';

  @override
  String get commonDataInsufficient => 'データ不足';

  @override
  String get commonRegisterChildFirst => '先にお子さまを登録してください。';

  @override
  String get commonGoRegisterChild => 'お子さま登録へ';

  @override
  String get commonNotLoggedIn => 'ログインされていません。';

  @override
  String get commonMemoOptional => 'メモ (任意)';

  @override
  String errorFailed(Object error) {
    return '失敗: $error';
  }

  @override
  String errorChildrenLoadFailed(Object error) {
    return 'お子さま一覧の読み込みに失敗: $error';
  }

  @override
  String errorChildLoadFailed(Object error) {
    return 'お子さまの読み込みに失敗: $error';
  }

  @override
  String errorAuthStream(Object error) {
    return '認証ストリームエラー: $error';
  }

  @override
  String get timeJustNow => 'たった今';

  @override
  String timeMinutesAgo(int n) {
    return '$n分前';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n時間前';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n日前';
  }

  @override
  String timeYesterdayAt(String hhmm) {
    return '昨日 $hhmm';
  }

  @override
  String get authStartTitle => 'ベビーノートを始める';

  @override
  String get authLogin => 'ログイン';

  @override
  String get authSignup => '新規登録';

  @override
  String get authEmail => 'メール';

  @override
  String get authPassword => 'パスワード';

  @override
  String get authDisplayNameLabel => '表示名 (任意)';

  @override
  String get authDisplayNameHint => '例: ママ、パパ';

  @override
  String get authDisplayNameHelp => '家族共有時に他の人に表示される名前';

  @override
  String get homeLogout => 'ログアウト';

  @override
  String get homeMyChildren => 'お子さま';

  @override
  String get homeAddChild => 'お子さまを追加';

  @override
  String get homeFirstChild => '最初のお子さまを登録';

  @override
  String get homeNoChildYet => 'まだお子さまが登録されていません';

  @override
  String homeChildSubtitle(String gender, int days) {
    return '$gender ・ 生後 $days日';
  }

  @override
  String get homeLastActivity => '最近のアクティビティ';

  @override
  String get homeTodayRecord => '今日の記録';

  @override
  String get homeInventory => '在庫管理';

  @override
  String get homeFormulaInventoryEntry => 'ミルク在庫管理';

  @override
  String get homeDiaperInventoryEntry => 'おむつ在庫管理';

  @override
  String get homeHospital => '病院';

  @override
  String get homeHospitalEntry => 'かかりつけ病院 (電話 ・ 経路)';

  @override
  String get homeVaccineEntry => '予防接種スケジュール';

  @override
  String get homeNoLogin => '未ログイン';

  @override
  String get homeAnonymous => '匿名';

  @override
  String get homeUser => 'ユーザー';

  @override
  String get childRegisterTitle => 'お子さま登録';

  @override
  String get childName => '名前';

  @override
  String get childNameHint => '例: 山田あかちゃん';

  @override
  String get childNameRequired => '名前は必須です。';

  @override
  String get childGender => '性別';

  @override
  String get childGenderFemale => '女の子';

  @override
  String get childGenderMale => '男の子';

  @override
  String get childGenderOther => 'その他';

  @override
  String get childGenderUnset => '未設定';

  @override
  String get childBirthDate => '生年月日';

  @override
  String get childBirthDateHelp => 'お子さまの生年月日を選択';

  @override
  String get childBirthDateRequired => '生年月日を選択してください。';

  @override
  String get childBirthWeightLabel => '出生時体重 (kg, 任意)';

  @override
  String get childBirthWeightHint => '例: 3.45';

  @override
  String get childBirthHeightLabel => '出生時身長 (cm, 任意)';

  @override
  String get childBirthHeightHint => '例: 51.5';

  @override
  String childRegisterFailed(Object error) {
    return '登録失敗: $error';
  }

  @override
  String get feedingTitle => '授乳記録';

  @override
  String get feedingTabBreast => '母乳';

  @override
  String get feedingTabFormula => 'ミルク';

  @override
  String get feedingTabSolid => '離乳食';

  @override
  String get feedingSavedToast => '授乳記録を保存しました 🍼';

  @override
  String feedingSaveFailed(Object error) {
    return '保存失敗: $error';
  }

  @override
  String feedingPhotoFailed(Object error) {
    return '写真選択に失敗: $error';
  }

  @override
  String get feedingBreastSide => 'どちら側?';

  @override
  String get feedingBreastLeft => '左';

  @override
  String get feedingBreastRight => '右';

  @override
  String get feedingBreastBoth => '両方';

  @override
  String get feedingBreastAmountLabel => '量 (ml, 任意)';

  @override
  String get feedingBreastAmountHint => '搾乳の場合は入力';

  @override
  String get feedingFormulaAmountLabel => '量 (ml)';

  @override
  String get feedingFormulaAmountHint => '例: 120';

  @override
  String get feedingFormulaBrandLabel => '商品名/ブランド (任意)';

  @override
  String get feedingFormulaBrandHint => '例: アプタミル ステップ1';

  @override
  String get feedingInUse => '使用中';

  @override
  String get feedingAutoSubtract => '登録時に自動で差し引き';

  @override
  String get feedingNoActiveFormula => '使用中のミルク缶がありません。\n登録すると自動で差し引かれます。';

  @override
  String get feedingSolidFoodLabel => '食品名';

  @override
  String get feedingSolidFoodHint => '例: お粥、かぼちゃスープ、すりおろしりんご';

  @override
  String get feedingSolidAmountLabel => '量 (ml, 任意)';

  @override
  String get feedingSolidAmountHint => 'おおよその分量';

  @override
  String get feedingPhotoOptional => '写真 (任意)';

  @override
  String get feedingPickFromGallery => 'ギャラリーから写真を選択';

  @override
  String get feedingMemoHint => '例: げっぷ良好、好き嫌いあり';

  @override
  String get sleepTitle => '睡眠記録';

  @override
  String get sleepStartedToast => '睡眠開始! おやすみ 💤';

  @override
  String get sleepFinishedToast => '睡眠記録完了 ✅';

  @override
  String get sleepNapNight => 'お昼寝/夜の睡眠';

  @override
  String get sleepNap => 'お昼寝';

  @override
  String get sleepNight => '夜の睡眠';

  @override
  String get sleepGoToSleep => '寝つきました';

  @override
  String get sleepStarting => '開始中…';

  @override
  String get sleepWakeUp => '今起きました';

  @override
  String get sleepFinishing => '終了中…';

  @override
  String get sleepStartLabel => '開始';

  @override
  String get sleepElapsed => '経過';

  @override
  String get sleepKindLabel => '区分';

  @override
  String sleepInProgressLoadFailure(Object error) {
    return '進行中の睡眠取得に失敗: $error';
  }

  @override
  String get sleepMemoHint => '例: 抱っこで寝かしつけ、モビールを見て就寝';

  @override
  String get sleepNapInProgress => 'お昼寝中';

  @override
  String get sleepNightInProgress => '夜の睡眠中';

  @override
  String sleepDurationMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get diaperTitle => 'おむつ記録';

  @override
  String get diaperSavedToast => 'おむつ記録を保存しました 💩';

  @override
  String get diaperType => '種類';

  @override
  String get diaperPee => 'おしっこ';

  @override
  String get diaperPoop => 'うんち';

  @override
  String get diaperBoth => '両方';

  @override
  String get diaperColor => '色';

  @override
  String get diaperColorYellow => '黄色';

  @override
  String get diaperColorBrown => '茶色';

  @override
  String get diaperColorGreen => '緑';

  @override
  String get diaperColorBlack => '黒';

  @override
  String get diaperColorRed => '赤';

  @override
  String get diaperColorWhite => '白';

  @override
  String get diaperColorUnknown => '不明';

  @override
  String get diaperColorAbnormalWarn => '異常な色です。なるべく早く医師にご相談ください。';

  @override
  String get diaperConsistency => '形状';

  @override
  String get diaperLoose => 'ゆるい';

  @override
  String get diaperNormal => '普通';

  @override
  String get diaperFirm => '硬い';

  @override
  String get diaperAmount => '量';

  @override
  String get diaperSmall => '少なめ';

  @override
  String get diaperLarge => '多め';

  @override
  String get diaperMemoHint => '例: 普段より量が多め';

  @override
  String get diaperNoActivePack => '使用中のおむつパックがありません。\n登録すると自動で差し引かれます。';

  @override
  String get growthTitle => '成長記録';

  @override
  String get growthSavedToast => '成長記録を保存しました 📏';

  @override
  String get growthDateHelp => '計測日を選択';

  @override
  String get growthAtLeastOneRequired => '体重・身長・頭囲のいずれかを入力してください。';

  @override
  String get growthDateLabel => '計測日';

  @override
  String get growthWeightLabel => '体重';

  @override
  String get growthWeightHint => '例: 8.45';

  @override
  String get growthHeightLabel => '身長';

  @override
  String get growthHeightHint => '例: 75.5';

  @override
  String get growthHeadLabel => '頭囲';

  @override
  String get growthHeadHint => '例: 45.0';

  @override
  String get growthMemoHint => '例: 新生児室、定期健診など';

  @override
  String get hospitalListTitle => 'かかりつけ病院';

  @override
  String get hospitalRegisterTitle => '病院登録';

  @override
  String get hospitalSavedToast => '病院を登録しました 🏥';

  @override
  String hospitalLoadFailure(Object error) {
    return '病院一覧の読み込みに失敗: $error';
  }

  @override
  String get hospitalSpecialtyPediatrics => '小児科';

  @override
  String get hospitalSpecialtyDental => '歯科';

  @override
  String get hospitalSpecialtyER => '救急';

  @override
  String get hospitalSpecialtyOther => 'その他';

  @override
  String get hospitalSetDefault => 'デフォルトに設定';

  @override
  String get hospitalDelete => '削除';

  @override
  String get hospitalCall => '電話';

  @override
  String get hospitalDirections => '経路';

  @override
  String get hospitalCallFailed => '電話アプリを開けません。';

  @override
  String get hospitalMapsFailed => '地図アプリを開けません。';

  @override
  String get hospitalDeleteConfirmTitle => '病院を削除しますか?';

  @override
  String get hospitalDeleteConfirmBody => 'この操作は取り消せません。';

  @override
  String get hospitalNone => '登録された病院がありません';

  @override
  String get hospitalAdd => '病院を追加';

  @override
  String get hospitalNameLabel => '病院名';

  @override
  String get hospitalNameHint => '例: 近所の小児科';

  @override
  String get hospitalNameRequired => '病院名は必須です。';

  @override
  String get hospitalSpecialty => '診療科';

  @override
  String get hospitalPhone => '電話番号';

  @override
  String get hospitalPhoneHint => '例: 03-1234-5678';

  @override
  String get hospitalAddress => '住所';

  @override
  String get hospitalAddressHint => '例: 東京都千代田区...';

  @override
  String get hospitalMemoHint => '例: 夜間診療可、丁寧な医師';

  @override
  String get hospitalDefaultTitle => 'デフォルト病院に設定';

  @override
  String get hospitalDefaultSubtitle => '通知/ワンタップ電話などで優先表示';

  @override
  String get vaccineListTitle => '予防接種スケジュール';

  @override
  String get vaccineSectionOverdue => '期限超過 / 未接種';

  @override
  String get vaccineSectionUpcoming => '間近 / 未接種';

  @override
  String get vaccineSectionCompleted => '完了';

  @override
  String get vaccineRecordTitle => '接種記録';

  @override
  String get vaccineDoseDate => '接種日';

  @override
  String get vaccineDateHelp => '接種日を選択';

  @override
  String vaccineRecommendedAge(int days) {
    return '推奨時期: 生後 $days日';
  }

  @override
  String vaccineHospitalLoadFailure(Object error) {
    return '病院の読み込みに失敗: $error';
  }

  @override
  String get vaccineHospitalNone => '登録された病院がありません。あとで追加';

  @override
  String get vaccineHospitalLabel => '病院 (任意)';

  @override
  String get vaccineMemoHint => '例: 副反応なし';

  @override
  String get vaccineRecordButton => '接種完了を記録';

  @override
  String vaccineScheduleLoadFailure(Object error) {
    return 'スケジュール読み込みに失敗: $error';
  }

  @override
  String vaccineRecordsLoadFailure(Object error) {
    return '接種記録の読み込みに失敗: $error';
  }

  @override
  String get upcomingVaccineTitle => '次回の予防接種';

  @override
  String get upcomingVaccineToday => '本日推奨';

  @override
  String upcomingVaccineDays(int n) {
    return '$n日後推奨';
  }

  @override
  String upcomingVaccineOverdue(int n) {
    return '$n日経過';
  }

  @override
  String get formulaInventoryTitle => 'ミルク在庫';

  @override
  String get formulaRegisterTitle => 'ミルク登録';

  @override
  String get formulaSavedToast => 'ミルクを登録しました 🍼';

  @override
  String get formulaProductName => '商品名';

  @override
  String get formulaProductHint => '例: アプタミル ステップ1';

  @override
  String get formulaProductRequired => '商品名は必須です。';

  @override
  String get formulaBrandLabel => 'ブランド (任意)';

  @override
  String get formulaBrandHint => '例: アプタミル、明治';

  @override
  String get formulaCapacity => '容量';

  @override
  String get formulaCapacityHint => '例: 800';

  @override
  String get formulaCapacityRequired => '容量は必須です。';

  @override
  String get formulaCapacityTooLarge => '容量が大きすぎます。単位(g)を確認してください。';

  @override
  String get formulaPurchaseDateOptional => '購入日 (任意)';

  @override
  String get formulaPurchaseDateLabel => '購入日';

  @override
  String get formulaOpenedDateOptional => '開封日 (任意、未入力なら保管中)';

  @override
  String get formulaNotOpenedYet => '未開封';

  @override
  String get formulaOpenedDateLabel => '開封日';

  @override
  String get formulaPriceLabel => '価格 (任意、円)';

  @override
  String get formulaPriceHint => '例: 3500';

  @override
  String get formulaPriceUnit => '円';

  @override
  String get formulaShopLabel => '購入先 (任意)';

  @override
  String get formulaShopHint => '例: Amazon、ドラッグストア';

  @override
  String get formulaSectionInUse => '使用中';

  @override
  String get formulaSectionStored => '保管中';

  @override
  String get formulaSectionDepleted => '使い切り';

  @override
  String get formulaActionOpen => '開封';

  @override
  String get formulaActionDeplete => '使い切り';

  @override
  String formulaRemainCalcFailed(Object error) {
    return '残量計算失敗: $error';
  }

  @override
  String formulaExpectedDays(String days) {
    return '約 $days日後に使い切り';
  }

  @override
  String formulaInventoryLoadFailure(Object error) {
    return '在庫一覧の読み込みに失敗: $error';
  }

  @override
  String get formulaNone => '登録されたミルクがありません';

  @override
  String get formulaAdd => 'ミルクを追加';

  @override
  String get formulaStatusTitle => 'ミルク残量';

  @override
  String formulaStatusDaysSupply(String days) {
    return '約 $days日分残り';
  }

  @override
  String formulaStatusDaysUntilEmpty(String days) {
    return '約 $days日後に使い切り!';
  }

  @override
  String get diaperInventoryTitle => 'おむつ在庫';

  @override
  String get diaperInventoryRegister => 'おむつ登録';

  @override
  String get diaperInventorySavedToast => 'おむつを登録しました 🧷';

  @override
  String get diaperInventorySize => 'サイズ';

  @override
  String get diaperInventoryCount => '枚数';

  @override
  String get diaperInventoryCountHint => '例: 60';

  @override
  String get diaperInventoryCountUnit => '枚';

  @override
  String get diaperInventoryCountRequired => '枚数は必須です。';

  @override
  String get diaperInventoryCountTooMany => '枚数が多すぎます。';

  @override
  String get diaperInventoryBrandHint => '例: パンパース、ムーニー';

  @override
  String get diaperInventoryUseType => '用途 (任意)';

  @override
  String get diaperInventoryDay => '昼用';

  @override
  String get diaperInventoryNight => '夜用';

  @override
  String get diaperInventoryAll => '兼用';

  @override
  String get diaperInventoryNone => '登録されたおむつがありません';

  @override
  String get diaperInventoryAdd => 'おむつを追加';

  @override
  String diaperInventoryLoadFailure(Object error) {
    return '在庫の読み込みに失敗: $error';
  }

  @override
  String get diaperSizeUpTitle => 'おむつサイズアップ予測';

  @override
  String diaperSizeUpDays(int days, String next) {
    return '約 $days日後に $next サイズ推奨';
  }

  @override
  String diaperSizeUpUrgent(String current, String next) {
    return '$current → $next へまもなく変更推奨!';
  }

  @override
  String diaperSizeUpOverdue(String next) {
    return '$next サイズ推奨時期を過ぎています';
  }

  @override
  String diaperSizeUpCurrentWeight(String kg, String current, String max) {
    return '現在 ${kg}kg ・ $current 適正 ${max}kg まで';
  }

  @override
  String get summaryTitle => '今日のサマリー';

  @override
  String get summaryFeeding => '授乳';

  @override
  String get summarySleep => '睡眠';

  @override
  String get summaryDiaper => 'おむつ';

  @override
  String get summaryGrowth => '成長';

  @override
  String get lastActivityFeeding => '授乳';

  @override
  String get lastActivitySleep => '睡眠';

  @override
  String get lastActivityDiaper => 'おむつ';

  @override
  String get lastActivityGrowth => '成長';

  @override
  String get familyTitle => '家族共有';

  @override
  String get familyEntryHome => '家族共有';

  @override
  String get familyChildPicker => 'お子さま選択';

  @override
  String get familyCaregivers => '一緒にお世話する人';

  @override
  String get familyMe => '自分';

  @override
  String get familyRoleParent => '親';

  @override
  String get familyRoleGrandparent => '祖父母';

  @override
  String get familyRoleNanny => 'シッター';

  @override
  String get familyRoleOther => 'その他';

  @override
  String familyAcceptedAt(String date) {
    return '$date 参加';
  }

  @override
  String get familyRemoveCaregiver => '外す';

  @override
  String get familyRemoveCaregiverConfirm => 'この人を家族から外しますか?';

  @override
  String get familyLeave => '家族から抜ける';

  @override
  String get familyInvites => '有効な招待コード';

  @override
  String familyInviteExpiresAt(String date) {
    return '期限: $date';
  }

  @override
  String get familyCreateInvite => '招待コードを作成';

  @override
  String get familyShareCode => 'コードを共有';

  @override
  String get familyRevokeInvite => 'コードを取消';

  @override
  String get familyJoinTitle => '家族に参加';

  @override
  String get familyJoinHelp => '受け取った6桁の招待コードを入力してください。';

  @override
  String get familyCodeLabel => '招待コード';

  @override
  String get familyCodeHint => '例: A3B7K9';

  @override
  String get familyJoinButton => '家族に参加';

  @override
  String get familyJoined => '家族に参加しました 🎉';

  @override
  String get familyInviteCreated => 'コードを発行しました。24時間有効です。';

  @override
  String get familyInviteInvalid => '無効なコードです。';

  @override
  String get familyInviteExpired => '期限切れのコードです。新しく発行してください。';

  @override
  String get familyEntryJoin => '招待コードで参加';

  @override
  String get statsTitle => '統計';

  @override
  String get statsEntryHome => '統計を見る';

  @override
  String get statsFeedingDaily => '日別 授乳回数';

  @override
  String get statsSleepDaily => '日別 睡眠時間';

  @override
  String get statsDiaperDaily => '日別 おむつ回数';

  @override
  String get statsGrowthCurve => '成長曲線 (体重)';

  @override
  String get statsLast7Days => '過去7日';

  @override
  String get statsLast7DaysHours => '過去7日 (時間)';

  @override
  String get statsAllRecords => '全記録';

  @override
  String get statsNotEnoughData => 'データが不足しています。成長記録を2件以上登録してください。';

  @override
  String get statsLegendChild => 'うちの子';

  @override
  String get statsLegendP50 => 'WHO 平均 (P50)';

  @override
  String get statsLegendP3P97 => 'WHO 正常範囲 (P3~P97)';

  @override
  String get notifFormulaLowTitle => 'ミルク残量わずか';

  @override
  String notifFormulaLowBody(String product) {
    return '$product 残り1日分。新しい缶を準備してください。';
  }

  @override
  String get notifVaccineUpcomingTitle => '予防接種が近づいています';

  @override
  String notifVaccineUpcomingBody(String vaccine) {
    return '明日は $vaccine の推奨日です。';
  }

  @override
  String get notifSleepOngoingBody => 'タップでアプリから起床を記録';

  @override
  String get notifGrowthWeeklyTitle => '成長測定';

  @override
  String get notifGrowthWeeklyBody => '週1回の体重・身長記録をおすすめします 📏';

  @override
  String get inventoryHubTitle => '在庫管理';

  @override
  String get homeSectionData => 'データ/管理';

  @override
  String get homeSectionMedical => '医療';

  @override
  String get childEditTitle => 'お子さま情報の編集';

  @override
  String get childEditSaved => 'お子さま情報を保存しました';

  @override
  String get childDeleteAction => 'お子さまを削除';

  @override
  String get childDeleteTitle => 'お子さまを削除しますか?';

  @override
  String childDeleteWarning(String name) {
    return '$name と全記録(授乳・睡眠・おむつ・成長・在庫・接種)が永久に削除されます。取り消せません。';
  }

  @override
  String get childDeleted => 'お子さまを削除しました';

  @override
  String get recordDeleteTitle => 'この記録を削除しますか?';

  @override
  String get recordDeleteBody => 'この操作は取り消せません。長押しで削除できるのは最新の1件です。';

  @override
  String get recordDeleted => '記録を削除しました';

  @override
  String get recordsTitle => '全記録';

  @override
  String get recordsEntryHome => '全記録を見る';

  @override
  String get recordsEmpty => 'まだ記録がありません。ホームから新しい記録を追加してください。';

  @override
  String get recordsDeleteBody => 'この操作は取り消せません。カードを長押しで1件ずつ削除できます。';

  @override
  String get feedingEditTitle => '授乳記録の編集';

  @override
  String get sleepEditTitle => '睡眠記録の編集';

  @override
  String get diaperEditTitle => 'おむつ記録の編集';

  @override
  String get growthEditTitle => '成長記録の編集';

  @override
  String get recordEditSaved => '記録を更新しました';

  @override
  String get formulaEditTitle => 'ミルク情報の編集';

  @override
  String get diaperInventoryEditTitle => 'おむつ情報の編集';

  @override
  String get inventoryDeleteTitle => 'この在庫を削除しますか?';

  @override
  String inventoryDeleteBody(String name) {
    return '$name の情報が永久に削除されます。取り消せません。';
  }

  @override
  String get inventoryDeleted => '在庫を削除しました';

  @override
  String get hospitalEdit => '編集';

  @override
  String get hospitalEditTitle => '病院情報の編集';

  @override
  String get bellTooltip => '近日の予定';

  @override
  String get bellSheetTitle => '近日の予定';

  @override
  String get bellEmpty => '近日の予定はありません。ゆっくりどうぞ 🎉';

  @override
  String get bellFormulaLowTitle => 'ミルクまもなく切れ';

  @override
  String get bellSizeUpTitle => 'おむつサイズアップ';

  @override
  String get onboardingTitle => 'ベビーノートへようこそ!';

  @override
  String get onboardingBody => 'まずお子さまを登録すると\n授乳・睡眠・おむつ・成長の記録を始められます。';

  @override
  String get onboardingCta => '最初のお子さまを登録';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeHelp => 'ライト/ダークモードを直接選ぶか、システム設定に従わせることができます。';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get settingsExport => 'データのエクスポート';

  @override
  String get settingsExportHelp =>
      '現在のお子さまの全記録(授乳・睡眠・おむつ・成長)をCSVで書き出します。診察やバックアップに使えます。';

  @override
  String get settingsExportCsv => 'CSVで共有';

  @override
  String get settingsExportInProgress => '準備中…';

  @override
  String get fabQuickFeed => '授乳クイック記録';

  @override
  String get fabQuickFeedTooltip => '前回と同じパターンで1タップ記録。長押しで直接入力。';

  @override
  String fabSaved(String summary) {
    return '$summary 保存しました';
  }

  @override
  String get fabUndo => '取消';

  @override
  String get fabAmountEditTitle => '授乳量を入力';

  @override
  String get fabAmountEditHint => '例: 120';
}
