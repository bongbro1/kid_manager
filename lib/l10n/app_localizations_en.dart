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
  String get addAccountTitle => 'Add child account';

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
  String get appAppearanceThemeLabel => 'Theme';

  @override
  String get appAppearanceSelectThemeTitle => 'Select theme';

  @override
  String get appAppearanceThemeSystem => 'Follow system';

  @override
  String get appAppearanceThemeLight => 'Light';

  @override
  String get appAppearanceThemeDark => 'Dark';

  @override
  String get appAppearanceSectionApp => 'APP';

  @override
  String get appAppearanceThemeSubtitle => 'Change light/dark appearance';

  @override
  String get appAppearanceSectionSecurity => 'SECURITY';

  @override
  String get appAppearanceChangePasswordTitle => 'Change password';

  @override
  String get appAppearanceChangePasswordSubtitle => 'Update your password';

  @override
  String get appAppearanceNotificationsTitle => 'Notifications';

  @override
  String get appAppearanceNotificationsSubtitle =>
      'Manage notification preferences';

  @override
  String get addAccountSuccessMessage => 'Child account created successfully';

  @override
  String get addAccountNameRequired => 'Please enter a name';

  @override
  String get addAccountAccessLabel => 'Access role';

  @override
  String get addAccountRoleChild => 'Child';

  @override
  String get addAccountRoleGuardian => 'Guardian';

  @override
  String get addAccountSelectBirthDateTitle => 'Select birth date';

  @override
  String get addAccountSelectButton => 'Select';

  @override
  String get sessionExpiredLoginAgain =>
      'Session expired. Please sign in again.';

  @override
  String userVmLoadUserError(String error) {
    return 'Failed to load user: $error';
  }

  @override
  String userVmLoadChildrenError(String error) {
    return 'Failed to load children: $error';
  }

  @override
  String userVmLoadMembersError(String error) {
    return 'Failed to load members: $error';
  }

  @override
  String get userVmFamilyIdNotFound => 'Family ID was not found';

  @override
  String userVmLoadFamilyError(String error) {
    return 'Failed to load family: $error';
  }

  @override
  String get userVmUserIdNotFound => 'User ID was not found';

  @override
  String get userVmFullNameRequired => 'Full name cannot be empty';

  @override
  String get userVmUpdatePhotoFailed => 'Failed to update photo';

  @override
  String subscriptionLoadError(String error) {
    return 'Failed to load subscription: $error';
  }

  @override
  String subscriptionWatchError(String error) {
    return 'Failed to watch subscription: $error';
  }

  @override
  String subscriptionUpdateError(String error) {
    return 'Failed to update subscription: $error';
  }

  @override
  String subscriptionActivateError(String error) {
    return 'Failed to activate plan: $error';
  }

  @override
  String subscriptionStartTrialError(String error) {
    return 'Failed to start trial: $error';
  }

  @override
  String subscriptionMarkExpiredError(String error) {
    return 'Failed to mark subscription as expired: $error';
  }

  @override
  String subscriptionClearError(String error) {
    return 'Failed to clear subscription: $error';
  }

  @override
  String get appManagementSyncFailed => 'Could not sync apps';

  @override
  String get appManagementUserIdNotFound => 'User ID was not found';

  @override
  String zoneStatusAtText(String zoneName, String duration) {
    return 'at $zoneName • $duration';
  }

  @override
  String zoneStatusWasAtText(String zoneName) {
    return 'was at $zoneName';
  }

  @override
  String zoneStatusWasAtWithAgoText(String zoneName, String ago) {
    return 'was at $zoneName • $ago';
  }

  @override
  String zoneStatusDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String zoneStatusDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get zoneStatusJustNow => 'just now';

  @override
  String zoneStatusMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String zoneStatusHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String zoneStatusDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get otpResendCooldownError =>
      'Please wait before requesting another OTP';

  @override
  String get otpResendLockedError =>
      'You requested OTP too many times. Please try again later';

  @override
  String get otpResendMaxError => 'You requested OTP too many times';

  @override
  String otpRepositoryLockedMessage(int seconds) {
    return 'OTP sending is temporarily locked. Please try again in ${seconds}s';
  }

  @override
  String get authLoginCancelled => 'Login was cancelled';

  @override
  String get continueButton => 'Continue';

  @override
  String zoneDetailsRadiusLabel(String radius) {
    return 'Radius ${radius}m';
  }

  @override
  String get zoneDetailsNoCoordinates =>
      'No coordinates available to display the map';

  @override
  String birthdaySpecialDayHeadline(String name) {
    return 'It\'s $name\'s special day!';
  }

  @override
  String get mapTopBarTitle => 'Location';

  @override
  String childGroupMarkerCount(int count) {
    return '$count children';
  }

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordSuccessMessage => 'Password changed successfully';

  @override
  String get changePasswordCurrentPasswordLabel => 'Current password';

  @override
  String get changePasswordCurrentPasswordHint => 'Enter current password';

  @override
  String get changePasswordNewPasswordLabel => 'New password';

  @override
  String get changePasswordNewPasswordHint => 'Enter new password';

  @override
  String get changePasswordConfirmPasswordLabel => 'Confirm password';

  @override
  String get changePasswordConfirmPasswordHint => 'Re-enter new password';

  @override
  String get changePasswordUpdateButton => 'Update password';

  @override
  String get memberManagementTitle => 'Member management';

  @override
  String get memberManagementAddMemberTitle => 'Add member';

  @override
  String get memberManagementAddMemberSubtitle =>
      'Connect a new device for your child';

  @override
  String get memberManagementAddNowButton => 'Add now';

  @override
  String get memberManagementFamilyMembersLabel => 'FAMILY MEMBERS';

  @override
  String get memberManagementEmpty => 'No members yet';

  @override
  String get memberManagementOnline => 'Online';

  @override
  String get memberManagementOffline => 'Offline';

  @override
  String get memberManagementMessageButton => 'Message';

  @override
  String get memberManagementLocationButton => 'Location';

  @override
  String get userRoleParent => 'Parent';

  @override
  String get userRoleChild => 'Child';

  @override
  String get userRoleGuardian => 'Guardian';

  @override
  String get aboutAppName => 'My Application';

  @override
  String aboutAppVersionLabel(String version) {
    return 'Version: $version';
  }

  @override
  String get aboutAppDescription =>
      'This app helps manage accounts, track activity, and personalize the user experience.';

  @override
  String get aboutAppCopyright => '© 2026 My Company';

  @override
  String get themeSelectorTitle => 'Customize appearance';

  @override
  String get themeSelectorSubtitle =>
      'Choose the primary color and light/dark mode';

  @override
  String get themeSelectorDarkMode => 'Dark mode';

  @override
  String get themeSelectorApplyButton => 'Apply appearance';

  @override
  String get phoneAuthTitle => 'Login with phone number';

  @override
  String get phoneAuthSendOtpButton => 'Send OTP';

  @override
  String get phoneAuthOtpTitle => 'Enter verification code';

  @override
  String get phoneAuthOtpInstruction =>
      'Please enter the OTP sent to your phone number';

  @override
  String get termsTitle => 'Terms';

  @override
  String get termsNoData => 'No data available';

  @override
  String termsLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get homeTitle => 'Home';

  @override
  String get homeGreeting => 'Hello';

  @override
  String get homeManageChildButton => 'Manage child';

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
  String get birthdayMemberFallback => 'Member';

  @override
  String birthdayWishSelfWithAge(int age) {
    return 'Happy birthday to me. Welcome $age with joy, peace, and beautiful moments.';
  }

  @override
  String get birthdayWishSelfDefault =>
      'Happy birthday to me. Wishing myself a joyful and memorable day.';

  @override
  String birthdayWishOtherWithAge(String name, int age) {
    return 'Happy birthday, $name. Wishing you a healthy, joyful, and lucky year at $age.';
  }

  @override
  String birthdayWishOtherDefault(String name) {
    return 'Happy birthday, $name. Wishing you joy, good health, and lots of happy moments.';
  }

  @override
  String get birthdayViewWishButton => 'View wish';

  @override
  String get birthdaySendWishButton => 'Send wishes';

  @override
  String get birthdayCongratsYouTitle => 'Happy birthday to you';

  @override
  String get birthdayCongratsTitle => 'Happy birthday';

  @override
  String get birthdayTodayIsYourDay => 'Today is your day';

  @override
  String birthdayTurnsAge(int age) {
    return 'Turning $age';
  }

  @override
  String get birthdaySuggestionTitle => 'Suggested wish';

  @override
  String birthdayYouEnteringAge(int age) {
    return 'Today you turn $age. Wishing you a gentle, joyful, and memorable day.';
  }

  @override
  String get birthdayYouSpecialDay =>
      'Today is your special day. Wishing you lots of joy and positive energy.';

  @override
  String birthdayTodayIsBirthdayWithAge(String name, int age) {
    return 'Today is $name\'s birthday, turning $age.';
  }

  @override
  String birthdayTodayIsBirthday(String name) {
    return 'Today is $name\'s birthday.';
  }

  @override
  String get birthdayCountdownTitle => '✨ Upcoming birthday';

  @override
  String get birthdayCountdownSelfTitle => '✨ Your birthday is coming';

  @override
  String get birthdayCountdownTomorrowChip => 'Tomorrow';

  @override
  String birthdayCountdownDaysChip(int days) {
    return '$days days left';
  }

  @override
  String birthdayCountdownOtherBody(String name, int days) {
    return '$name\'s birthday is in $days days.';
  }

  @override
  String birthdayCountdownOtherBodyTomorrow(String name) {
    return 'Tomorrow is $name\'s birthday.';
  }

  @override
  String birthdayCountdownSelfBody(int days) {
    return 'Your birthday is in $days days.';
  }

  @override
  String get birthdayCountdownSelfBodyTomorrow => 'Tomorrow is your birthday.';

  @override
  String get birthdayCountdownSuggestionTitle => 'Preparation ideas';

  @override
  String birthdayCountdownSuggestionOther(String name) {
    return 'You can prepare a wish, a gift, or a little surprise for $name starting now.';
  }

  @override
  String get birthdayCountdownSuggestionSelf =>
      'You can prepare a wish, a small gift, or a little surprise for yourself starting now.';

  @override
  String get birthdayCountdownPlanButton => 'Prepare wish';

  @override
  String birthdayCopiedFallback(String name) {
    return 'Family chat was not found. The birthday wish for $name has been copied.';
  }

  @override
  String get birthdayCloseButton => 'Close';

  @override
  String get birthdayAwesomeButton => 'Awesome';

  @override
  String get familyChatLoadingTitle => 'Loading chat';

  @override
  String get familyChatTitle => 'Family group chat';

  @override
  String get familyChatTitleLarge => 'Family Group Chat';

  @override
  String familyChatSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get familyChatYou => 'You';

  @override
  String get familyChatMemberFallback => 'Member';

  @override
  String get familyChatLoadingMembers => 'Loading members...';

  @override
  String get familyChatNoMembersFound => 'No members found';

  @override
  String get familyChatOneMember => '1 member';

  @override
  String familyChatManyMembers(int count) {
    return '$count members';
  }

  @override
  String get familyChatCannotLoadMessages => 'Cannot load messages';

  @override
  String get familyChatNoMessagesYet =>
      'No messages yet. Start the conversation.';

  @override
  String get familyChatStatusFailed => 'failed';

  @override
  String get familyChatStatusSending => 'sending...';

  @override
  String get familyChatTypeMessageHint => 'Type a message...';

  @override
  String familyChatMemberCountOverflow(String names, int extra) {
    return '$names +$extra';
  }

  @override
  String get notificationScreenTitle => 'Notifications';

  @override
  String get notificationDateToday => 'TODAY';

  @override
  String get notificationDateYesterday => 'YESTERDAY';

  @override
  String get notificationFilterTitle => 'Filter notifications';

  @override
  String get notificationFilterAll => 'All';

  @override
  String get notificationFilterActivity => 'Activity';

  @override
  String get notificationFilterAlert => 'Alerts';

  @override
  String get notificationFilterReminder => 'Reminders';

  @override
  String get notificationFilterSystem => 'System notifications';

  @override
  String get notificationSearchHint => 'Search notifications';

  @override
  String get notificationJustNow => 'Just now';

  @override
  String notificationMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String notificationHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get notificationDetailTitle => 'Notification details';

  @override
  String get notificationDetailSectionTitle => 'DETAILS';

  @override
  String get notificationChildFallback => 'Child';

  @override
  String get notificationChildInfoNotFound =>
      'Child information could not be found';

  @override
  String get notificationMapLocationNotFound =>
      'Location could not be found to open the map';

  @override
  String notificationScheduleCreatedTitle(String childName) {
    return 'New schedule for $childName';
  }

  @override
  String notificationScheduleUpdatedTitle(String childName) {
    return '$childName\'s schedule has changed';
  }

  @override
  String notificationScheduleDeletedTitle(String childName) {
    return '$childName\'s schedule was deleted';
  }

  @override
  String notificationScheduleRestoredTitle(String childName) {
    return '$childName\'s schedule was restored';
  }

  @override
  String notificationZoneEnteredDangerTitle(String childName) {
    return '$childName entered a danger zone';
  }

  @override
  String notificationZoneExitedSafeTitle(String childName) {
    return '$childName left a safe zone';
  }

  @override
  String notificationZoneExitedDangerTitle(String childName) {
    return '$childName left a danger zone';
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
  String get memoryDayReminderLabel => 'Remind before';

  @override
  String get memoryDayReminderNone => 'No reminder';

  @override
  String get memoryDayReminderOneDay => '1 day before';

  @override
  String get memoryDayReminderThreeDays => '3 days before';

  @override
  String get memoryDayReminderSevenDays => '7 days before';

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
  String get memoryDayEditAction => 'Edit';

  @override
  String get memoryDayDeleteAction => 'Delete';

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
  String get notificationsLocalChannelName => 'Default';

  @override
  String get notificationsLocalChannelDescription => 'Default notifications';

  @override
  String get notificationsDefaultTitle => 'Notifications';

  @override
  String get notificationsDefaultBody => 'You have a new notification';

  @override
  String get notificationsFamilyChatTitle => 'Family chat';

  @override
  String get notificationsFamilyChatBody => 'You have a new message';

  @override
  String get notificationsFamilyEventTitle => 'Family event';

  @override
  String get notificationsFamilyEventBody => 'Your family has a new event';

  @override
  String get notificationsBirthdayTitle => 'Birthday';

  @override
  String notificationsBirthdayUpcomingBody(String name) {
    return '$name\'s birthday is coming soon!';
  }

  @override
  String notificationsBirthdayTodayBody(String name) {
    return 'Today is $name\'s birthday!';
  }

  @override
  String get notificationsTrackingDefaultBody => 'Tracking status has changed.';

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
  String get zonesOverlappingPrefix => 'Overlapping with: ';

  @override
  String zonesOverlappingWith(String name) {
    return 'Overlapping with: $name';
  }

  @override
  String get zonesDefaultNameFallback => 'Zone';

  @override
  String get parentLocationUnknownUser => 'Unknown';

  @override
  String get parentLocationSosSent => 'SOS sent';

  @override
  String get parentLocationSosFailed => 'Failed to send SOS';

  @override
  String get parentLocationMapLoadingTitle => 'Loading map';

  @override
  String get parentLocationMapLoadingSubtitle =>
      'Preparing the children\'s locations';

  @override
  String get parentChildrenListTitle => 'Member list';

  @override
  String get personalInfoManageAccountsTitle => 'Account management';

  @override
  String get personalInfoManageAccountsSubtitle => 'Manage member accounts';

  @override
  String get personalInfoDetailsButton => 'Details';

  @override
  String get childLocationTransportWalking => 'Walking';

  @override
  String get childLocationTransportBicycle => 'Cycling';

  @override
  String get childLocationTransportVehicle => 'In vehicle';

  @override
  String get childLocationTransportStill => 'Still';

  @override
  String get childLocationTransportUnknown => 'Unknown';

  @override
  String get childLocationDetailTitle => 'Location details';

  @override
  String childLocationStatusTitle(String transport) {
    return 'Status: $transport';
  }

  @override
  String childLocationHistoryTitle(String date) {
    return 'History • $date';
  }

  @override
  String get childLocationTooltipHideDots => 'Hide points';

  @override
  String get childLocationTooltipShowDots => 'Show points';

  @override
  String get childLocationHistoryButton => 'History';

  @override
  String get childLocationZonesButton => 'Zones';

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

  @override
  String get sosChannelName => 'SOS Alerts';

  @override
  String get sosChannelDescription => 'Emergency SOS alerts';

  @override
  String get sosFallbackTitle => 'Emergency SOS';

  @override
  String get sosFallbackBody => 'A family member is asking for help.';

  @override
  String get localAlarmDangerChannelName => 'Danger zone alerts';

  @override
  String get localAlarmDangerChannelDescription =>
      'Alerts when a child enters or leaves a danger zone';

  @override
  String get localAlarmDangerEnterTitle => 'Danger zone alert';

  @override
  String localAlarmDangerEnterBody(String zoneName) {
    return 'You entered: $zoneName';
  }

  @override
  String get localAlarmDangerExitTitle => 'Left danger zone';

  @override
  String localAlarmDangerExitBody(String zoneName) {
    return 'You left: $zoneName';
  }

  @override
  String get trackingStatusLocationServiceOffMessage =>
      'Device turned off GPS/location';

  @override
  String get trackingStatusLocationPermissionDeniedMessage =>
      'Device turned off location permission';

  @override
  String get trackingStatusPreciseLocationDeniedMessage =>
      'Device has not granted precise location';

  @override
  String get trackingStatusBackgroundDisabledMessage =>
      'Background location sharing is off';

  @override
  String get trackingStatusOkMessage => 'Location is working normally';

  @override
  String get trackingErrorEnableLocationService =>
      'Please turn on GPS/location on the device.';

  @override
  String get trackingErrorEnablePreciseLocation =>
      'Please allow precise location.';

  @override
  String get trackingErrorEnableBackgroundLocation =>
      'Please allow background location sharing (Allow all the time).';

  @override
  String get locationForegroundServiceTitle => 'Sharing location';

  @override
  String get locationForegroundServiceSubtitle =>
      'The app runs in background to help protect your child';

  @override
  String parentLocationGpsError(Object error) {
    return 'GPS error: $error';
  }

  @override
  String parentLocationEnableGpsError(Object error) {
    return 'Failed to enable GPS: $error';
  }

  @override
  String parentLocationCurrentLocationError(Object error) {
    return 'Could not get current location: $error';
  }

  @override
  String parentLocationHistoryLoadError(Object error) {
    return 'Failed to load history: $error';
  }

  @override
  String parentLocationWatchChildError(Object childId, Object error) {
    return 'Failed to watch $childId: $error';
  }

  @override
  String get authLoginRequired => 'Not logged in';

  @override
  String get firebaseAuthCurrentPasswordIncorrect =>
      'Current password is incorrect';

  @override
  String get firebaseAuthUserMismatch => 'Authenticated account does not match';

  @override
  String get firebaseAuthTooManyRequests =>
      'Too many failed attempts. Please try again later';

  @override
  String get firebaseAuthNetworkFailed =>
      'Network connection error. Please check your internet';

  @override
  String get firebaseAuthChangePasswordFailed =>
      'Could not change password. Please try again';

  @override
  String get permissionLocationTitle => 'Enable location access';

  @override
  String get permissionLocationSubtitle =>
      'The app needs location permission to track your child\'s position and support safety features.';

  @override
  String get permissionLocationRecommendation =>
      'Recommended: allow location while using the app first. If background tracking is needed later, you can grant Always permission after that.';

  @override
  String get permissionLocationAllowButton => 'Allow location';

  @override
  String get permissionNotificationTitle => 'Enable SOS Alerts';

  @override
  String get permissionNotificationSubtitle =>
      'The app needs notification permission to send emergency SOS alerts even when the app is closed.';

  @override
  String get permissionNotificationRecommendation =>
      'After granting permission, make sure the \"SOS Alerts\" notification channel has sound enabled in system settings.';

  @override
  String get permissionNotificationAllowButton => 'Allow notifications';

  @override
  String get permissionSosTitle => 'Enable SOS access';

  @override
  String get permissionSosSubtitle =>
      'The app needs notification permission to send emergency SOS alerts and play alarm sounds.';

  @override
  String get permissionSosRecommendation =>
      'Please enable notifications and make sure the \"SOS Alerts\" channel has sound enabled.';

  @override
  String get permissionSosAllowButton => 'Allow SOS';

  @override
  String get permissionOpenSettingsButton => 'Open settings';

  @override
  String get permissionLaterButton => 'Later';

  @override
  String permissionStepLabel(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String get applyButton => 'Apply';

  @override
  String get commonStartLabel => 'Start';

  @override
  String get commonEndLabel => 'End';

  @override
  String get childLocationSosSending => 'Sending SOS...';

  @override
  String childLocationSosError(String error) {
    return 'SOS error: $error';
  }

  @override
  String get childLocationCurrentJourneyTitle => 'Current journey';

  @override
  String get childLocationTravelHistoryTitle => 'Movement history';

  @override
  String get childLocationTodayLabel => 'Today';

  @override
  String get childLocationRangeAllDay => 'All day';

  @override
  String get childLocationTagStart => 'Start';

  @override
  String get childLocationTagEnd => 'End';

  @override
  String get childLocationTagGpsVeryWeak => 'Very weak GPS';

  @override
  String get childLocationTagGpsLost => 'GPS lost';

  @override
  String get childLocationStayedHereLabel => 'Stayed here';

  @override
  String get childLocationStayedHereUnavailable => 'Unavailable';

  @override
  String get childLocationSpeedLabel => 'Speed';

  @override
  String get childLocationSpeedUnavailable => 'Unavailable';

  @override
  String get childLocationGpsAccuracyLabel => 'GPS accuracy';

  @override
  String get childLocationMockGpsLabel => 'Mock GPS';

  @override
  String get childLocationMockGpsDetected => 'Detected';

  @override
  String get childLocationNoLabel => 'No';

  @override
  String get childLocationTechnicalDetailsTitle => 'Technical details';

  @override
  String get childLocationDetailFullTimeLabel => 'Timestamp';

  @override
  String get childLocationDetailHeadingLabel => 'Heading';

  @override
  String get childLocationDetailCoordinatesLabel => 'Coordinates';

  @override
  String get childLocationDetailAccuracyLabel => 'Accuracy';

  @override
  String get childLocationDurationZeroMinutes => '0 min';

  @override
  String childLocationDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String childLocationDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String childLocationDurationSeconds(int seconds) {
    return '$seconds sec';
  }

  @override
  String get childLocationGpsLostTitle => 'GPS signal lost';

  @override
  String get childLocationGpsVeryWeakSubtitle =>
      'GPS signal is very weak. The location may be inaccurate.';

  @override
  String childLocationGpsLostSubtitle(String meters) {
    return 'Accuracy is worse than $meters m';
  }

  @override
  String get childLocationStoppedNowTitle => 'Currently stopped';

  @override
  String childLocationStoppedNowSubtitle(String duration) {
    return 'Stopped here for $duration';
  }

  @override
  String get childLocationStoppedHereTitle => 'Stopped here';

  @override
  String childLocationStoppedHereSubtitle(String duration) {
    return 'Stopped for about $duration';
  }

  @override
  String get childLocationJourneyStartSubtitle => 'Journey starting point';

  @override
  String get childLocationJourneyEndSubtitle => 'Journey ending point';

  @override
  String childLocationUpdatedAt(String time) {
    return 'Updated at $time';
  }

  @override
  String childLocationPassedAt(String time) {
    return 'Passed this point at $time';
  }

  @override
  String get childLocationHeadlineWalking => 'Walking';

  @override
  String get childLocationHeadlineBicycle => 'Cycling';

  @override
  String get childLocationHeadlineVehicle => 'In vehicle';

  @override
  String get childLocationHeadlineStill => 'Standing still';

  @override
  String get childLocationHeadlineUnknown => 'Unknown status';

  @override
  String get childLocationSpeedAlmostStill => 'Almost not moving';

  @override
  String get childLocationAccuracySevere => 'Severe GPS loss';

  @override
  String get childLocationAccuracyLost => 'GPS lost';

  @override
  String childLocationAccuracyGood(String meters) {
    return 'Fairly accurate ($meters m)';
  }

  @override
  String childLocationAccuracyModerate(String meters) {
    return 'Moderate accuracy ($meters m)';
  }

  @override
  String get childLocationTimeWindowTitle => 'Choose a time range';

  @override
  String get childLocationTimeWindowSubtitle =>
      'Only load and show history within the selected time range.';

  @override
  String get childLocationPresetMorning => 'Morning';

  @override
  String get childLocationPresetAfternoon => 'Afternoon';

  @override
  String get childLocationPresetEvening => 'Evening';

  @override
  String get childLocationNoDataTitle => 'No data in this range';

  @override
  String get childLocationNoDataSubtitle =>
      'Try another time range or another day to review the journey.';

  @override
  String get childLocationSummaryDateLabel => 'Date';

  @override
  String get childLocationSummaryTimeRangeLabel => 'Time range';

  @override
  String get childLocationLiveLabel => 'Live';

  @override
  String childLocationPointCount(int count) {
    return '$count points';
  }

  @override
  String get locationNoLocationYet => 'No location yet';

  @override
  String locationCoordinatesSummary(String lat, String lng) {
    return 'Lat $lat • Lng $lng';
  }

  @override
  String get locationSearchHint => 'Search';

  @override
  String get locationMessageSent => 'Message sent';

  @override
  String get locationChildInfoTitle => 'Information';

  @override
  String get locationQuickMessageHint => 'Send a quick message...';

  @override
  String get locationStatusStudying => 'Studying';

  @override
  String get locationStopSearching => 'Stop searching';

  @override
  String incomingSosConfirmFailed(Object error) {
    return 'Confirmation failed: $error';
  }

  @override
  String get incomingSosEmergencyTitle => '🚨 Emergency SOS alert!';

  @override
  String get incomingSosResolvingButton => 'PROCESSING';

  @override
  String get incomingSosConfirmButton => 'CONFIRM';

  @override
  String get sosConfirmedRoleParent => 'Parent';

  @override
  String get sosConfirmedRoleChild => 'Child';

  @override
  String get sosConfirmedNameLabel => 'Name';

  @override
  String get sosConfirmedSenderLabel => 'Sender';

  @override
  String get sosConfirmedSentAtLabel => 'Sent at';

  @override
  String get sosConfirmedConfirmedAtLabel => 'Confirmed at';

  @override
  String get sosConfirmedAccuracyLabel => 'Accuracy';

  @override
  String get sosConfirmedTitle => 'SOS confirmed';

  @override
  String get sosConfirmedCloseButton => 'CLOSE';

  @override
  String get sosButtonLabel => 'SOS';

  @override
  String get parentPhoneSaveFailed => 'Could not save the phone number';

  @override
  String get parentPhoneAddTitle => 'Add your child\'s phone number';

  @override
  String get parentPhoneAddSubtitle =>
      'Contact your child even when their phone is in silent mode';

  @override
  String get parentPhoneAddButton => 'Add';

  @override
  String get parentPhoneContactHasNoNumber =>
      'This contact has no phone number';

  @override
  String parentPhonePickFailed(Object error) {
    return 'Could not get the phone number from contacts: $error';
  }

  @override
  String get parentPhonePickTitle => 'Choose phone number';

  @override
  String get parentPhoneOpenContactsButton => 'Open contacts';

  @override
  String get appImageReplaceOption => 'Change image';

  @override
  String get appImageLoadFailed => 'Could not load image';

  @override
  String get photoUpdateFailedMessage => 'Failed to update photo';

  @override
  String get mapTypeSheetTitle => 'Map type';

  @override
  String get mapTypeDefault => 'Default';

  @override
  String get mapTypeSatellite => 'Satellite';

  @override
  String get mapTypeTerrain => 'Terrain';

  @override
  String get phoneHelperSaveSuccessTitle => 'Added successfully';

  @override
  String get phoneHelperSaveSuccessMessage =>
      'The child\'s phone number has been saved successfully';

  @override
  String phoneHelperCallActionFailed(Object error) {
    return 'Could not complete the call action: $error';
  }

  @override
  String get phoneHelperOpenDialerFailed => 'Could not open the phone app';

  @override
  String phoneHelperLaunchCallFailed(Object error) {
    return 'Phone call failed: $error';
  }

  @override
  String get scheduleRepositoryNotFound => 'Schedule not found';

  @override
  String get scheduleRepositoryCurrentNotFound => 'Current schedule not found';

  @override
  String get scheduleRepositoryHistoryNotFound => 'History record not found';

  @override
  String get locationRepositoryLoginRequired =>
      'Not logged in. Unable to send location';

  @override
  String get locationRepositoryParentIdNotFound => 'Parent account not found';

  @override
  String get cupertinoTimePickerDoneButton => 'Done';
}
