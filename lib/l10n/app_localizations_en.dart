// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BabyNote';

  @override
  String get homeWelcome => 'Welcome';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRegister => 'Register';

  @override
  String get commonRegistering => 'Registering…';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonOr => 'OR';

  @override
  String get commonNoSelection => 'None';

  @override
  String get commonOptional => '(Optional)';

  @override
  String get commonTapToSelect => 'Tap to select';

  @override
  String get commonNumberOnly => 'Numbers only please.';

  @override
  String get commonPositiveOnly => 'Positive numbers only.';

  @override
  String get commonNoRecordYet => 'No record yet';

  @override
  String get commonNoEntryYet => 'No entry yet';

  @override
  String get commonDataInsufficient => 'Not enough data';

  @override
  String get commonRegisterChildFirst => 'Please register a child first.';

  @override
  String get commonGoRegisterChild => 'Go to register child';

  @override
  String get commonNotLoggedIn => 'Not logged in.';

  @override
  String get commonMemoOptional => 'Memo (Optional)';

  @override
  String errorFailed(Object error) {
    return 'Failed: $error';
  }

  @override
  String errorChildrenLoadFailed(Object error) {
    return 'Failed to load children: $error';
  }

  @override
  String errorChildLoadFailed(Object error) {
    return 'Failed to load child: $error';
  }

  @override
  String errorAuthStream(Object error) {
    return 'Auth stream error: $error';
  }

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int n) {
    return '${n}m ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '${n}h ago';
  }

  @override
  String timeDaysAgo(int n) {
    return '${n}d ago';
  }

  @override
  String timeYesterdayAt(String hhmm) {
    return 'yesterday $hhmm';
  }

  @override
  String get authStartTitle => 'Start BabyNote';

  @override
  String get authLogin => 'Sign In';

  @override
  String get authSignup => 'Sign Up';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authDisplayNameLabel => 'Display name (optional)';

  @override
  String get authDisplayNameHint => 'e.g. Mom, Dad';

  @override
  String get authDisplayNameHelp =>
      'Visible to others when sharing with family';

  @override
  String get homeLogout => 'Sign out';

  @override
  String get homeMyChildren => 'My Children';

  @override
  String get homeAddChild => 'Add child';

  @override
  String get homeFirstChild => 'Register first child';

  @override
  String get homeNoChildYet => 'No child registered yet';

  @override
  String homeChildSubtitle(String gender, int days) {
    return '$gender · $days days old';
  }

  @override
  String get homeLastActivity => 'Last activity';

  @override
  String get homeTodayRecord => 'Today\'s record';

  @override
  String get homeInventory => 'Inventory';

  @override
  String get homeFormulaInventoryEntry => 'Formula inventory';

  @override
  String get homeDiaperInventoryEntry => 'Diaper inventory';

  @override
  String get homeHospital => 'Hospital';

  @override
  String get homeHospitalEntry => 'Hospitals (call · directions)';

  @override
  String get homeVaccineEntry => 'Vaccination schedule';

  @override
  String get homeNoLogin => 'Not signed in';

  @override
  String get homeAnonymous => 'Anonymous';

  @override
  String get homeUser => 'User';

  @override
  String get childRegisterTitle => 'Register child';

  @override
  String get childName => 'Name';

  @override
  String get childNameHint => 'e.g., Baby';

  @override
  String get childNameRequired => 'Name is required.';

  @override
  String get childGender => 'Gender';

  @override
  String get childGenderFemale => 'Girl';

  @override
  String get childGenderMale => 'Boy';

  @override
  String get childGenderOther => 'Other';

  @override
  String get childGenderUnset => 'Unset';

  @override
  String get childBirthDate => 'Birth date';

  @override
  String get childBirthDateHelp => 'Pick birth date';

  @override
  String get childBirthDateRequired => 'Please select birth date.';

  @override
  String get childBirthWeightLabel => 'Birth weight (kg, optional)';

  @override
  String get childBirthWeightHint => 'e.g., 3.45';

  @override
  String get childBirthHeightLabel => 'Birth height (cm, optional)';

  @override
  String get childBirthHeightHint => 'e.g., 51.5';

  @override
  String childRegisterFailed(Object error) {
    return 'Register failed: $error';
  }

  @override
  String get feedingTitle => 'Feeding record';

  @override
  String get feedingTabBreast => 'Breast';

  @override
  String get feedingTabFormula => 'Formula';

  @override
  String get feedingTabSolid => 'Solid';

  @override
  String get feedingSavedToast => 'Feeding saved 🍼';

  @override
  String feedingSaveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String feedingPhotoFailed(Object error) {
    return 'Photo pick failed: $error';
  }

  @override
  String get feedingBreastSide => 'Which side?';

  @override
  String get feedingBreastLeft => 'Left';

  @override
  String get feedingBreastRight => 'Right';

  @override
  String get feedingBreastBoth => 'Both';

  @override
  String get feedingBreastAmountLabel => 'Amount (ml, optional)';

  @override
  String get feedingBreastAmountHint => 'Enter for pumped milk';

  @override
  String get feedingFormulaAmountLabel => 'Amount (ml)';

  @override
  String get feedingFormulaAmountHint => 'e.g., 120';

  @override
  String get feedingFormulaBrandLabel => 'Product/brand (optional)';

  @override
  String get feedingFormulaBrandHint => 'e.g., Aptamil Stage 1';

  @override
  String get feedingInUse => 'In use';

  @override
  String get feedingAutoSubtract => 'Auto-subtract on save';

  @override
  String get feedingNoActiveFormula =>
      'No active formula container.\nWill auto-subtract once registered.';

  @override
  String get feedingSolidFoodLabel => 'Food name';

  @override
  String get feedingSolidFoodHint => 'e.g., rice porridge, pumpkin soup';

  @override
  String get feedingSolidAmountLabel => 'Amount (ml, optional)';

  @override
  String get feedingSolidAmountHint => 'Approx amount';

  @override
  String get feedingPhotoOptional => 'Photo (optional)';

  @override
  String get feedingPickFromGallery => 'Pick from gallery';

  @override
  String get feedingMemoHint => 'e.g., burped well, picky eater';

  @override
  String get sleepTitle => 'Sleep record';

  @override
  String get sleepStartedToast => 'Sleep started! Sweet dreams 💤';

  @override
  String get sleepFinishedToast => 'Sleep recorded ✅';

  @override
  String get sleepNapNight => 'Nap/Night';

  @override
  String get sleepNap => 'Nap';

  @override
  String get sleepNight => 'Night';

  @override
  String get sleepGoToSleep => 'Fell asleep';

  @override
  String get sleepStarting => 'Starting…';

  @override
  String get sleepWakeUp => 'Just woke up';

  @override
  String get sleepFinishing => 'Finishing…';

  @override
  String get sleepStartLabel => 'Start';

  @override
  String get sleepElapsed => 'Elapsed';

  @override
  String get sleepKindLabel => 'Kind';

  @override
  String sleepInProgressLoadFailure(Object error) {
    return 'Failed to load ongoing sleep: $error';
  }

  @override
  String get sleepMemoHint => 'e.g., held to sleep, watched mobile';

  @override
  String get sleepNapInProgress => 'Napping';

  @override
  String get sleepNightInProgress => 'Sleeping at night';

  @override
  String sleepDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get diaperTitle => 'Diaper record';

  @override
  String get diaperSavedToast => 'Diaper saved 💩';

  @override
  String get diaperType => 'Type';

  @override
  String get diaperPee => 'Pee';

  @override
  String get diaperPoop => 'Poop';

  @override
  String get diaperBoth => 'Both';

  @override
  String get diaperColor => 'Color';

  @override
  String get diaperColorYellow => 'Yellow';

  @override
  String get diaperColorBrown => 'Brown';

  @override
  String get diaperColorGreen => 'Green';

  @override
  String get diaperColorBlack => 'Black';

  @override
  String get diaperColorRed => 'Red';

  @override
  String get diaperColorWhite => 'White';

  @override
  String get diaperColorUnknown => 'Unknown';

  @override
  String get diaperColorAbnormalWarn =>
      'Unusual color. Please consult a doctor as soon as possible.';

  @override
  String get diaperConsistency => 'Consistency';

  @override
  String get diaperLoose => 'Loose';

  @override
  String get diaperNormal => 'Normal';

  @override
  String get diaperFirm => 'Firm';

  @override
  String get diaperAmount => 'Amount';

  @override
  String get diaperSmall => 'Small';

  @override
  String get diaperLarge => 'Large';

  @override
  String get diaperMemoHint => 'e.g., more than usual';

  @override
  String get diaperNoActivePack =>
      'No active diaper pack.\nWill auto-subtract once registered.';

  @override
  String get growthTitle => 'Growth record';

  @override
  String get growthSavedToast => 'Growth saved 📏';

  @override
  String get growthDateHelp => 'Pick measurement date';

  @override
  String get growthAtLeastOneRequired =>
      'Please enter at least one of weight, height, or head.';

  @override
  String get growthDateLabel => 'Measurement date';

  @override
  String get growthWeightLabel => 'Weight';

  @override
  String get growthWeightHint => 'e.g., 8.45';

  @override
  String get growthHeightLabel => 'Height';

  @override
  String get growthHeightHint => 'e.g., 75.5';

  @override
  String get growthHeadLabel => 'Head circumference';

  @override
  String get growthHeadHint => 'e.g., 45.0';

  @override
  String get growthMemoHint => 'e.g., NICU, regular checkup';

  @override
  String get hospitalListTitle => 'Hospitals';

  @override
  String get hospitalRegisterTitle => 'Register hospital';

  @override
  String get hospitalSavedToast => 'Hospital saved 🏥';

  @override
  String hospitalLoadFailure(Object error) {
    return 'Failed to load hospitals: $error';
  }

  @override
  String get hospitalSpecialtyPediatrics => 'Pediatrics';

  @override
  String get hospitalSpecialtyDental => 'Dental';

  @override
  String get hospitalSpecialtyER => 'ER';

  @override
  String get hospitalSpecialtyOther => 'Other';

  @override
  String get hospitalSetDefault => 'Set as default';

  @override
  String get hospitalDelete => 'Delete';

  @override
  String get hospitalCall => 'Call';

  @override
  String get hospitalDirections => 'Directions';

  @override
  String get hospitalCallFailed => 'Cannot open phone app.';

  @override
  String get hospitalMapsFailed => 'Cannot open maps app.';

  @override
  String get hospitalDeleteConfirmTitle => 'Delete this hospital?';

  @override
  String get hospitalDeleteConfirmBody => 'This action cannot be undone.';

  @override
  String get hospitalNone => 'No hospitals registered';

  @override
  String get hospitalAdd => 'Add hospital';

  @override
  String get hospitalNameLabel => 'Hospital name';

  @override
  String get hospitalNameHint => 'e.g., Local Pediatrics';

  @override
  String get hospitalNameRequired => 'Hospital name is required.';

  @override
  String get hospitalSpecialty => 'Specialty';

  @override
  String get hospitalPhone => 'Phone';

  @override
  String get hospitalPhoneHint => 'e.g., 555-123-4567';

  @override
  String get hospitalAddress => 'Address';

  @override
  String get hospitalAddressHint => 'e.g., 123 Main St';

  @override
  String get hospitalMemoHint => 'e.g., night clinic, friendly doctor';

  @override
  String get hospitalDefaultTitle => 'Set as default hospital';

  @override
  String get hospitalDefaultSubtitle =>
      'Priority for notifications/one-tap call';

  @override
  String get vaccineListTitle => 'Vaccination schedule';

  @override
  String get vaccineSectionOverdue => 'Overdue / not yet given';

  @override
  String get vaccineSectionUpcoming => 'Upcoming / not yet given';

  @override
  String get vaccineSectionCompleted => 'Completed';

  @override
  String get vaccineRecordTitle => 'Vaccination record';

  @override
  String get vaccineDoseDate => 'Dose date';

  @override
  String get vaccineDateHelp => 'Pick dose date';

  @override
  String vaccineRecommendedAge(int days) {
    return 'Recommended: $days days old';
  }

  @override
  String vaccineHospitalLoadFailure(Object error) {
    return 'Failed to load hospitals: $error';
  }

  @override
  String get vaccineHospitalNone => 'No hospitals registered. Add later';

  @override
  String get vaccineHospitalLabel => 'Hospital (optional)';

  @override
  String get vaccineMemoHint => 'e.g., no side effects';

  @override
  String get vaccineRecordButton => 'Record dose';

  @override
  String vaccineScheduleLoadFailure(Object error) {
    return 'Failed to load schedule: $error';
  }

  @override
  String vaccineRecordsLoadFailure(Object error) {
    return 'Failed to load records: $error';
  }

  @override
  String get upcomingVaccineTitle => 'Upcoming vaccination';

  @override
  String get upcomingVaccineToday => 'recommended today';

  @override
  String upcomingVaccineDays(int n) {
    return 'in $n days';
  }

  @override
  String upcomingVaccineOverdue(int n) {
    return '${n}d overdue';
  }

  @override
  String get formulaInventoryTitle => 'Formula inventory';

  @override
  String get formulaRegisterTitle => 'Register formula';

  @override
  String get formulaSavedToast => 'Formula saved 🍼';

  @override
  String get formulaProductName => 'Product name';

  @override
  String get formulaProductHint => 'e.g., Aptamil Stage 1';

  @override
  String get formulaProductRequired => 'Product name is required.';

  @override
  String get formulaBrandLabel => 'Brand (optional)';

  @override
  String get formulaBrandHint => 'e.g., Aptamil, Maeil';

  @override
  String get formulaCapacity => 'Capacity';

  @override
  String get formulaCapacityHint => 'e.g., 800';

  @override
  String get formulaCapacityRequired => 'Capacity is required.';

  @override
  String get formulaCapacityTooLarge => 'Capacity too large. Check unit (g).';

  @override
  String get formulaPurchaseDateOptional => 'Purchase date (optional)';

  @override
  String get formulaPurchaseDateLabel => 'Purchase date';

  @override
  String get formulaOpenedDateOptional =>
      'Opened date (optional, blank = stored)';

  @override
  String get formulaNotOpenedYet => 'Not opened yet';

  @override
  String get formulaOpenedDateLabel => 'Opened date';

  @override
  String get formulaPriceLabel => 'Price (optional, KRW)';

  @override
  String get formulaPriceHint => 'e.g., 35000';

  @override
  String get formulaPriceUnit => 'won';

  @override
  String get formulaShopLabel => 'Shop (optional)';

  @override
  String get formulaShopHint => 'e.g., Coupang, pharmacy';

  @override
  String get formulaSectionInUse => 'In use';

  @override
  String get formulaSectionStored => 'Stored';

  @override
  String get formulaSectionDepleted => 'Depleted';

  @override
  String get formulaActionOpen => 'Open';

  @override
  String get formulaActionDeplete => 'Deplete';

  @override
  String formulaRemainCalcFailed(Object error) {
    return 'Remain calc failed: $error';
  }

  @override
  String formulaExpectedDays(String days) {
    return 'depleted in ~$days days';
  }

  @override
  String formulaInventoryLoadFailure(Object error) {
    return 'Failed to load inventory: $error';
  }

  @override
  String get formulaNone => 'No formula registered';

  @override
  String get formulaAdd => 'Add formula';

  @override
  String get formulaStatusTitle => 'Formula remaining';

  @override
  String formulaStatusDaysSupply(String days) {
    return '~$days days supply left';
  }

  @override
  String formulaStatusDaysUntilEmpty(String days) {
    return 'Empty in ~$days days!';
  }

  @override
  String get diaperInventoryTitle => 'Diaper inventory';

  @override
  String get diaperInventoryRegister => 'Register diaper';

  @override
  String get diaperInventorySavedToast => 'Diaper saved 🧷';

  @override
  String get diaperInventorySize => 'Size';

  @override
  String get diaperInventoryCount => 'Count';

  @override
  String get diaperInventoryCountHint => 'e.g., 60';

  @override
  String get diaperInventoryCountUnit => 'pcs';

  @override
  String get diaperInventoryCountRequired => 'Count is required.';

  @override
  String get diaperInventoryCountTooMany => 'Too many.';

  @override
  String get diaperInventoryBrandHint => 'e.g., Pampers, Huggies';

  @override
  String get diaperInventoryUseType => 'Use type (optional)';

  @override
  String get diaperInventoryDay => 'Day';

  @override
  String get diaperInventoryNight => 'Night';

  @override
  String get diaperInventoryAll => 'All-day';

  @override
  String get diaperInventoryNone => 'No diapers registered';

  @override
  String get diaperInventoryAdd => 'Add diapers';

  @override
  String diaperInventoryLoadFailure(Object error) {
    return 'Failed to load inventory: $error';
  }

  @override
  String get diaperSizeUpTitle => 'Diaper size-up forecast';

  @override
  String diaperSizeUpDays(int days, String next) {
    return 'Move to $next in ~$days days';
  }

  @override
  String diaperSizeUpUrgent(String current, String next) {
    return 'Time to size up: $current → $next!';
  }

  @override
  String diaperSizeUpOverdue(String next) {
    return 'Past $next size-up window';
  }

  @override
  String diaperSizeUpCurrentWeight(String kg, String current, String max) {
    return 'Now ${kg}kg · $current fits up to ${max}kg';
  }

  @override
  String get summaryTitle => 'Today\'s summary';

  @override
  String get summaryFeeding => 'Feeding';

  @override
  String get summarySleep => 'Sleep';

  @override
  String get summaryDiaper => 'Diaper';

  @override
  String get summaryGrowth => 'Growth';

  @override
  String get lastActivityFeeding => 'Feeding';

  @override
  String get lastActivitySleep => 'Sleep';

  @override
  String get lastActivityDiaper => 'Diaper';

  @override
  String get lastActivityGrowth => 'Growth';

  @override
  String get familyTitle => 'Family sharing';

  @override
  String get familyEntryHome => 'Family sharing';

  @override
  String get familyChildPicker => 'Pick child';

  @override
  String get familyCaregivers => 'Caregivers';

  @override
  String get familyMe => 'Me';

  @override
  String get familyRoleParent => 'Parent';

  @override
  String get familyRoleGrandparent => 'Grandparent';

  @override
  String get familyRoleNanny => 'Nanny';

  @override
  String get familyRoleOther => 'Other';

  @override
  String familyAcceptedAt(String date) {
    return 'joined $date';
  }

  @override
  String get familyRemoveCaregiver => 'Remove';

  @override
  String get familyRemoveCaregiverConfirm =>
      'Remove this person from the family?';

  @override
  String get familyLeave => 'Leave family';

  @override
  String get familyInvites => 'Active invites';

  @override
  String familyInviteExpiresAt(String date) {
    return 'expires $date';
  }

  @override
  String get familyCreateInvite => 'Create invite code';

  @override
  String get familyShareCode => 'Share';

  @override
  String get familyRevokeInvite => 'Revoke';

  @override
  String get familyJoinTitle => 'Join family';

  @override
  String get familyJoinHelp =>
      'Enter the 6-character invite code you received.';

  @override
  String get familyCodeLabel => 'Invite code';

  @override
  String get familyCodeHint => 'e.g. A3B7K9';

  @override
  String get familyJoinButton => 'Join family';

  @override
  String get familyJoined => 'Joined the family 🎉';

  @override
  String get familyInviteCreated => 'Code created. Valid for 24 hours.';

  @override
  String get familyInviteInvalid => 'Invalid code.';

  @override
  String get familyInviteExpired => 'Code expired. Please request a new one.';

  @override
  String get familyEntryJoin => 'Join with code';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsEntryHome => 'View statistics';

  @override
  String get statsFeedingDaily => 'Feedings per day';

  @override
  String get statsSleepDaily => 'Sleep hours per day';

  @override
  String get statsDiaperDaily => 'Diapers per day';

  @override
  String get statsGrowthCurve => 'Growth curve (weight)';

  @override
  String get statsLast7Days => 'Last 7 days';

  @override
  String get statsLast7DaysHours => 'Last 7 days (hours)';

  @override
  String get statsAllRecords => 'All records';

  @override
  String get statsNotEnoughData =>
      'Not enough data. Please add at least 2 growth records.';

  @override
  String get statsLegendChild => 'Your child';

  @override
  String get statsLegendP50 => 'WHO median (P50)';

  @override
  String get statsLegendP3P97 => 'WHO normal range (P3~P97)';

  @override
  String get notifFormulaLowTitle => 'Formula running low';

  @override
  String notifFormulaLowBody(String product) {
    return '$product has 1 day left. Please prepare a new container.';
  }

  @override
  String get notifVaccineUpcomingTitle => 'Upcoming vaccination';

  @override
  String notifVaccineUpcomingBody(String vaccine) {
    return '$vaccine is recommended tomorrow.';
  }

  @override
  String get childEditTitle => 'Edit child';

  @override
  String get childEditSaved => 'Child saved';

  @override
  String get childDeleteAction => 'Delete child';

  @override
  String get childDeleteTitle => 'Delete this child?';

  @override
  String childDeleteWarning(String name) {
    return '$name and all records (feedings, sleep, diapers, growth, inventory, vaccinations) will be permanently deleted. This cannot be undone.';
  }

  @override
  String get childDeleted => 'Child deleted';

  @override
  String get recordDeleteTitle => 'Delete this record?';

  @override
  String get recordDeleteBody =>
      'This action cannot be undone. Long-press deletes only the most recent entry.';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get recordsTitle => 'All records';

  @override
  String get recordsEntryHome => 'View all records';

  @override
  String get recordsEmpty =>
      'No records yet. Add new entries from the home screen.';

  @override
  String get recordsDeleteBody =>
      'This action cannot be undone. Long-press a card to delete one entry.';

  @override
  String get feedingEditTitle => 'Edit feeding';

  @override
  String get sleepEditTitle => 'Edit sleep';

  @override
  String get diaperEditTitle => 'Edit diaper';

  @override
  String get growthEditTitle => 'Edit growth';

  @override
  String get recordEditSaved => 'Record updated';

  @override
  String get formulaEditTitle => 'Edit formula';

  @override
  String get diaperInventoryEditTitle => 'Edit diaper pack';

  @override
  String get inventoryDeleteTitle => 'Delete this inventory?';

  @override
  String inventoryDeleteBody(String name) {
    return '$name will be permanently deleted. This cannot be undone.';
  }

  @override
  String get inventoryDeleted => 'Inventory deleted';
}
