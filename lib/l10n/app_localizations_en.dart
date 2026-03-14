// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get personalInfoTitle => 'Personal Information';

  @override
  String get appAppearanceTitle => 'App Appearance';

  @override
  String get aboutAppTitle => 'About app';

  @override
  String get addAccountTitle => 'Add account';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameHint => 'Enter full name';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneHint => '+84 012345678';

  @override
  String get genderLabel => 'Gender';

  @override
  String get genderHint => 'Male';

  @override
  String get birthDateLabel => 'Birth date';

  @override
  String get birthDateHint => '12/12/2003';

  @override
  String get addressLabel => 'Address';

  @override
  String get addressHint => 'Diem Thuy commune, Thai Nguyen province';

  @override
  String get locationTrackingLabel => 'Location tracking';

  @override
  String get allowLocationTrackingText => 'Allow others to track location';

  @override
  String get yearsOld => '%d years old';

  @override
  String get updateSuccessTitle => 'Success';

  @override
  String get updateSuccessMessage => 'Profile updated successfully';

  @override
  String get updateErrorTitle => 'Failed';

  @override
  String get invalidBirthDate => 'Invalid birth date';

  @override
  String get confirmLogoutQuestion => 'Do you want to logout?';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get languageSetting => 'Language';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get english => 'English';

  @override
  String get changeLanguagePrompt => 'Change language, app will restart';

  @override
  String get accountNotFound => 'Account not found';

  @override
  String get accountNotActivated => 'Account not activated';

  @override
  String get emailNotRegistered => 'Email not registered';

  @override
  String get noLocationPermission => 'No location permission';

  @override
  String get gpsError => 'GPS error';

  @override
  String get currentLocationError => 'Cannot get current location';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get codeExpired => 'Code expired';

  @override
  String get tooManyAttempts => 'Too many attempts';

  @override
  String get unknownError => 'An error occurred';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get weakPassword => 'Weak password';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get emailInUse => 'Email already in use';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get authStartTitle => 'Get Started';

  @override
  String get authStartSubtitle => 'Continue with the app now!';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithFacebook => 'Continue with Facebook';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueWithPhone => 'Continue with phone number';

  @override
  String get authLoginButton => 'Login';

  @override
  String get authSignupButton => 'Sign up';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authTermsOfService => 'Terms of Service';

  @override
  String get authEnterAllInfo => 'Please fill in all required information';

  @override
  String get authInvalidCredentials => 'Incorrect account information';

  @override
  String get authUserProfileLoadFailed => 'Failed to load user profile';

  @override
  String get authGenericError => 'Something went wrong';

  @override
  String get authWelcomeBackTitle => 'WELCOME BACK';

  @override
  String get authLoginNowSubtitle => 'Login now!';

  @override
  String get authEnterEmailHint => 'Enter email';

  @override
  String get authEnterPasswordHint => 'Enter password';

  @override
  String get authRememberPassword => 'Remember password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authOr => 'Or';

  @override
  String get authNoAccount => 'You don\'t have an account, ';

  @override
  String get authSignUpInline => 'sign up';

  @override
  String get authSignupTitle => 'CREATE\nACCOUNT NOW';

  @override
  String get authSignupSubtitle => 'Monitor and manage your kids!';

  @override
  String get authPasswordMismatch => 'Password confirmation does not match';

  @override
  String get authSignupFailed => 'Sign up failed';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authAgreeTermsPrefix => 'Agree to terms, ';

  @override
  String get authAgreeTermsLink => 'here';

  @override
  String get authHaveAccount => 'You already have an account, ';

  @override
  String get authLoginInline => 'login';

  @override
  String get authForgotPasswordTitle => 'FORGOT PASSWORD?';

  @override
  String get authForgotPasswordSubtitle =>
      'Did you forget your password? Follow the steps below to recover it.';

  @override
  String get authEnterYourEmailLabel => 'Enter your email';

  @override
  String get authContinueButton => 'Continue';

  @override
  String get authSendOtpFailed => 'Failed to send OTP';

  @override
  String get otpTitle => 'ENTER OTP CODE';

  @override
  String get otpInstruction =>
      'We have sent a verification code to your email address';

  @override
  String get otpNeed4Digits => 'Please enter all 4 OTP digits';

  @override
  String get otpDigitsOnly => 'OTP must contain digits only';

  @override
  String get otpIncorrect => 'Incorrect OTP';

  @override
  String get otpExpired => 'OTP has expired';

  @override
  String get otpTooManyAttempts =>
      'You have entered incorrectly more than 3 times. Please wait 10 minutes.';

  @override
  String get otpRequestNotFound => 'OTP request not found';

  @override
  String otpResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpVerifyButton => 'Verify';

  @override
  String get authRegisterSuccessMessage => 'Account registered successfully';

  @override
  String get resetPasswordTitle => 'RESET\nNEW PASSWORD';

  @override
  String get resetPasswordSubtitle => 'Enter your new password!';

  @override
  String get resetPasswordNewLabel => 'New password';

  @override
  String get resetPasswordConfirmLabel => 'Confirm password';

  @override
  String get resetPasswordConfirmMismatch =>
      'Re-entered password does not match';

  @override
  String get resetPasswordRuleTitle => 'Password requirements';

  @override
  String get resetPasswordRuleMinLength => 'At least 8 characters';

  @override
  String get resetPasswordRuleUppercase => 'Contains uppercase letters';

  @override
  String get resetPasswordRuleLowercase => 'Contains lowercase letters';

  @override
  String get resetPasswordRuleNumber => 'Contains numbers';

  @override
  String get resetPasswordCompleteButton => 'Complete';

  @override
  String get resetPasswordSuccessMessage => 'Password reset successfully';

  @override
  String get authCompleteTitle => 'Completed!';

  @override
  String get authRegisterCongratsMessage =>
      'Congratulations! You have registered successfully';

  @override
  String get authBackToLogin => 'Back to login';

  @override
  String get flashWelcomeTitle => 'Welcome to the app';

  @override
  String get flashWelcomeSubtitle => 'Child tracking application';

  @override
  String get flashNext => 'Next';

  @override
  String get scheduleScreenTitle => 'Schedule';

  @override
  String get scheduleNoChild => 'No child yet';

  @override
  String get scheduleFormTitleHint => 'Schedule title';

  @override
  String get scheduleFormDescriptionHint => 'Description';

  @override
  String get scheduleAddHeaderTitle => 'Add event';

  @override
  String get scheduleFormDateLabel => 'Date';

  @override
  String get scheduleFormStartTimeLabel => 'Start time';

  @override
  String get scheduleFormEndTimeLabel => 'End time';

  @override
  String get scheduleFormEndTimeInvalid => 'End time must be later';

  @override
  String get scheduleFormSavingButton => 'Saving...';

  @override
  String get scheduleAddSubmitButton => 'Create schedule';

  @override
  String get scheduleAddSuccessMessage => 'Schedule created successfully';

  @override
  String get scheduleDialogWarningTitle => 'Warning';

  @override
  String get scheduleEditHeaderTitle => 'Edit schedule';

  @override
  String get scheduleEditSubmitButton => 'Save schedule';

  @override
  String get scheduleEditSuccessMessage => 'Schedule updated successfully';

  @override
  String get scheduleSelectChildLabel => 'Select child';

  @override
  String get scheduleYourChild => 'Your child';

  @override
  String get schedulePleaseSelectChild => 'Please select a child';

  @override
  String get scheduleExportTitle => 'Export Excel';

  @override
  String get scheduleExportDateRangeLabel => 'Date range';

  @override
  String get scheduleExportColumnsHint =>
      'Export file includes columns: title, description, date, start, end';

  @override
  String get scheduleExportLoadingButton => 'Exporting...';

  @override
  String get scheduleExportSubmitButton => 'Export file';

  @override
  String get scheduleExportInvalidDateRange =>
      'Start date cannot be after end date';

  @override
  String get scheduleExportNoDataInRange => 'No schedules in selected range';

  @override
  String get scheduleExportSaveCanceled => 'File save was canceled';

  @override
  String scheduleExportSuccessMessage(int count) {
    return 'Excel export successful ($count schedules)';
  }

  @override
  String scheduleExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get scheduleImportTitle => 'Import Excel';

  @override
  String get scheduleTemplateDownloadButton => 'Download template';

  @override
  String get scheduleTemplateSaveCanceled => 'Template save was canceled';

  @override
  String get scheduleTemplateSavedSuccess => 'Template saved successfully';

  @override
  String scheduleTemplateDownloadFailed(String error) {
    return 'Template download failed: $error';
  }

  @override
  String get scheduleImportCannotReadFile =>
      'Cannot read file, please try again';

  @override
  String get scheduleImportMissingOwner => 'Cannot determine schedule owner';

  @override
  String get scheduleImportNoValidItems => 'No valid schedules to import';

  @override
  String get scheduleImportSuccessMessage => 'Schedules imported successfully';

  @override
  String scheduleImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String scheduleImportAddCount(int count) {
    return 'Add $count schedules';
  }

  @override
  String get scheduleImportPickFileButton => 'Choose Excel file';

  @override
  String get scheduleImportPickAnotherFileButton => 'Choose another file';

  @override
  String scheduleImportSelectedFile(String fileName) {
    return 'Selected: $fileName';
  }

  @override
  String get scheduleImportChangeFileButton => 'Change file';

  @override
  String scheduleImportSummaryOk(int count) {
    return 'OK: $count';
  }

  @override
  String scheduleImportSummaryDuplicate(int count) {
    return 'Duplicate: $count';
  }

  @override
  String scheduleImportSummaryError(int count) {
    return 'Error: $count';
  }

  @override
  String get scheduleImportPreviewTitle => 'Preview data';

  @override
  String get scheduleImportStatusOk => 'OK';

  @override
  String get scheduleImportStatusError => 'ERROR';

  @override
  String get scheduleImportStatusDuplicate => 'DUPLICATE';

  @override
  String scheduleImportRowError(int row, String error) {
    return 'Row $row: $error';
  }

  @override
  String scheduleImportRowTitle(int row, String title) {
    return 'Row $row: $title';
  }

  @override
  String get scheduleImportDuplicateInSystem =>
      'Duplicate with existing system data';

  @override
  String get scheduleImportDuplicateInFile => 'Duplicate within file';

  @override
  String get scheduleHistoryTitle => 'Edit history';

  @override
  String get scheduleHistoryEmpty => 'No edit history yet';

  @override
  String get scheduleHistoryToday => 'Today';

  @override
  String get scheduleHistoryYesterday => 'Yesterday';

  @override
  String get scheduleHistoryRestoreDialogTitle => 'Restore schedule';

  @override
  String get scheduleHistoryRestoreDialogMessage =>
      'Are you sure you want to restore this version?';

  @override
  String get scheduleHistoryRestoreButton => 'Restore';

  @override
  String get scheduleHistoryRestoringButton => 'Restoring...';

  @override
  String get scheduleHistoryRestoreSuccessMessage =>
      'Schedule restored successfully';

  @override
  String scheduleHistoryRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String scheduleHistoryEditedAt(String time) {
    return 'Edited at $time';
  }

  @override
  String get scheduleHistoryLabelTitle => 'Schedule title:';

  @override
  String get scheduleHistoryLabelDescription => 'Description:';

  @override
  String get scheduleHistoryLabelDate => 'Date:';

  @override
  String get scheduleHistoryLabelTime => 'Time:';

  @override
  String get scheduleDrawerMenuTitle => 'Menu';

  @override
  String get scheduleCreateButtonAddEvent => '+ Add event';

  @override
  String get schedulePeriodTitle => 'Time';

  @override
  String get schedulePeriodMorning => 'Morning';

  @override
  String get schedulePeriodAfternoon => 'Afternoon';

  @override
  String get schedulePeriodEvening => 'Evening';

  @override
  String get scheduleCalendarFormatMonth => 'Month';

  @override
  String get scheduleCalendarFormatWeek => 'Week';

  @override
  String scheduleCalendarMonthLabel(int month) {
    return 'Month $month';
  }

  @override
  String get scheduleWeekdayMon => 'Mon';

  @override
  String get scheduleWeekdayTue => 'Tue';

  @override
  String get scheduleWeekdayWed => 'Wed';

  @override
  String get scheduleWeekdayThu => 'Thu';

  @override
  String get scheduleWeekdayFri => 'Fri';

  @override
  String get scheduleWeekdaySat => 'Sat';

  @override
  String get scheduleWeekdaySun => 'Sun';

  @override
  String get scheduleNoEventsInDay => 'No schedules for this day';

  @override
  String get scheduleDeleteTitle => 'Delete schedule';

  @override
  String get scheduleDeleteConfirmMessage => 'Are you sure you want to delete?';

  @override
  String get scheduleDeleteSuccessMessage => 'Deleted successfully';

  @override
  String scheduleDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get memoryDayTitle => 'Memorable days';

  @override
  String get memoryDayEmpty => 'No memorable days yet';

  @override
  String get memoryDayDeleteTitle => 'Delete memorable day';

  @override
  String get memoryDayDeleteConfirmMessage =>
      'Are you sure you want to delete?';

  @override
  String get memoryDayDeleteSuccessMessage => 'Deleted successfully';

  @override
  String get memoryDayDeleteFailedMessage => 'Delete failed, please try again';

  @override
  String memoryDayDeleteFailedWithError(String error) {
    return 'Delete failed: $error';
  }

  @override
  String memoryDayDaysPassed(int days) {
    return 'Passed $days days';
  }

  @override
  String get memoryDayToday => 'Today';

  @override
  String memoryDayDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String memoryDayDateText(String date) {
    return 'Date: $date';
  }

  @override
  String memoryDayDateRepeatText(String date) {
    return 'Date: $date (repeats yearly)';
  }

  @override
  String get memoryDayUnsavedTitle => 'Unsaved changes';

  @override
  String get memoryDayUnsavedExitMessage =>
      'You have unsaved changes. Are you sure you want to exit?';

  @override
  String get memoryDayFormTitleLabel => 'Title';

  @override
  String get memoryDayFormDateLabel => 'Date';

  @override
  String get memoryDayFormNoteLabel => 'Note';

  @override
  String get memoryDayRepeatYearlyLabel => 'Repeat yearly';

  @override
  String get memoryDayEditHeaderTitle => 'Edit memorable day';

  @override
  String get memoryDayAddHeaderTitle => 'Add memorable day';

  @override
  String get memoryDayEditSuccessMessage => 'Changes saved successfully';

  @override
  String get memoryDayAddSuccessMessage => 'Memorable day added successfully';

  @override
  String get memoryDaySaveFailedMessage =>
      'Something went wrong, please try again';

  @override
  String get memoryDaySavingButton => 'Saving...';

  @override
  String get memoryDaySaveChangesButton => 'Save changes';

  @override
  String get memoryDayAddButton => 'Add memorable day';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptySubtitle => 'New notifications will appear here';

  @override
  String get notificationsDefaultChildName => 'Child';

  @override
  String get notificationsNoTitle => 'No title';

  @override
  String get notificationsActionCreated => 'Added';

  @override
  String get notificationsActionUpdated => 'Updated';

  @override
  String get notificationsActionDeleted => 'Deleted';

  @override
  String get notificationsActionRestored => 'Restored';

  @override
  String get notificationsActionChanged => 'Changed';

  @override
  String get notificationsScheduleTitleLabel => 'Schedule title';

  @override
  String get notificationsChildNameLabel => 'Child name';

  @override
  String get notificationsDateLabel => 'Date';

  @override
  String get notificationsTimeLabel => 'Time';

  @override
  String get notificationsViewScheduleButton => 'View schedule';

  @override
  String get notificationsRepeatLabel => 'Repeat';

  @override
  String get notificationsRepeatYearly => 'Yearly';

  @override
  String get notificationsRepeatNone => 'No repeat';

  @override
  String get notificationsImportOperatorLabel => 'Operator';

  @override
  String get notificationsChildLabel => 'Child';

  @override
  String get notificationsImportAddedCountLabel => 'Schedules added';

  @override
  String get notificationsActorParent => 'Parent';

  @override
  String get notificationsActorChild => 'Child';

  @override
  String get notificationsBlockedAccountLabel => 'Account';

  @override
  String get notificationsBlockedAppLabel => 'Application';

  @override
  String get notificationsBlockedTimeLabel => 'Time';

  @override
  String get notificationsBlockedAllowedWindowLabel => 'Allowed time window';

  @override
  String get notificationsBlockedWarningMessage =>
      'The app was automatically blocked by the system.';

  @override
  String get notificationsBlockedViewConfigButton => 'View time configuration';

  @override
  String get notificationsRemovedDeviceOfLabel => 'Device of';

  @override
  String get notificationsRemovedAppLabel => 'Removed app';

  @override
  String get notificationsRemovedAtLabel => 'Removed at';

  @override
  String get notificationsRemovedWarningMessage =>
      'The app was removed from the device. Please check if this is a managed app.';

  @override
  String get notificationsRemovedViewAppsButton => 'View app list';

  @override
  String notificationsZoneDangerEnterDescription(
    String childName,
    String zoneName,
    String time,
  ) {
    return '$childName\'s location was recorded at $zoneName. The system detected entry into a danger zone at $time.';
  }

  @override
  String notificationsZoneSafeExitDescription(
    String childName,
    String zoneName,
    String time,
  ) {
    return '$childName\'s location was recorded at $zoneName. The system detected exit from a safe zone at $time.';
  }

  @override
  String notificationsZoneDangerExitDescription(
    String childName,
    String zoneName,
    String time,
  ) {
    return '$childName\'s location was recorded at $zoneName. The system detected exit from a danger zone at $time.';
  }

  @override
  String notificationsZoneUpdatedDescription(
    String childName,
    String zoneName,
  ) {
    return '$childName\'s location was updated at $zoneName.';
  }

  @override
  String get notificationsZoneViewOnMainMapButton => 'View on main map';

  @override
  String get notificationsContactNowButton => 'Contact now';

  @override
  String scheduleOverlapConflictMessage(
    String title,
    String start,
    String end,
  ) {
    return 'Conflicts with schedule \"$title\" ($start - $end). Please choose another time.';
  }

  @override
  String get scheduleExportErrorCreateExcelFile =>
      'Unable to create Excel file';

  @override
  String get scheduleImportTemplateSampleTitle1 => 'Math Study';

  @override
  String get scheduleImportTemplateSampleDescription1 =>
      'Complete exercises 1-5';

  @override
  String get scheduleImportTemplateSampleTitle2 => 'Play football';

  @override
  String get scheduleImportErrorCreateExcelBytes =>
      'Unable to create Excel bytes';

  @override
  String get scheduleImportErrorMissingTitle => 'Missing title';

  @override
  String get scheduleImportErrorEndAfterStart =>
      'End time must be after start time';

  @override
  String scheduleImportWarningDbCheckFailed(String error) {
    return 'Duplicate check against database failed due to network error: $error';
  }

  @override
  String get scheduleImportErrorMissingDate => 'Missing date';

  @override
  String scheduleImportErrorInvalidDate(String raw) {
    return 'Invalid date: \"$raw\"';
  }

  @override
  String scheduleImportErrorInvalidDateSupported(String raw) {
    return 'Invalid date: \"$raw\" (supported: yyyy-MM-dd, dd/MM/yyyy, MM/dd/yyyy, ISO datetime)';
  }

  @override
  String get scheduleImportErrorMissingTime => 'Missing time';

  @override
  String scheduleImportErrorInvalidTimeSupported(String raw) {
    return 'Invalid time: \"$raw\" (supported: HH:mm, HH:mm:ss, 7:00 AM/PM)';
  }

  @override
  String get scheduleNotifyTitleCreated => 'New schedule';

  @override
  String get scheduleNotifyTitleUpdated => 'Schedule updated';

  @override
  String get scheduleNotifyTitleDeleted => 'Schedule deleted';

  @override
  String get scheduleNotifyTitleRestored => 'Schedule restored';

  @override
  String get scheduleNotifyTitleChanged => 'Schedule changed';

  @override
  String scheduleNotifyBodyParentCreated(
    String title,
    String childName,
    String date,
    String time,
  ) {
    return 'Parent added schedule \"$title\" for $childName on $date, $time.';
  }

  @override
  String scheduleNotifyBodyParentUpdated(String title, String childName) {
    return 'Parent updated schedule \"$title\" of $childName.';
  }

  @override
  String scheduleNotifyBodyParentDeleted(String title, String childName) {
    return 'Parent deleted schedule \"$title\" of $childName.';
  }

  @override
  String scheduleNotifyBodyParentRestored(String title, String childName) {
    return 'Parent restored an older version of schedule \"$title\" of $childName.';
  }

  @override
  String scheduleNotifyBodyParentChanged(String title, String childName) {
    return 'Parent changed schedule \"$title\" of $childName.';
  }

  @override
  String scheduleNotifyBodyChildCreated(
    String childName,
    String title,
    String date,
    String time,
  ) {
    return '$childName added schedule \"$title\" on $date, $time.';
  }

  @override
  String scheduleNotifyBodyChildUpdated(String childName, String title) {
    return '$childName updated schedule \"$title\".';
  }

  @override
  String scheduleNotifyBodyChildDeleted(String childName, String title) {
    return '$childName deleted schedule \"$title\".';
  }

  @override
  String scheduleNotifyBodyChildRestored(String childName, String title) {
    return '$childName restored edit history of schedule \"$title\".';
  }

  @override
  String scheduleNotifyBodyChildChanged(String childName, String title) {
    return '$childName changed schedule \"$title\".';
  }

  @override
  String get memoryDayNotifyTitleCreated => 'New memorable day';

  @override
  String get memoryDayNotifyTitleUpdated => 'Memorable day updated';

  @override
  String get memoryDayNotifyTitleDeleted => 'Memorable day deleted';

  @override
  String get memoryDayNotifyTitleChanged => 'Memorable day changed';

  @override
  String memoryDayNotifyBodyParentCreated(String title) {
    return 'Parent added memorable day \"$title\".';
  }

  @override
  String memoryDayNotifyBodyParentUpdated(String title) {
    return 'Parent updated memorable day \"$title\".';
  }

  @override
  String memoryDayNotifyBodyParentDeleted(String title) {
    return 'Parent deleted memorable day \"$title\".';
  }

  @override
  String memoryDayNotifyBodyParentChanged(String title) {
    return 'Parent changed memorable day \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildCreated(String actorChildName, String title) {
    return '$actorChildName added memorable day \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildUpdated(String actorChildName, String title) {
    return '$actorChildName updated memorable day \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildDeleted(String actorChildName, String title) {
    return '$actorChildName deleted memorable day \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildChanged(String actorChildName, String title) {
    return '$actorChildName changed memorable day \"$title\".';
  }

  @override
  String get scheduleImportNotifyTitle => 'New schedules added';

  @override
  String scheduleImportNotifyBodyParent(int importCount, String childName) {
    return 'Parent added $importCount schedules for $childName.';
  }

  @override
  String scheduleImportNotifyBodyChild(String actorChildName, int importCount) {
    return '$actorChildName added $importCount schedules.';
  }

  @override
  String get parentDashboardTitle => 'Dashboard';

  @override
  String get parentDashboardTabApps => 'Apps';

  @override
  String get parentDashboardTabStatistics => 'Statistics';

  @override
  String get parentDashboardNoDeviceTitle => 'No linked devices yet';

  @override
  String get parentDashboardNoDeviceSubtitle =>
      'To monitor app usage time, add your child\'s device to the system.';

  @override
  String get parentDashboardAddDeviceButton => 'Add device';

  @override
  String get parentDashboardHowItWorksButton => 'Learn how it works';

  @override
  String get parentStatsTotalToday => 'TOTAL TIME TODAY';

  @override
  String get parentStatsTotalThisWeek => 'TOTAL TIME THIS WEEK';

  @override
  String get parentStatsSelectRange => 'SELECT DATE RANGE';

  @override
  String get parentStatsSelectEndDate => 'SELECT END DATE';

  @override
  String parentStatsTotalFromRange(String startDate, String endDate) {
    return 'TOTAL TIME FROM $startDate - $endDate';
  }

  @override
  String get parentStatsSegmentDay => 'Day';

  @override
  String get parentStatsSegmentWeek => 'Week';

  @override
  String get parentStatsSegmentRange => 'Range';

  @override
  String get parentStatsAppDetailsTitle => 'App details';

  @override
  String get parentStatsCollapse => 'COLLAPSE';

  @override
  String get parentStatsViewAll => 'VIEW ALL';

  @override
  String get parentUsageNoAvailableSlot => 'No available time slot';

  @override
  String get parentUsageStartBeforeEnd =>
      'Start time must be earlier than end time';

  @override
  String get parentUsageOverlapTimeRange => 'Time range overlaps another slot';

  @override
  String get parentUsageEndAfterStart =>
      'End time must be later than start time';

  @override
  String get parentUsageEditTitle => 'Usage time settings';

  @override
  String get parentUsageEnableUsage => 'Allow usage';

  @override
  String get parentUsageSelectAllowedDays => 'Select allowed days';

  @override
  String get saveButton => 'Save';

  @override
  String get parentUsageDayRuleModalHint => 'Choose the rule for this day';

  @override
  String get parentUsageRuleFollowScheduleTitle => 'Follow schedule';

  @override
  String get parentUsageRuleFollowScheduleSubtitle =>
      'Apply weekly time windows';

  @override
  String get parentUsageRuleAllowAllDayTitle => 'Allow all day';

  @override
  String get parentUsageRuleAllowAllDaySubtitle => 'Can be used at any time';

  @override
  String get parentUsageRuleBlockAllDayTitle => 'Block all day';

  @override
  String get parentUsageRuleBlockAllDaySubtitle => 'Cannot be used today';

  @override
  String get zonesDeleteConfirmTitle => 'Confirm deletion';

  @override
  String get zonesDeleteConfirmMessage =>
      'Are you sure you want to delete this location?';

  @override
  String get zonesDeleteButton => 'Delete';

  @override
  String get zonesCreateSuccessTitle => 'Created successfully';

  @override
  String zonesCreateSuccessMessage(String name) {
    return 'Location \"$name\" has been created';
  }

  @override
  String get zonesFailedTitle => 'Failed';

  @override
  String get zonesCreateFailedMessage =>
      'Unable to create location. Please try again.';

  @override
  String get zonesEditSuccessTitle => 'Updated successfully';

  @override
  String get zonesEditSuccessMessage => 'Location has been updated';

  @override
  String get zonesEditFailedMessage =>
      'Unable to update location. Please try again.';

  @override
  String get zonesDeleteSuccessTitle => 'Deleted successfully';

  @override
  String get zonesDeleteSuccessMessage => 'Location has been deleted';

  @override
  String get zonesDeleteFailedMessage =>
      'Unable to delete location. Please try again.';

  @override
  String get zonesEmptyTitle => 'No zones yet';

  @override
  String get zonesEmptySubtitle =>
      'Add zones to start tracking your child\'s location';

  @override
  String get zonesTypeSafe => 'Safe';

  @override
  String get zonesTypeDanger => 'Danger';

  @override
  String get zonesEditMenu => 'Edit';

  @override
  String get zonesDeleteMenu => 'Delete';

  @override
  String get zonesScreenTitle => 'Child zones';

  @override
  String get zonesAddButton => 'Add zone';

  @override
  String zonesErrorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get zonesNewZoneDefaultName => 'New zone';

  @override
  String get zonesEditTitle => 'Edit zone';

  @override
  String get zonesAddAddressTitle => 'Location address';

  @override
  String get zonesOverlapWarningText => 'Locations should not overlap';

  @override
  String get zonesNameFieldLabel => 'Zone name';

  @override
  String get zonesTypeFieldLabel => 'Zone type';

  @override
  String get zonesRadiusLabel => 'Radius';

  @override
  String zonesOverlappingWith(String name) {
    return 'Overlapping with: $name';
  }

  @override
  String get zonesDefaultNameFallback => 'Zone';

  @override
  String get zone_default => 'Zone notification';

  @override
  String get zone_enter_danger_parent => '⚠️ Child entered a danger zone';

  @override
  String get zone_exit_danger_parent => '✅ Child left a danger zone';

  @override
  String get zone_enter_safe_parent => '✅ Child entered a safe zone';

  @override
  String get zone_exit_safe_parent => 'ℹ️ Child left a safe zone';

  @override
  String get zone_enter_danger_child => '⚠️ You entered a danger zone';

  @override
  String get zone_exit_danger_child => '✅ You left a danger zone';

  @override
  String get zone_enter_safe_child => '✅ You entered a safe zone';

  @override
  String get zone_exit_safe_child => 'ℹ️ You left a safe zone';

  @override
  String get tracking_location_service_off_parent_title =>
      'Child turned off location';

  @override
  String get tracking_location_permission_denied_parent_title =>
      'Child turned off location permission';

  @override
  String get tracking_background_disabled_parent_title =>
      'Background location was turned off';

  @override
  String get tracking_location_stale_parent_title =>
      'No recent location update';

  @override
  String get tracking_ok_parent_title => 'Location is active again';

  @override
  String get tracking_location_service_off_child_title =>
      'Location is turned off';

  @override
  String get tracking_location_permission_denied_child_title =>
      'Location permission is off';

  @override
  String get tracking_background_disabled_child_title =>
      'Background location is off';

  @override
  String get tracking_location_stale_child_title => 'Location is not updating';

  @override
  String get tracking_ok_child_title => 'Location is working again';

  @override
  String get tracking_default_title => 'Tracking notification';
}
