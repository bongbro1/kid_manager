import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
    Locale('vi'),
  ];

  /// No description provided for @personalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfoTitle;

  /// No description provided for @appAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'App Appearance'**
  String get appAppearanceTitle;

  /// No description provided for @aboutAppTitle.
  ///
  /// In en, this message translates to:
  /// **'About app'**
  String get aboutAppTitle;

  /// No description provided for @addAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Add child account'**
  String get addAccountTitle;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get fullNameHint;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+84 012345678'**
  String get phoneHint;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @genderHint.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderHint;

  /// No description provided for @birthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get birthDateLabel;

  /// No description provided for @birthDateHint.
  ///
  /// In en, this message translates to:
  /// **'12/12/2003'**
  String get birthDateHint;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Diem Thuy commune, Thai Nguyen province'**
  String get addressHint;

  /// No description provided for @locationTrackingLabel.
  ///
  /// In en, this message translates to:
  /// **'Location tracking'**
  String get locationTrackingLabel;

  /// No description provided for @allowLocationTrackingText.
  ///
  /// In en, this message translates to:
  /// **'Allow others to track location'**
  String get allowLocationTrackingText;

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'%d years old'**
  String get yearsOld;

  /// No description provided for @updateSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get updateSuccessTitle;

  /// No description provided for @updateSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get updateSuccessMessage;

  /// No description provided for @updateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get updateErrorTitle;

  /// No description provided for @invalidBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid birth date'**
  String get invalidBirthDate;

  /// No description provided for @confirmLogoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to logout?'**
  String get confirmLogoutQuestion;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @changeLanguagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Change language, app will restart'**
  String get changeLanguagePrompt;

  /// No description provided for @appAppearanceThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appAppearanceThemeLabel;

  /// No description provided for @appAppearanceSelectThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select theme'**
  String get appAppearanceSelectThemeTitle;

  /// No description provided for @appAppearanceThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get appAppearanceThemeSystem;

  /// No description provided for @appAppearanceThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appAppearanceThemeLight;

  /// No description provided for @appAppearanceThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appAppearanceThemeDark;

  /// No description provided for @appAppearanceSectionApp.
  ///
  /// In en, this message translates to:
  /// **'APP'**
  String get appAppearanceSectionApp;

  /// No description provided for @appAppearanceThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change light/dark appearance'**
  String get appAppearanceThemeSubtitle;

  /// No description provided for @appAppearanceSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get appAppearanceSectionSecurity;

  /// No description provided for @appAppearanceChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get appAppearanceChangePasswordTitle;

  /// No description provided for @appAppearanceChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get appAppearanceChangePasswordSubtitle;

  /// No description provided for @appAppearanceNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get appAppearanceNotificationsTitle;

  /// No description provided for @appAppearanceNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get appAppearanceNotificationsSubtitle;

  /// No description provided for @addAccountSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Child account created successfully'**
  String get addAccountSuccessMessage;

  /// No description provided for @addAccountNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get addAccountNameRequired;

  /// No description provided for @addAccountAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Access role'**
  String get addAccountAccessLabel;

  /// No description provided for @addAccountRoleChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get addAccountRoleChild;

  /// No description provided for @addAccountRoleGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get addAccountRoleGuardian;

  /// No description provided for @addAccountSelectBirthDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Select birth date'**
  String get addAccountSelectBirthDateTitle;

  /// No description provided for @addAccountSelectButton.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get addAccountSelectButton;

  /// No description provided for @sessionExpiredLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get sessionExpiredLoginAgain;

  /// No description provided for @userVmLoadUserError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user: {error}'**
  String userVmLoadUserError(String error);

  /// No description provided for @userVmLoadChildrenError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load children: {error}'**
  String userVmLoadChildrenError(String error);

  /// No description provided for @userVmLoadMembersError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load members: {error}'**
  String userVmLoadMembersError(String error);

  /// No description provided for @userVmFamilyIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Family ID was not found'**
  String get userVmFamilyIdNotFound;

  /// No description provided for @userVmLoadFamilyError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load family: {error}'**
  String userVmLoadFamilyError(String error);

  /// No description provided for @userVmUserIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'User ID was not found'**
  String get userVmUserIdNotFound;

  /// No description provided for @userVmFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name cannot be empty'**
  String get userVmFullNameRequired;

  /// No description provided for @userVmUpdatePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update photo'**
  String get userVmUpdatePhotoFailed;

  /// No description provided for @subscriptionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subscription: {error}'**
  String subscriptionLoadError(String error);

  /// No description provided for @subscriptionWatchError.
  ///
  /// In en, this message translates to:
  /// **'Failed to watch subscription: {error}'**
  String subscriptionWatchError(String error);

  /// No description provided for @subscriptionUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update subscription: {error}'**
  String subscriptionUpdateError(String error);

  /// No description provided for @subscriptionActivateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to activate plan: {error}'**
  String subscriptionActivateError(String error);

  /// No description provided for @subscriptionStartTrialError.
  ///
  /// In en, this message translates to:
  /// **'Failed to start trial: {error}'**
  String subscriptionStartTrialError(String error);

  /// No description provided for @subscriptionMarkExpiredError.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark subscription as expired: {error}'**
  String subscriptionMarkExpiredError(String error);

  /// No description provided for @subscriptionClearError.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear subscription: {error}'**
  String subscriptionClearError(String error);

  /// No description provided for @appManagementSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync apps'**
  String get appManagementSyncFailed;

  /// No description provided for @appManagementUserIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'User ID was not found'**
  String get appManagementUserIdNotFound;

  /// No description provided for @zoneStatusAtText.
  ///
  /// In en, this message translates to:
  /// **'at {zoneName} • {duration}'**
  String zoneStatusAtText(String zoneName, String duration);

  /// No description provided for @zoneStatusWasAtText.
  ///
  /// In en, this message translates to:
  /// **'was at {zoneName}'**
  String zoneStatusWasAtText(String zoneName);

  /// No description provided for @zoneStatusWasAtWithAgoText.
  ///
  /// In en, this message translates to:
  /// **'was at {zoneName} • {ago}'**
  String zoneStatusWasAtWithAgoText(String zoneName, String ago);

  /// No description provided for @zoneStatusDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String zoneStatusDurationMinutes(int minutes);

  /// No description provided for @zoneStatusDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String zoneStatusDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @zoneStatusJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get zoneStatusJustNow;

  /// No description provided for @zoneStatusMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String zoneStatusMinutesAgo(int minutes);

  /// No description provided for @zoneStatusHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String zoneStatusHoursAgo(int hours);

  /// No description provided for @zoneStatusDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String zoneStatusDaysAgo(int days);

  /// No description provided for @otpResendCooldownError.
  ///
  /// In en, this message translates to:
  /// **'Please wait before requesting another OTP'**
  String get otpResendCooldownError;

  /// No description provided for @otpResendLockedError.
  ///
  /// In en, this message translates to:
  /// **'You requested OTP too many times. Please try again later'**
  String get otpResendLockedError;

  /// No description provided for @otpResendMaxError.
  ///
  /// In en, this message translates to:
  /// **'You requested OTP too many times'**
  String get otpResendMaxError;

  /// No description provided for @otpRepositoryLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'OTP sending is temporarily locked. Please try again in {seconds}s'**
  String otpRepositoryLockedMessage(int seconds);

  /// No description provided for @authLoginCancelled.
  ///
  /// In en, this message translates to:
  /// **'Login was cancelled'**
  String get authLoginCancelled;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @zoneDetailsRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Radius {radius}m'**
  String zoneDetailsRadiusLabel(String radius);

  /// No description provided for @zoneDetailsNoCoordinates.
  ///
  /// In en, this message translates to:
  /// **'No coordinates available to display the map'**
  String get zoneDetailsNoCoordinates;

  /// No description provided for @birthdaySpecialDayHeadline.
  ///
  /// In en, this message translates to:
  /// **'It\'s {name}\'s special day!'**
  String birthdaySpecialDayHeadline(String name);

  /// No description provided for @mapTopBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get mapTopBarTitle;

  /// No description provided for @childGroupMarkerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} children'**
  String childGroupMarkerCount(int count);

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get changePasswordSuccessMessage;

  /// No description provided for @changePasswordCurrentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentPasswordLabel;

  /// No description provided for @changePasswordCurrentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get changePasswordCurrentPasswordHint;

  /// No description provided for @changePasswordNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNewPasswordLabel;

  /// No description provided for @changePasswordNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get changePasswordNewPasswordHint;

  /// No description provided for @changePasswordConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get changePasswordConfirmPasswordLabel;

  /// No description provided for @changePasswordConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get changePasswordConfirmPasswordHint;

  /// No description provided for @changePasswordUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get changePasswordUpdateButton;

  /// No description provided for @memberManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Member management'**
  String get memberManagementTitle;

  /// No description provided for @memberManagementAddMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get memberManagementAddMemberTitle;

  /// No description provided for @memberManagementAddMemberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect a new device for your child'**
  String get memberManagementAddMemberSubtitle;

  /// No description provided for @memberManagementAddNowButton.
  ///
  /// In en, this message translates to:
  /// **'Add now'**
  String get memberManagementAddNowButton;

  /// No description provided for @memberManagementFamilyMembersLabel.
  ///
  /// In en, this message translates to:
  /// **'FAMILY MEMBERS'**
  String get memberManagementFamilyMembersLabel;

  /// No description provided for @memberManagementEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get memberManagementEmpty;

  /// No description provided for @memberManagementOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get memberManagementOnline;

  /// No description provided for @memberManagementOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get memberManagementOffline;

  /// No description provided for @memberManagementMessageButton.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get memberManagementMessageButton;

  /// No description provided for @memberManagementLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get memberManagementLocationButton;

  /// No description provided for @userRoleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get userRoleParent;

  /// No description provided for @userRoleChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get userRoleChild;

  /// No description provided for @userRoleGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get userRoleGuardian;

  /// No description provided for @aboutAppName.
  ///
  /// In en, this message translates to:
  /// **'My Application'**
  String get aboutAppName;

  /// No description provided for @aboutAppVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String aboutAppVersionLabel(String version);

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'This app helps manage accounts, track activity, and personalize the user experience.'**
  String get aboutAppDescription;

  /// No description provided for @aboutAppCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 My Company'**
  String get aboutAppCopyright;

  /// No description provided for @themeSelectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize appearance'**
  String get themeSelectorTitle;

  /// No description provided for @themeSelectorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the primary color and light/dark mode'**
  String get themeSelectorSubtitle;

  /// No description provided for @themeSelectorDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get themeSelectorDarkMode;

  /// No description provided for @themeSelectorApplyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply appearance'**
  String get themeSelectorApplyButton;

  /// No description provided for @phoneAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Login with phone number'**
  String get phoneAuthTitle;

  /// No description provided for @phoneAuthSendOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get phoneAuthSendOtpButton;

  /// No description provided for @phoneAuthOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get phoneAuthOtpTitle;

  /// No description provided for @phoneAuthOtpInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please enter the OTP sent to your phone number'**
  String get phoneAuthOtpInstruction;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsTitle;

  /// No description provided for @termsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get termsNoData;

  /// No description provided for @termsLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String termsLastUpdated(String date);

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get homeGreeting;

  /// No description provided for @homeManageChildButton.
  ///
  /// In en, this message translates to:
  /// **'Manage child'**
  String get homeManageChildButton;

  /// No description provided for @accountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get accountNotFound;

  /// No description provided for @accountNotActivated.
  ///
  /// In en, this message translates to:
  /// **'Account not activated'**
  String get accountNotActivated;

  /// No description provided for @emailNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email not registered'**
  String get emailNotRegistered;

  /// No description provided for @noLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'No location permission'**
  String get noLocationPermission;

  /// No description provided for @gpsError.
  ///
  /// In en, this message translates to:
  /// **'GPS error'**
  String get gpsError;

  /// No description provided for @currentLocationError.
  ///
  /// In en, this message translates to:
  /// **'Cannot get current location'**
  String get currentLocationError;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @codeExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired'**
  String get codeExpired;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts'**
  String get tooManyAttempts;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get unknownError;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Weak password'**
  String get weakPassword;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalid;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get emailInUse;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @authStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get authStartTitle;

  /// No description provided for @authStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue with the app now!'**
  String get authStartSubtitle;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get authContinueWithFacebook;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authContinueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with phone number'**
  String get authContinueWithPhone;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginButton;

  /// No description provided for @authSignupButton.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignupButton;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsOfService;

  /// No description provided for @authEnterAllInfo.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required information'**
  String get authEnterAllInfo;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect account information'**
  String get authInvalidCredentials;

  /// No description provided for @authUserProfileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user profile'**
  String get authUserProfileLoadFailed;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get authGenericError;

  /// No description provided for @authWelcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get authWelcomeBackTitle;

  /// No description provided for @authLoginNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login now!'**
  String get authLoginNowSubtitle;

  /// No description provided for @authEnterEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get authEnterEmailHint;

  /// No description provided for @authEnterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get authEnterPasswordHint;

  /// No description provided for @authRememberPassword.
  ///
  /// In en, this message translates to:
  /// **'Remember password'**
  String get authRememberPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get authOr;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have an account, '**
  String get authNoAccount;

  /// No description provided for @authSignUpInline.
  ///
  /// In en, this message translates to:
  /// **'sign up'**
  String get authSignUpInline;

  /// No description provided for @authSignupTitle.
  ///
  /// In en, this message translates to:
  /// **'CREATE\nACCOUNT NOW'**
  String get authSignupTitle;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor and manage your kids!'**
  String get authSignupSubtitle;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Password confirmation does not match'**
  String get authPasswordMismatch;

  /// No description provided for @authSignupFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed'**
  String get authSignupFailed;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authAgreeTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Agree to terms, '**
  String get authAgreeTermsPrefix;

  /// No description provided for @authAgreeTermsLink.
  ///
  /// In en, this message translates to:
  /// **'here'**
  String get authAgreeTermsLink;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'You already have an account, '**
  String get authHaveAccount;

  /// No description provided for @authLoginInline.
  ///
  /// In en, this message translates to:
  /// **'login'**
  String get authLoginInline;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'FORGOT PASSWORD?'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Did you forget your password? Follow the steps below to recover it.'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authEnterYourEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEnterYourEmailLabel;

  /// No description provided for @authContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinueButton;

  /// No description provided for @authSendOtpFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP'**
  String get authSendOtpFailed;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'ENTER OTP CODE'**
  String get otpTitle;

  /// No description provided for @otpInstruction.
  ///
  /// In en, this message translates to:
  /// **'We have sent a verification code to your email address'**
  String get otpInstruction;

  /// No description provided for @otpNeed4Digits.
  ///
  /// In en, this message translates to:
  /// **'Please enter all 4 OTP digits'**
  String get otpNeed4Digits;

  /// No description provided for @otpDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'OTP must contain digits only'**
  String get otpDigitsOnly;

  /// No description provided for @otpIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect OTP'**
  String get otpIncorrect;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'OTP has expired'**
  String get otpExpired;

  /// No description provided for @otpTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'You have entered incorrectly more than 3 times. Please wait 10 minutes.'**
  String get otpTooManyAttempts;

  /// No description provided for @otpRequestNotFound.
  ///
  /// In en, this message translates to:
  /// **'OTP request not found'**
  String get otpRequestNotFound;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String otpResendIn(int seconds);

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerifyButton;

  /// No description provided for @authRegisterSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Account registered successfully'**
  String get authRegisterSuccessMessage;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'RESET\nNEW PASSWORD'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password!'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetPasswordNewLabel;

  /// No description provided for @resetPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get resetPasswordConfirmLabel;

  /// No description provided for @resetPasswordConfirmMismatch.
  ///
  /// In en, this message translates to:
  /// **'Re-entered password does not match'**
  String get resetPasswordConfirmMismatch;

  /// No description provided for @resetPasswordRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Password requirements'**
  String get resetPasswordRuleTitle;

  /// No description provided for @resetPasswordRuleMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get resetPasswordRuleMinLength;

  /// No description provided for @resetPasswordRuleUppercase.
  ///
  /// In en, this message translates to:
  /// **'Contains uppercase letters'**
  String get resetPasswordRuleUppercase;

  /// No description provided for @resetPasswordRuleLowercase.
  ///
  /// In en, this message translates to:
  /// **'Contains lowercase letters'**
  String get resetPasswordRuleLowercase;

  /// No description provided for @resetPasswordRuleNumber.
  ///
  /// In en, this message translates to:
  /// **'Contains numbers'**
  String get resetPasswordRuleNumber;

  /// No description provided for @resetPasswordCompleteButton.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get resetPasswordCompleteButton;

  /// No description provided for @resetPasswordSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get resetPasswordSuccessMessage;

  /// No description provided for @authCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed!'**
  String get authCompleteTitle;

  /// No description provided for @authRegisterCongratsMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You have registered successfully'**
  String get authRegisterCongratsMessage;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get authBackToLogin;

  /// No description provided for @flashWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the app'**
  String get flashWelcomeTitle;

  /// No description provided for @flashWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Child tracking application'**
  String get flashWelcomeSubtitle;

  /// No description provided for @flashNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get flashNext;

  /// No description provided for @scheduleScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleScreenTitle;

  /// No description provided for @scheduleNoChild.
  ///
  /// In en, this message translates to:
  /// **'No child yet'**
  String get scheduleNoChild;

  /// No description provided for @scheduleFormTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Schedule title'**
  String get scheduleFormTitleHint;

  /// No description provided for @scheduleFormDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get scheduleFormDescriptionHint;

  /// No description provided for @scheduleAddHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get scheduleAddHeaderTitle;

  /// No description provided for @scheduleFormDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get scheduleFormDateLabel;

  /// No description provided for @scheduleFormStartTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get scheduleFormStartTimeLabel;

  /// No description provided for @scheduleFormEndTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get scheduleFormEndTimeLabel;

  /// No description provided for @scheduleFormEndTimeInvalid.
  ///
  /// In en, this message translates to:
  /// **'End time must be later'**
  String get scheduleFormEndTimeInvalid;

  /// No description provided for @scheduleFormSavingButton.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get scheduleFormSavingButton;

  /// No description provided for @scheduleAddSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Create schedule'**
  String get scheduleAddSubmitButton;

  /// No description provided for @scheduleAddSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Schedule created successfully'**
  String get scheduleAddSuccessMessage;

  /// No description provided for @scheduleDialogWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get scheduleDialogWarningTitle;

  /// No description provided for @scheduleEditHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit schedule'**
  String get scheduleEditHeaderTitle;

  /// No description provided for @scheduleEditSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Save schedule'**
  String get scheduleEditSubmitButton;

  /// No description provided for @scheduleEditSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated successfully'**
  String get scheduleEditSuccessMessage;

  /// No description provided for @scheduleSelectChildLabel.
  ///
  /// In en, this message translates to:
  /// **'Select child'**
  String get scheduleSelectChildLabel;

  /// No description provided for @scheduleYourChild.
  ///
  /// In en, this message translates to:
  /// **'Your child'**
  String get scheduleYourChild;

  /// No description provided for @schedulePleaseSelectChild.
  ///
  /// In en, this message translates to:
  /// **'Please select a child'**
  String get schedulePleaseSelectChild;

  /// No description provided for @scheduleExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get scheduleExportTitle;

  /// No description provided for @scheduleExportDateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get scheduleExportDateRangeLabel;

  /// No description provided for @scheduleExportColumnsHint.
  ///
  /// In en, this message translates to:
  /// **'Export file includes columns: title, description, date, start, end'**
  String get scheduleExportColumnsHint;

  /// No description provided for @scheduleExportLoadingButton.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get scheduleExportLoadingButton;

  /// No description provided for @scheduleExportSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Export file'**
  String get scheduleExportSubmitButton;

  /// No description provided for @scheduleExportInvalidDateRange.
  ///
  /// In en, this message translates to:
  /// **'Start date cannot be after end date'**
  String get scheduleExportInvalidDateRange;

  /// No description provided for @scheduleExportNoDataInRange.
  ///
  /// In en, this message translates to:
  /// **'No schedules in selected range'**
  String get scheduleExportNoDataInRange;

  /// No description provided for @scheduleExportSaveCanceled.
  ///
  /// In en, this message translates to:
  /// **'File save was canceled'**
  String get scheduleExportSaveCanceled;

  /// No description provided for @scheduleExportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Excel export successful ({count} schedules)'**
  String scheduleExportSuccessMessage(int count);

  /// No description provided for @scheduleExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String scheduleExportFailed(String error);

  /// No description provided for @scheduleImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Excel'**
  String get scheduleImportTitle;

  /// No description provided for @scheduleTemplateDownloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download template'**
  String get scheduleTemplateDownloadButton;

  /// No description provided for @scheduleTemplateSaveCanceled.
  ///
  /// In en, this message translates to:
  /// **'Template save was canceled'**
  String get scheduleTemplateSaveCanceled;

  /// No description provided for @scheduleTemplateSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Template saved successfully'**
  String get scheduleTemplateSavedSuccess;

  /// No description provided for @scheduleTemplateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Template download failed: {error}'**
  String scheduleTemplateDownloadFailed(String error);

  /// No description provided for @scheduleImportCannotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot read file, please try again'**
  String get scheduleImportCannotReadFile;

  /// No description provided for @scheduleImportMissingOwner.
  ///
  /// In en, this message translates to:
  /// **'Cannot determine schedule owner'**
  String get scheduleImportMissingOwner;

  /// No description provided for @scheduleImportNoValidItems.
  ///
  /// In en, this message translates to:
  /// **'No valid schedules to import'**
  String get scheduleImportNoValidItems;

  /// No description provided for @scheduleImportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Schedules imported successfully'**
  String get scheduleImportSuccessMessage;

  /// No description provided for @scheduleImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String scheduleImportFailed(String error);

  /// No description provided for @scheduleImportAddCount.
  ///
  /// In en, this message translates to:
  /// **'Add {count} schedules'**
  String scheduleImportAddCount(int count);

  /// No description provided for @scheduleImportPickFileButton.
  ///
  /// In en, this message translates to:
  /// **'Choose Excel file'**
  String get scheduleImportPickFileButton;

  /// No description provided for @scheduleImportPickAnotherFileButton.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get scheduleImportPickAnotherFileButton;

  /// No description provided for @scheduleImportSelectedFile.
  ///
  /// In en, this message translates to:
  /// **'Selected: {fileName}'**
  String scheduleImportSelectedFile(String fileName);

  /// No description provided for @scheduleImportChangeFileButton.
  ///
  /// In en, this message translates to:
  /// **'Change file'**
  String get scheduleImportChangeFileButton;

  /// No description provided for @scheduleImportSummaryOk.
  ///
  /// In en, this message translates to:
  /// **'OK: {count}'**
  String scheduleImportSummaryOk(int count);

  /// No description provided for @scheduleImportSummaryDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate: {count}'**
  String scheduleImportSummaryDuplicate(int count);

  /// No description provided for @scheduleImportSummaryError.
  ///
  /// In en, this message translates to:
  /// **'Error: {count}'**
  String scheduleImportSummaryError(int count);

  /// No description provided for @scheduleImportPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview data'**
  String get scheduleImportPreviewTitle;

  /// No description provided for @scheduleImportStatusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get scheduleImportStatusOk;

  /// No description provided for @scheduleImportStatusError.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get scheduleImportStatusError;

  /// No description provided for @scheduleImportStatusDuplicate.
  ///
  /// In en, this message translates to:
  /// **'DUPLICATE'**
  String get scheduleImportStatusDuplicate;

  /// No description provided for @scheduleImportRowError.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {error}'**
  String scheduleImportRowError(int row, String error);

  /// No description provided for @birthdayMemberFallback.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get birthdayMemberFallback;

  /// No description provided for @birthdayWishSelfWithAge.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday to me. Welcome {age} with joy, peace, and beautiful moments.'**
  String birthdayWishSelfWithAge(int age);

  /// No description provided for @birthdayWishSelfDefault.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday to me. Wishing myself a joyful and memorable day.'**
  String get birthdayWishSelfDefault;

  /// No description provided for @birthdayWishOtherWithAge.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday, {name}. Wishing you a healthy, joyful, and lucky year at {age}.'**
  String birthdayWishOtherWithAge(String name, int age);

  /// No description provided for @birthdayWishOtherDefault.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday, {name}. Wishing you joy, good health, and lots of happy moments.'**
  String birthdayWishOtherDefault(String name);

  /// No description provided for @birthdayViewWishButton.
  ///
  /// In en, this message translates to:
  /// **'View wish'**
  String get birthdayViewWishButton;

  /// No description provided for @birthdaySendWishButton.
  ///
  /// In en, this message translates to:
  /// **'Send wishes'**
  String get birthdaySendWishButton;

  /// No description provided for @birthdayCongratsYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday to you'**
  String get birthdayCongratsYouTitle;

  /// No description provided for @birthdayCongratsTitle.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday'**
  String get birthdayCongratsTitle;

  /// No description provided for @birthdayTodayIsYourDay.
  ///
  /// In en, this message translates to:
  /// **'Today is your day'**
  String get birthdayTodayIsYourDay;

  /// No description provided for @birthdayTurnsAge.
  ///
  /// In en, this message translates to:
  /// **'Turning {age}'**
  String birthdayTurnsAge(int age);

  /// No description provided for @birthdaySuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested wish'**
  String get birthdaySuggestionTitle;

  /// No description provided for @birthdayYouEnteringAge.
  ///
  /// In en, this message translates to:
  /// **'Today you turn {age}. Wishing you a gentle, joyful, and memorable day.'**
  String birthdayYouEnteringAge(int age);

  /// No description provided for @birthdayYouSpecialDay.
  ///
  /// In en, this message translates to:
  /// **'Today is your special day. Wishing you lots of joy and positive energy.'**
  String get birthdayYouSpecialDay;

  /// No description provided for @birthdayTodayIsBirthdayWithAge.
  ///
  /// In en, this message translates to:
  /// **'Today is {name}\'s birthday, turning {age}.'**
  String birthdayTodayIsBirthdayWithAge(String name, int age);

  /// No description provided for @birthdayTodayIsBirthday.
  ///
  /// In en, this message translates to:
  /// **'Today is {name}\'s birthday.'**
  String birthdayTodayIsBirthday(String name);

  /// No description provided for @birthdayCountdownTitle.
  ///
  /// In en, this message translates to:
  /// **'✨ Upcoming birthday'**
  String get birthdayCountdownTitle;

  /// No description provided for @birthdayCountdownSelfTitle.
  ///
  /// In en, this message translates to:
  /// **'✨ Your birthday is coming'**
  String get birthdayCountdownSelfTitle;

  /// No description provided for @birthdayCountdownTomorrowChip.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get birthdayCountdownTomorrowChip;

  /// No description provided for @birthdayCountdownDaysChip.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String birthdayCountdownDaysChip(int days);

  /// No description provided for @birthdayCountdownOtherBody.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s birthday is in {days} days.'**
  String birthdayCountdownOtherBody(String name, int days);

  /// No description provided for @birthdayCountdownOtherBodyTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is {name}\'s birthday.'**
  String birthdayCountdownOtherBodyTomorrow(String name);

  /// No description provided for @birthdayCountdownSelfBody.
  ///
  /// In en, this message translates to:
  /// **'Your birthday is in {days} days.'**
  String birthdayCountdownSelfBody(int days);

  /// No description provided for @birthdayCountdownSelfBodyTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is your birthday.'**
  String get birthdayCountdownSelfBodyTomorrow;

  /// No description provided for @birthdayCountdownSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparation ideas'**
  String get birthdayCountdownSuggestionTitle;

  /// No description provided for @birthdayCountdownSuggestionOther.
  ///
  /// In en, this message translates to:
  /// **'You can prepare a wish, a gift, or a little surprise for {name} starting now.'**
  String birthdayCountdownSuggestionOther(String name);

  /// No description provided for @birthdayCountdownSuggestionSelf.
  ///
  /// In en, this message translates to:
  /// **'You can prepare a wish, a small gift, or a little surprise for yourself starting now.'**
  String get birthdayCountdownSuggestionSelf;

  /// No description provided for @birthdayCountdownPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Prepare wish'**
  String get birthdayCountdownPlanButton;

  /// No description provided for @birthdayCopiedFallback.
  ///
  /// In en, this message translates to:
  /// **'Family chat was not found. The birthday wish for {name} has been copied.'**
  String birthdayCopiedFallback(String name);

  /// No description provided for @birthdayCloseButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get birthdayCloseButton;

  /// No description provided for @birthdayAwesomeButton.
  ///
  /// In en, this message translates to:
  /// **'Awesome'**
  String get birthdayAwesomeButton;

  /// No description provided for @familyChatLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading chat'**
  String get familyChatLoadingTitle;

  /// No description provided for @familyChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Family group chat'**
  String get familyChatTitle;

  /// No description provided for @familyChatTitleLarge.
  ///
  /// In en, this message translates to:
  /// **'Family Group Chat'**
  String get familyChatTitleLarge;

  /// No description provided for @familyChatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String familyChatSendFailed(String error);

  /// No description provided for @familyChatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get familyChatYou;

  /// No description provided for @familyChatMemberFallback.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get familyChatMemberFallback;

  /// No description provided for @familyChatLoadingMembers.
  ///
  /// In en, this message translates to:
  /// **'Loading members...'**
  String get familyChatLoadingMembers;

  /// No description provided for @familyChatNoMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get familyChatNoMembersFound;

  /// No description provided for @familyChatOneMember.
  ///
  /// In en, this message translates to:
  /// **'1 member'**
  String get familyChatOneMember;

  /// No description provided for @familyChatManyMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String familyChatManyMembers(int count);

  /// No description provided for @familyChatCannotLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Cannot load messages'**
  String get familyChatCannotLoadMessages;

  /// No description provided for @familyChatNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Start the conversation.'**
  String get familyChatNoMessagesYet;

  /// No description provided for @familyChatStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get familyChatStatusFailed;

  /// No description provided for @familyChatStatusSending.
  ///
  /// In en, this message translates to:
  /// **'sending...'**
  String get familyChatStatusSending;

  /// No description provided for @familyChatTypeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get familyChatTypeMessageHint;

  /// No description provided for @familyChatMemberCountOverflow.
  ///
  /// In en, this message translates to:
  /// **'{names} +{extra}'**
  String familyChatMemberCountOverflow(String names, int extra);

  /// No description provided for @notificationScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationScreenTitle;

  /// No description provided for @notificationDateToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get notificationDateToday;

  /// No description provided for @notificationDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get notificationDateYesterday;

  /// No description provided for @notificationFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter notifications'**
  String get notificationFilterTitle;

  /// No description provided for @notificationFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationFilterAll;

  /// No description provided for @notificationFilterActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get notificationFilterActivity;

  /// No description provided for @notificationFilterAlert.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get notificationFilterAlert;

  /// No description provided for @notificationFilterReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notificationFilterReminder;

  /// No description provided for @notificationFilterSystem.
  ///
  /// In en, this message translates to:
  /// **'System notifications'**
  String get notificationFilterSystem;

  /// No description provided for @notificationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notifications'**
  String get notificationSearchHint;

  /// No description provided for @notificationJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationJustNow;

  /// No description provided for @notificationMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String notificationMinutesAgo(int minutes);

  /// No description provided for @notificationHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String notificationHoursAgo(int hours);

  /// No description provided for @notificationDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification details'**
  String get notificationDetailTitle;

  /// No description provided for @notificationDetailSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get notificationDetailSectionTitle;

  /// No description provided for @notificationChildFallback.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get notificationChildFallback;

  /// No description provided for @notificationChildInfoNotFound.
  ///
  /// In en, this message translates to:
  /// **'Child information could not be found'**
  String get notificationChildInfoNotFound;

  /// No description provided for @notificationMapLocationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location could not be found to open the map'**
  String get notificationMapLocationNotFound;

  /// No description provided for @notificationScheduleCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'New schedule for {childName}'**
  String notificationScheduleCreatedTitle(String childName);

  /// No description provided for @notificationScheduleUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'{childName}\'s schedule has changed'**
  String notificationScheduleUpdatedTitle(String childName);

  /// No description provided for @notificationScheduleDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'{childName}\'s schedule was deleted'**
  String notificationScheduleDeletedTitle(String childName);

  /// No description provided for @notificationScheduleRestoredTitle.
  ///
  /// In en, this message translates to:
  /// **'{childName}\'s schedule was restored'**
  String notificationScheduleRestoredTitle(String childName);

  /// No description provided for @notificationZoneEnteredDangerTitle.
  ///
  /// In en, this message translates to:
  /// **'{childName} entered a danger zone'**
  String notificationZoneEnteredDangerTitle(String childName);

  /// No description provided for @notificationZoneExitedSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'{childName} left a safe zone'**
  String notificationZoneExitedSafeTitle(String childName);

  /// No description provided for @notificationZoneExitedDangerTitle.
  ///
  /// In en, this message translates to:
  /// **'{childName} left a danger zone'**
  String notificationZoneExitedDangerTitle(String childName);

  /// No description provided for @scheduleImportRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {title}'**
  String scheduleImportRowTitle(int row, String title);

  /// No description provided for @scheduleImportDuplicateInSystem.
  ///
  /// In en, this message translates to:
  /// **'Duplicate with existing system data'**
  String get scheduleImportDuplicateInSystem;

  /// No description provided for @scheduleImportDuplicateInFile.
  ///
  /// In en, this message translates to:
  /// **'Duplicate within file'**
  String get scheduleImportDuplicateInFile;

  /// No description provided for @scheduleHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit history'**
  String get scheduleHistoryTitle;

  /// No description provided for @scheduleHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No edit history yet'**
  String get scheduleHistoryEmpty;

  /// No description provided for @scheduleHistoryToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get scheduleHistoryToday;

  /// No description provided for @scheduleHistoryYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get scheduleHistoryYesterday;

  /// No description provided for @scheduleHistoryRestoreDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore schedule'**
  String get scheduleHistoryRestoreDialogTitle;

  /// No description provided for @scheduleHistoryRestoreDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore this version?'**
  String get scheduleHistoryRestoreDialogMessage;

  /// No description provided for @scheduleHistoryRestoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get scheduleHistoryRestoreButton;

  /// No description provided for @scheduleHistoryRestoringButton.
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get scheduleHistoryRestoringButton;

  /// No description provided for @scheduleHistoryRestoreSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Schedule restored successfully'**
  String get scheduleHistoryRestoreSuccessMessage;

  /// No description provided for @scheduleHistoryRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String scheduleHistoryRestoreFailed(String error);

  /// No description provided for @scheduleHistoryEditedAt.
  ///
  /// In en, this message translates to:
  /// **'Edited at {time}'**
  String scheduleHistoryEditedAt(String time);

  /// No description provided for @scheduleHistoryLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule title:'**
  String get scheduleHistoryLabelTitle;

  /// No description provided for @scheduleHistoryLabelDescription.
  ///
  /// In en, this message translates to:
  /// **'Description:'**
  String get scheduleHistoryLabelDescription;

  /// No description provided for @scheduleHistoryLabelDate.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get scheduleHistoryLabelDate;

  /// No description provided for @scheduleHistoryLabelTime.
  ///
  /// In en, this message translates to:
  /// **'Time:'**
  String get scheduleHistoryLabelTime;

  /// No description provided for @scheduleDrawerMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get scheduleDrawerMenuTitle;

  /// No description provided for @scheduleCreateButtonAddEvent.
  ///
  /// In en, this message translates to:
  /// **'+ Add event'**
  String get scheduleCreateButtonAddEvent;

  /// No description provided for @schedulePeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get schedulePeriodTitle;

  /// No description provided for @schedulePeriodMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get schedulePeriodMorning;

  /// No description provided for @schedulePeriodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get schedulePeriodAfternoon;

  /// No description provided for @schedulePeriodEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get schedulePeriodEvening;

  /// No description provided for @scheduleCalendarFormatMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get scheduleCalendarFormatMonth;

  /// No description provided for @scheduleCalendarFormatWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get scheduleCalendarFormatWeek;

  /// No description provided for @scheduleCalendarMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month {month}'**
  String scheduleCalendarMonthLabel(int month);

  /// No description provided for @scheduleWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get scheduleWeekdayMon;

  /// No description provided for @scheduleWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get scheduleWeekdayTue;

  /// No description provided for @scheduleWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get scheduleWeekdayWed;

  /// No description provided for @scheduleWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get scheduleWeekdayThu;

  /// No description provided for @scheduleWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get scheduleWeekdayFri;

  /// No description provided for @scheduleWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get scheduleWeekdaySat;

  /// No description provided for @scheduleWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get scheduleWeekdaySun;

  /// No description provided for @scheduleNoEventsInDay.
  ///
  /// In en, this message translates to:
  /// **'No schedules for this day'**
  String get scheduleNoEventsInDay;

  /// No description provided for @scheduleDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule'**
  String get scheduleDeleteTitle;

  /// No description provided for @scheduleDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get scheduleDeleteConfirmMessage;

  /// No description provided for @scheduleDeleteSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get scheduleDeleteSuccessMessage;

  /// No description provided for @scheduleDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String scheduleDeleteFailed(String error);

  /// No description provided for @memoryDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Memorable days'**
  String get memoryDayTitle;

  /// No description provided for @memoryDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'No memorable days yet'**
  String get memoryDayEmpty;

  /// No description provided for @memoryDayDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete memorable day'**
  String get memoryDayDeleteTitle;

  /// No description provided for @memoryDayDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get memoryDayDeleteConfirmMessage;

  /// No description provided for @memoryDayDeleteSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get memoryDayDeleteSuccessMessage;

  /// No description provided for @memoryDayDeleteFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete failed, please try again'**
  String get memoryDayDeleteFailedMessage;

  /// No description provided for @memoryDayDeleteFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String memoryDayDeleteFailedWithError(String error);

  /// No description provided for @memoryDayDaysPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed {days} days'**
  String memoryDayDaysPassed(int days);

  /// No description provided for @memoryDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get memoryDayToday;

  /// No description provided for @memoryDayDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String memoryDayDaysLeft(int days);

  /// No description provided for @memoryDayDateText.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String memoryDayDateText(String date);

  /// No description provided for @memoryDayDateRepeatText.
  ///
  /// In en, this message translates to:
  /// **'Date: {date} (repeats yearly)'**
  String memoryDayDateRepeatText(String date);

  /// No description provided for @memoryDayUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get memoryDayUnsavedTitle;

  /// No description provided for @memoryDayUnsavedExitMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to exit?'**
  String get memoryDayUnsavedExitMessage;

  /// No description provided for @memoryDayFormTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get memoryDayFormTitleLabel;

  /// No description provided for @memoryDayFormDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get memoryDayFormDateLabel;

  /// No description provided for @memoryDayFormNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get memoryDayFormNoteLabel;

  /// No description provided for @memoryDayReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Remind before'**
  String get memoryDayReminderLabel;

  /// No description provided for @memoryDayReminderNone.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get memoryDayReminderNone;

  /// No description provided for @memoryDayReminderOneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get memoryDayReminderOneDay;

  /// No description provided for @memoryDayReminderThreeDays.
  ///
  /// In en, this message translates to:
  /// **'3 days before'**
  String get memoryDayReminderThreeDays;

  /// No description provided for @memoryDayReminderSevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 days before'**
  String get memoryDayReminderSevenDays;

  /// No description provided for @memoryDayRepeatYearlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat yearly'**
  String get memoryDayRepeatYearlyLabel;

  /// No description provided for @memoryDayEditHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit memorable day'**
  String get memoryDayEditHeaderTitle;

  /// No description provided for @memoryDayAddHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Add memorable day'**
  String get memoryDayAddHeaderTitle;

  /// No description provided for @memoryDayEditSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully'**
  String get memoryDayEditSuccessMessage;

  /// No description provided for @memoryDayAddSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Memorable day added successfully'**
  String get memoryDayAddSuccessMessage;

  /// No description provided for @memoryDaySaveFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again'**
  String get memoryDaySaveFailedMessage;

  /// No description provided for @memoryDaySavingButton.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get memoryDaySavingButton;

  /// No description provided for @memoryDaySaveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get memoryDaySaveChangesButton;

  /// No description provided for @memoryDayAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add memorable day'**
  String get memoryDayAddButton;

  /// No description provided for @memoryDayEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get memoryDayEditAction;

  /// No description provided for @memoryDayDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get memoryDayDeleteAction;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'New notifications will appear here'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsDefaultChildName.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get notificationsDefaultChildName;

  /// No description provided for @notificationsNoTitle.
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get notificationsNoTitle;

  /// No description provided for @notificationsActionCreated.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get notificationsActionCreated;

  /// No description provided for @notificationsActionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get notificationsActionUpdated;

  /// No description provided for @notificationsActionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get notificationsActionDeleted;

  /// No description provided for @notificationsActionRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get notificationsActionRestored;

  /// No description provided for @notificationsActionChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get notificationsActionChanged;

  /// No description provided for @notificationsScheduleTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule title'**
  String get notificationsScheduleTitleLabel;

  /// No description provided for @notificationsChildNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Child name'**
  String get notificationsChildNameLabel;

  /// No description provided for @notificationsDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get notificationsDateLabel;

  /// No description provided for @notificationsTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get notificationsTimeLabel;

  /// No description provided for @notificationsViewScheduleButton.
  ///
  /// In en, this message translates to:
  /// **'View schedule'**
  String get notificationsViewScheduleButton;

  /// No description provided for @notificationsRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get notificationsRepeatLabel;

  /// No description provided for @notificationsRepeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get notificationsRepeatYearly;

  /// No description provided for @notificationsRepeatNone.
  ///
  /// In en, this message translates to:
  /// **'No repeat'**
  String get notificationsRepeatNone;

  /// No description provided for @notificationsImportOperatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get notificationsImportOperatorLabel;

  /// No description provided for @notificationsChildLabel.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get notificationsChildLabel;

  /// No description provided for @notificationsImportAddedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedules added'**
  String get notificationsImportAddedCountLabel;

  /// No description provided for @notificationsActorParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get notificationsActorParent;

  /// No description provided for @notificationsActorChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get notificationsActorChild;

  /// No description provided for @notificationsBlockedAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get notificationsBlockedAccountLabel;

  /// No description provided for @notificationsBlockedAppLabel.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get notificationsBlockedAppLabel;

  /// No description provided for @notificationsBlockedTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get notificationsBlockedTimeLabel;

  /// No description provided for @notificationsBlockedAllowedWindowLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowed time window'**
  String get notificationsBlockedAllowedWindowLabel;

  /// No description provided for @notificationsBlockedWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'The app was automatically blocked by the system.'**
  String get notificationsBlockedWarningMessage;

  /// No description provided for @notificationsBlockedViewConfigButton.
  ///
  /// In en, this message translates to:
  /// **'View time configuration'**
  String get notificationsBlockedViewConfigButton;

  /// No description provided for @notificationsRemovedDeviceOfLabel.
  ///
  /// In en, this message translates to:
  /// **'Device of'**
  String get notificationsRemovedDeviceOfLabel;

  /// No description provided for @notificationsRemovedAppLabel.
  ///
  /// In en, this message translates to:
  /// **'Removed app'**
  String get notificationsRemovedAppLabel;

  /// No description provided for @notificationsRemovedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Removed at'**
  String get notificationsRemovedAtLabel;

  /// No description provided for @notificationsRemovedWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'The app was removed from the device. Please check if this is a managed app.'**
  String get notificationsRemovedWarningMessage;

  /// No description provided for @notificationsRemovedViewAppsButton.
  ///
  /// In en, this message translates to:
  /// **'View app list'**
  String get notificationsRemovedViewAppsButton;

  /// No description provided for @notificationsZoneDangerEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'{childName}\'s location was recorded at {zoneName}. The system detected entry into a danger zone at {time}.'**
  String notificationsZoneDangerEnterDescription(
    String childName,
    String zoneName,
    String time,
  );

  /// No description provided for @notificationsZoneSafeExitDescription.
  ///
  /// In en, this message translates to:
  /// **'{childName}\'s location was recorded at {zoneName}. The system detected exit from a safe zone at {time}.'**
  String notificationsZoneSafeExitDescription(
    String childName,
    String zoneName,
    String time,
  );

  /// No description provided for @notificationsZoneDangerExitDescription.
  ///
  /// In en, this message translates to:
  /// **'{childName}\'s location was recorded at {zoneName}. The system detected exit from a danger zone at {time}.'**
  String notificationsZoneDangerExitDescription(
    String childName,
    String zoneName,
    String time,
  );

  /// No description provided for @notificationsZoneUpdatedDescription.
  ///
  /// In en, this message translates to:
  /// **'{childName}\'s location was updated at {zoneName}.'**
  String notificationsZoneUpdatedDescription(String childName, String zoneName);

  /// No description provided for @notificationsZoneViewOnMainMapButton.
  ///
  /// In en, this message translates to:
  /// **'View on main map'**
  String get notificationsZoneViewOnMainMapButton;

  /// No description provided for @notificationsContactNowButton.
  ///
  /// In en, this message translates to:
  /// **'Contact now'**
  String get notificationsContactNowButton;

  /// No description provided for @notificationsLocalChannelName.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get notificationsLocalChannelName;

  /// No description provided for @notificationsLocalChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Default notifications'**
  String get notificationsLocalChannelDescription;

  /// No description provided for @notificationsDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsDefaultTitle;

  /// No description provided for @notificationsDefaultBody.
  ///
  /// In en, this message translates to:
  /// **'You have a new notification'**
  String get notificationsDefaultBody;

  /// No description provided for @notificationsFamilyChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Family chat'**
  String get notificationsFamilyChatTitle;

  /// No description provided for @notificationsFamilyChatBody.
  ///
  /// In en, this message translates to:
  /// **'You have a new message'**
  String get notificationsFamilyChatBody;

  /// No description provided for @notificationsFamilyEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Family event'**
  String get notificationsFamilyEventTitle;

  /// No description provided for @notificationsFamilyEventBody.
  ///
  /// In en, this message translates to:
  /// **'Your family has a new event'**
  String get notificationsFamilyEventBody;

  /// No description provided for @notificationsBirthdayTitle.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get notificationsBirthdayTitle;

  /// No description provided for @notificationsBirthdayUpcomingBody.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s birthday is coming soon!'**
  String notificationsBirthdayUpcomingBody(String name);

  /// No description provided for @notificationsBirthdayTodayBody.
  ///
  /// In en, this message translates to:
  /// **'Today is {name}\'s birthday!'**
  String notificationsBirthdayTodayBody(String name);

  /// No description provided for @notificationsTrackingDefaultBody.
  ///
  /// In en, this message translates to:
  /// **'Tracking status has changed.'**
  String get notificationsTrackingDefaultBody;

  /// No description provided for @scheduleOverlapConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'Conflicts with schedule \"{title}\" ({start} - {end}). Please choose another time.'**
  String scheduleOverlapConflictMessage(String title, String start, String end);

  /// No description provided for @scheduleExportErrorCreateExcelFile.
  ///
  /// In en, this message translates to:
  /// **'Unable to create Excel file'**
  String get scheduleExportErrorCreateExcelFile;

  /// No description provided for @scheduleImportTemplateSampleTitle1.
  ///
  /// In en, this message translates to:
  /// **'Math Study'**
  String get scheduleImportTemplateSampleTitle1;

  /// No description provided for @scheduleImportTemplateSampleDescription1.
  ///
  /// In en, this message translates to:
  /// **'Complete exercises 1-5'**
  String get scheduleImportTemplateSampleDescription1;

  /// No description provided for @scheduleImportTemplateSampleTitle2.
  ///
  /// In en, this message translates to:
  /// **'Play football'**
  String get scheduleImportTemplateSampleTitle2;

  /// No description provided for @scheduleImportErrorCreateExcelBytes.
  ///
  /// In en, this message translates to:
  /// **'Unable to create Excel bytes'**
  String get scheduleImportErrorCreateExcelBytes;

  /// No description provided for @scheduleImportErrorMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing title'**
  String get scheduleImportErrorMissingTitle;

  /// No description provided for @scheduleImportErrorEndAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get scheduleImportErrorEndAfterStart;

  /// No description provided for @scheduleImportWarningDbCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Duplicate check against database failed due to network error: {error}'**
  String scheduleImportWarningDbCheckFailed(String error);

  /// No description provided for @scheduleImportErrorMissingDate.
  ///
  /// In en, this message translates to:
  /// **'Missing date'**
  String get scheduleImportErrorMissingDate;

  /// No description provided for @scheduleImportErrorInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid date: \"{raw}\"'**
  String scheduleImportErrorInvalidDate(String raw);

  /// No description provided for @scheduleImportErrorInvalidDateSupported.
  ///
  /// In en, this message translates to:
  /// **'Invalid date: \"{raw}\" (supported: yyyy-MM-dd, dd/MM/yyyy, MM/dd/yyyy, ISO datetime)'**
  String scheduleImportErrorInvalidDateSupported(String raw);

  /// No description provided for @scheduleImportErrorMissingTime.
  ///
  /// In en, this message translates to:
  /// **'Missing time'**
  String get scheduleImportErrorMissingTime;

  /// No description provided for @scheduleImportErrorInvalidTimeSupported.
  ///
  /// In en, this message translates to:
  /// **'Invalid time: \"{raw}\" (supported: HH:mm, HH:mm:ss, 7:00 AM/PM)'**
  String scheduleImportErrorInvalidTimeSupported(String raw);

  /// No description provided for @scheduleNotifyTitleCreated.
  ///
  /// In en, this message translates to:
  /// **'New schedule'**
  String get scheduleNotifyTitleCreated;

  /// No description provided for @scheduleNotifyTitleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated'**
  String get scheduleNotifyTitleUpdated;

  /// No description provided for @scheduleNotifyTitleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Schedule deleted'**
  String get scheduleNotifyTitleDeleted;

  /// No description provided for @scheduleNotifyTitleRestored.
  ///
  /// In en, this message translates to:
  /// **'Schedule restored'**
  String get scheduleNotifyTitleRestored;

  /// No description provided for @scheduleNotifyTitleChanged.
  ///
  /// In en, this message translates to:
  /// **'Schedule changed'**
  String get scheduleNotifyTitleChanged;

  /// No description provided for @scheduleNotifyBodyParentCreated.
  ///
  /// In en, this message translates to:
  /// **'Parent added schedule \"{title}\" for {childName} on {date}, {time}.'**
  String scheduleNotifyBodyParentCreated(
    String title,
    String childName,
    String date,
    String time,
  );

  /// No description provided for @scheduleNotifyBodyParentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Parent updated schedule \"{title}\" of {childName}.'**
  String scheduleNotifyBodyParentUpdated(String title, String childName);

  /// No description provided for @scheduleNotifyBodyParentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Parent deleted schedule \"{title}\" of {childName}.'**
  String scheduleNotifyBodyParentDeleted(String title, String childName);

  /// No description provided for @scheduleNotifyBodyParentRestored.
  ///
  /// In en, this message translates to:
  /// **'Parent restored an older version of schedule \"{title}\" of {childName}.'**
  String scheduleNotifyBodyParentRestored(String title, String childName);

  /// No description provided for @scheduleNotifyBodyParentChanged.
  ///
  /// In en, this message translates to:
  /// **'Parent changed schedule \"{title}\" of {childName}.'**
  String scheduleNotifyBodyParentChanged(String title, String childName);

  /// No description provided for @scheduleNotifyBodyChildCreated.
  ///
  /// In en, this message translates to:
  /// **'{childName} added schedule \"{title}\" on {date}, {time}.'**
  String scheduleNotifyBodyChildCreated(
    String childName,
    String title,
    String date,
    String time,
  );

  /// No description provided for @scheduleNotifyBodyChildUpdated.
  ///
  /// In en, this message translates to:
  /// **'{childName} updated schedule \"{title}\".'**
  String scheduleNotifyBodyChildUpdated(String childName, String title);

  /// No description provided for @scheduleNotifyBodyChildDeleted.
  ///
  /// In en, this message translates to:
  /// **'{childName} deleted schedule \"{title}\".'**
  String scheduleNotifyBodyChildDeleted(String childName, String title);

  /// No description provided for @scheduleNotifyBodyChildRestored.
  ///
  /// In en, this message translates to:
  /// **'{childName} restored edit history of schedule \"{title}\".'**
  String scheduleNotifyBodyChildRestored(String childName, String title);

  /// No description provided for @scheduleNotifyBodyChildChanged.
  ///
  /// In en, this message translates to:
  /// **'{childName} changed schedule \"{title}\".'**
  String scheduleNotifyBodyChildChanged(String childName, String title);

  /// No description provided for @memoryDayNotifyTitleCreated.
  ///
  /// In en, this message translates to:
  /// **'New memorable day'**
  String get memoryDayNotifyTitleCreated;

  /// No description provided for @memoryDayNotifyTitleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Memorable day updated'**
  String get memoryDayNotifyTitleUpdated;

  /// No description provided for @memoryDayNotifyTitleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Memorable day deleted'**
  String get memoryDayNotifyTitleDeleted;

  /// No description provided for @memoryDayNotifyTitleChanged.
  ///
  /// In en, this message translates to:
  /// **'Memorable day changed'**
  String get memoryDayNotifyTitleChanged;

  /// No description provided for @memoryDayNotifyBodyParentCreated.
  ///
  /// In en, this message translates to:
  /// **'Parent added memorable day \"{title}\".'**
  String memoryDayNotifyBodyParentCreated(String title);

  /// No description provided for @memoryDayNotifyBodyParentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Parent updated memorable day \"{title}\".'**
  String memoryDayNotifyBodyParentUpdated(String title);

  /// No description provided for @memoryDayNotifyBodyParentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Parent deleted memorable day \"{title}\".'**
  String memoryDayNotifyBodyParentDeleted(String title);

  /// No description provided for @memoryDayNotifyBodyParentChanged.
  ///
  /// In en, this message translates to:
  /// **'Parent changed memorable day \"{title}\".'**
  String memoryDayNotifyBodyParentChanged(String title);

  /// No description provided for @memoryDayNotifyBodyChildCreated.
  ///
  /// In en, this message translates to:
  /// **'{actorChildName} added memorable day \"{title}\".'**
  String memoryDayNotifyBodyChildCreated(String actorChildName, String title);

  /// No description provided for @memoryDayNotifyBodyChildUpdated.
  ///
  /// In en, this message translates to:
  /// **'{actorChildName} updated memorable day \"{title}\".'**
  String memoryDayNotifyBodyChildUpdated(String actorChildName, String title);

  /// No description provided for @memoryDayNotifyBodyChildDeleted.
  ///
  /// In en, this message translates to:
  /// **'{actorChildName} deleted memorable day \"{title}\".'**
  String memoryDayNotifyBodyChildDeleted(String actorChildName, String title);

  /// No description provided for @memoryDayNotifyBodyChildChanged.
  ///
  /// In en, this message translates to:
  /// **'{actorChildName} changed memorable day \"{title}\".'**
  String memoryDayNotifyBodyChildChanged(String actorChildName, String title);

  /// No description provided for @scheduleImportNotifyTitle.
  ///
  /// In en, this message translates to:
  /// **'New schedules added'**
  String get scheduleImportNotifyTitle;

  /// No description provided for @scheduleImportNotifyBodyParent.
  ///
  /// In en, this message translates to:
  /// **'Parent added {importCount} schedules for {childName}.'**
  String scheduleImportNotifyBodyParent(int importCount, String childName);

  /// No description provided for @scheduleImportNotifyBodyChild.
  ///
  /// In en, this message translates to:
  /// **'{actorChildName} added {importCount} schedules.'**
  String scheduleImportNotifyBodyChild(String actorChildName, int importCount);

  /// No description provided for @parentDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get parentDashboardTitle;

  /// No description provided for @parentDashboardTabApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get parentDashboardTabApps;

  /// No description provided for @parentDashboardTabStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get parentDashboardTabStatistics;

  /// No description provided for @parentDashboardNoDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'No linked devices yet'**
  String get parentDashboardNoDeviceTitle;

  /// No description provided for @parentDashboardNoDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To monitor app usage time, add your child\'s device to the system.'**
  String get parentDashboardNoDeviceSubtitle;

  /// No description provided for @parentDashboardAddDeviceButton.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get parentDashboardAddDeviceButton;

  /// No description provided for @parentDashboardHowItWorksButton.
  ///
  /// In en, this message translates to:
  /// **'Learn how it works'**
  String get parentDashboardHowItWorksButton;

  /// No description provided for @parentStatsTotalToday.
  ///
  /// In en, this message translates to:
  /// **'TOTAL TIME TODAY'**
  String get parentStatsTotalToday;

  /// No description provided for @parentStatsTotalThisWeek.
  ///
  /// In en, this message translates to:
  /// **'TOTAL TIME THIS WEEK'**
  String get parentStatsTotalThisWeek;

  /// No description provided for @parentStatsSelectRange.
  ///
  /// In en, this message translates to:
  /// **'SELECT DATE RANGE'**
  String get parentStatsSelectRange;

  /// No description provided for @parentStatsSelectEndDate.
  ///
  /// In en, this message translates to:
  /// **'SELECT END DATE'**
  String get parentStatsSelectEndDate;

  /// No description provided for @parentStatsTotalFromRange.
  ///
  /// In en, this message translates to:
  /// **'TOTAL TIME FROM {startDate} - {endDate}'**
  String parentStatsTotalFromRange(String startDate, String endDate);

  /// No description provided for @parentStatsSegmentDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get parentStatsSegmentDay;

  /// No description provided for @parentStatsSegmentWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get parentStatsSegmentWeek;

  /// No description provided for @parentStatsSegmentRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get parentStatsSegmentRange;

  /// No description provided for @parentStatsAppDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'App details'**
  String get parentStatsAppDetailsTitle;

  /// No description provided for @parentStatsCollapse.
  ///
  /// In en, this message translates to:
  /// **'COLLAPSE'**
  String get parentStatsCollapse;

  /// No description provided for @parentStatsViewAll.
  ///
  /// In en, this message translates to:
  /// **'VIEW ALL'**
  String get parentStatsViewAll;

  /// No description provided for @parentUsageNoAvailableSlot.
  ///
  /// In en, this message translates to:
  /// **'No available time slot'**
  String get parentUsageNoAvailableSlot;

  /// No description provided for @parentUsageStartBeforeEnd.
  ///
  /// In en, this message translates to:
  /// **'Start time must be earlier than end time'**
  String get parentUsageStartBeforeEnd;

  /// No description provided for @parentUsageOverlapTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Time range overlaps another slot'**
  String get parentUsageOverlapTimeRange;

  /// No description provided for @parentUsageEndAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be later than start time'**
  String get parentUsageEndAfterStart;

  /// No description provided for @parentUsageEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage time settings'**
  String get parentUsageEditTitle;

  /// No description provided for @parentUsageEnableUsage.
  ///
  /// In en, this message translates to:
  /// **'Allow usage'**
  String get parentUsageEnableUsage;

  /// No description provided for @parentUsageSelectAllowedDays.
  ///
  /// In en, this message translates to:
  /// **'Select allowed days'**
  String get parentUsageSelectAllowedDays;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @parentUsageDayRuleModalHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the rule for this day'**
  String get parentUsageDayRuleModalHint;

  /// No description provided for @parentUsageRuleFollowScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow schedule'**
  String get parentUsageRuleFollowScheduleTitle;

  /// No description provided for @parentUsageRuleFollowScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply weekly time windows'**
  String get parentUsageRuleFollowScheduleSubtitle;

  /// No description provided for @parentUsageRuleAllowAllDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow all day'**
  String get parentUsageRuleAllowAllDayTitle;

  /// No description provided for @parentUsageRuleAllowAllDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Can be used at any time'**
  String get parentUsageRuleAllowAllDaySubtitle;

  /// No description provided for @parentUsageRuleBlockAllDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Block all day'**
  String get parentUsageRuleBlockAllDayTitle;

  /// No description provided for @parentUsageRuleBlockAllDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot be used today'**
  String get parentUsageRuleBlockAllDaySubtitle;

  /// No description provided for @zonesDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get zonesDeleteConfirmTitle;

  /// No description provided for @zonesDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this location?'**
  String get zonesDeleteConfirmMessage;

  /// No description provided for @zonesDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get zonesDeleteButton;

  /// No description provided for @zonesCreateSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Created successfully'**
  String get zonesCreateSuccessTitle;

  /// No description provided for @zonesCreateSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Location \"{name}\" has been created'**
  String zonesCreateSuccessMessage(String name);

  /// No description provided for @zonesFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get zonesFailedTitle;

  /// No description provided for @zonesCreateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to create location. Please try again.'**
  String get zonesCreateFailedMessage;

  /// No description provided for @zonesEditSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get zonesEditSuccessTitle;

  /// No description provided for @zonesEditSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Location has been updated'**
  String get zonesEditSuccessMessage;

  /// No description provided for @zonesEditFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to update location. Please try again.'**
  String get zonesEditFailedMessage;

  /// No description provided for @zonesDeleteSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get zonesDeleteSuccessTitle;

  /// No description provided for @zonesDeleteSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Location has been deleted'**
  String get zonesDeleteSuccessMessage;

  /// No description provided for @zonesDeleteFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete location. Please try again.'**
  String get zonesDeleteFailedMessage;

  /// No description provided for @zonesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No zones yet'**
  String get zonesEmptyTitle;

  /// No description provided for @zonesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add zones to start tracking your child\'s location'**
  String get zonesEmptySubtitle;

  /// No description provided for @zonesTypeSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get zonesTypeSafe;

  /// No description provided for @zonesTypeDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger'**
  String get zonesTypeDanger;

  /// No description provided for @zonesEditMenu.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get zonesEditMenu;

  /// No description provided for @zonesDeleteMenu.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get zonesDeleteMenu;

  /// No description provided for @zonesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Child zones'**
  String get zonesScreenTitle;

  /// No description provided for @zonesAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add zone'**
  String get zonesAddButton;

  /// No description provided for @zonesErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String zonesErrorWithMessage(String error);

  /// No description provided for @zonesNewZoneDefaultName.
  ///
  /// In en, this message translates to:
  /// **'New zone'**
  String get zonesNewZoneDefaultName;

  /// No description provided for @zonesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit zone'**
  String get zonesEditTitle;

  /// No description provided for @zonesAddAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Location address'**
  String get zonesAddAddressTitle;

  /// No description provided for @zonesOverlapWarningText.
  ///
  /// In en, this message translates to:
  /// **'Locations should not overlap'**
  String get zonesOverlapWarningText;

  /// No description provided for @zonesNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Zone name'**
  String get zonesNameFieldLabel;

  /// No description provided for @zonesTypeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Zone type'**
  String get zonesTypeFieldLabel;

  /// No description provided for @zonesRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get zonesRadiusLabel;

  /// No description provided for @zonesOverlappingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Overlapping with: '**
  String get zonesOverlappingPrefix;

  /// No description provided for @zonesOverlappingWith.
  ///
  /// In en, this message translates to:
  /// **'Overlapping with: {name}'**
  String zonesOverlappingWith(String name);

  /// No description provided for @zonesDefaultNameFallback.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zonesDefaultNameFallback;

  /// No description provided for @parentLocationUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get parentLocationUnknownUser;

  /// No description provided for @parentLocationSosSent.
  ///
  /// In en, this message translates to:
  /// **'SOS sent'**
  String get parentLocationSosSent;

  /// No description provided for @parentLocationSosFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send SOS'**
  String get parentLocationSosFailed;

  /// No description provided for @parentLocationMapLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading map'**
  String get parentLocationMapLoadingTitle;

  /// No description provided for @parentLocationMapLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing the children\'s locations'**
  String get parentLocationMapLoadingSubtitle;

  /// No description provided for @parentChildrenListTitle.
  ///
  /// In en, this message translates to:
  /// **'Member list'**
  String get parentChildrenListTitle;

  /// No description provided for @personalInfoManageAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account management'**
  String get personalInfoManageAccountsTitle;

  /// No description provided for @personalInfoManageAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage member accounts'**
  String get personalInfoManageAccountsSubtitle;

  /// No description provided for @personalInfoDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get personalInfoDetailsButton;

  /// No description provided for @childLocationTransportWalking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get childLocationTransportWalking;

  /// No description provided for @childLocationTransportBicycle.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get childLocationTransportBicycle;

  /// No description provided for @childLocationTransportVehicle.
  ///
  /// In en, this message translates to:
  /// **'In vehicle'**
  String get childLocationTransportVehicle;

  /// No description provided for @childLocationTransportStill.
  ///
  /// In en, this message translates to:
  /// **'Still'**
  String get childLocationTransportStill;

  /// No description provided for @childLocationTransportUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get childLocationTransportUnknown;

  /// No description provided for @childLocationDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Location details'**
  String get childLocationDetailTitle;

  /// No description provided for @childLocationStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Status: {transport}'**
  String childLocationStatusTitle(String transport);

  /// No description provided for @childLocationHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History • {date}'**
  String childLocationHistoryTitle(String date);

  /// No description provided for @childLocationTooltipHideDots.
  ///
  /// In en, this message translates to:
  /// **'Hide points'**
  String get childLocationTooltipHideDots;

  /// No description provided for @childLocationTooltipShowDots.
  ///
  /// In en, this message translates to:
  /// **'Show points'**
  String get childLocationTooltipShowDots;

  /// No description provided for @childLocationHistoryButton.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get childLocationHistoryButton;

  /// No description provided for @childLocationZonesButton.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get childLocationZonesButton;

  /// No description provided for @zone_default.
  ///
  /// In en, this message translates to:
  /// **'Zone notification'**
  String get zone_default;

  /// No description provided for @zone_enter_danger_parent.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Child entered a danger zone'**
  String get zone_enter_danger_parent;

  /// No description provided for @zone_exit_danger_parent.
  ///
  /// In en, this message translates to:
  /// **'✅ Child left a danger zone'**
  String get zone_exit_danger_parent;

  /// No description provided for @zone_enter_safe_parent.
  ///
  /// In en, this message translates to:
  /// **'✅ Child entered a safe zone'**
  String get zone_enter_safe_parent;

  /// No description provided for @zone_exit_safe_parent.
  ///
  /// In en, this message translates to:
  /// **'ℹ️ Child left a safe zone'**
  String get zone_exit_safe_parent;

  /// No description provided for @zone_enter_danger_child.
  ///
  /// In en, this message translates to:
  /// **'⚠️ You entered a danger zone'**
  String get zone_enter_danger_child;

  /// No description provided for @zone_exit_danger_child.
  ///
  /// In en, this message translates to:
  /// **'✅ You left a danger zone'**
  String get zone_exit_danger_child;

  /// No description provided for @zone_enter_safe_child.
  ///
  /// In en, this message translates to:
  /// **'✅ You entered a safe zone'**
  String get zone_enter_safe_child;

  /// No description provided for @zone_exit_safe_child.
  ///
  /// In en, this message translates to:
  /// **'ℹ️ You left a safe zone'**
  String get zone_exit_safe_child;

  /// No description provided for @tracking_location_service_off_parent_title.
  ///
  /// In en, this message translates to:
  /// **'Child turned off location'**
  String get tracking_location_service_off_parent_title;

  /// No description provided for @tracking_location_permission_denied_parent_title.
  ///
  /// In en, this message translates to:
  /// **'Child turned off location permission'**
  String get tracking_location_permission_denied_parent_title;

  /// No description provided for @tracking_background_disabled_parent_title.
  ///
  /// In en, this message translates to:
  /// **'Background location was turned off'**
  String get tracking_background_disabled_parent_title;

  /// No description provided for @tracking_location_stale_parent_title.
  ///
  /// In en, this message translates to:
  /// **'No recent location update'**
  String get tracking_location_stale_parent_title;

  /// No description provided for @tracking_ok_parent_title.
  ///
  /// In en, this message translates to:
  /// **'Location is active again'**
  String get tracking_ok_parent_title;

  /// No description provided for @tracking_location_service_off_child_title.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off'**
  String get tracking_location_service_off_child_title;

  /// No description provided for @tracking_location_permission_denied_child_title.
  ///
  /// In en, this message translates to:
  /// **'Location permission is off'**
  String get tracking_location_permission_denied_child_title;

  /// No description provided for @tracking_background_disabled_child_title.
  ///
  /// In en, this message translates to:
  /// **'Background location is off'**
  String get tracking_background_disabled_child_title;

  /// No description provided for @tracking_location_stale_child_title.
  ///
  /// In en, this message translates to:
  /// **'Location is not updating'**
  String get tracking_location_stale_child_title;

  /// No description provided for @tracking_ok_child_title.
  ///
  /// In en, this message translates to:
  /// **'Location is working again'**
  String get tracking_ok_child_title;

  /// No description provided for @tracking_default_title.
  ///
  /// In en, this message translates to:
  /// **'Tracking notification'**
  String get tracking_default_title;

  /// No description provided for @sosChannelName.
  ///
  /// In en, this message translates to:
  /// **'SOS Alerts'**
  String get sosChannelName;

  /// No description provided for @sosChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS alerts'**
  String get sosChannelDescription;

  /// No description provided for @sosFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get sosFallbackTitle;

  /// No description provided for @sosFallbackBody.
  ///
  /// In en, this message translates to:
  /// **'A family member is asking for help.'**
  String get sosFallbackBody;

  /// No description provided for @localAlarmDangerChannelName.
  ///
  /// In en, this message translates to:
  /// **'Danger zone alerts'**
  String get localAlarmDangerChannelName;

  /// No description provided for @localAlarmDangerChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Alerts when a child enters or leaves a danger zone'**
  String get localAlarmDangerChannelDescription;

  /// No description provided for @localAlarmDangerEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Danger zone alert'**
  String get localAlarmDangerEnterTitle;

  /// No description provided for @localAlarmDangerEnterBody.
  ///
  /// In en, this message translates to:
  /// **'You entered: {zoneName}'**
  String localAlarmDangerEnterBody(String zoneName);

  /// No description provided for @localAlarmDangerExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Left danger zone'**
  String get localAlarmDangerExitTitle;

  /// No description provided for @localAlarmDangerExitBody.
  ///
  /// In en, this message translates to:
  /// **'You left: {zoneName}'**
  String localAlarmDangerExitBody(String zoneName);

  /// No description provided for @trackingStatusLocationServiceOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Device turned off GPS/location'**
  String get trackingStatusLocationServiceOffMessage;

  /// No description provided for @trackingStatusLocationPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Device turned off location permission'**
  String get trackingStatusLocationPermissionDeniedMessage;

  /// No description provided for @trackingStatusPreciseLocationDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Device has not granted precise location'**
  String get trackingStatusPreciseLocationDeniedMessage;

  /// No description provided for @trackingStatusBackgroundDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Background location sharing is off'**
  String get trackingStatusBackgroundDisabledMessage;

  /// No description provided for @trackingStatusOkMessage.
  ///
  /// In en, this message translates to:
  /// **'Location is working normally'**
  String get trackingStatusOkMessage;

  /// No description provided for @trackingErrorEnableLocationService.
  ///
  /// In en, this message translates to:
  /// **'Please turn on GPS/location on the device.'**
  String get trackingErrorEnableLocationService;

  /// No description provided for @trackingErrorEnablePreciseLocation.
  ///
  /// In en, this message translates to:
  /// **'Please allow precise location.'**
  String get trackingErrorEnablePreciseLocation;

  /// No description provided for @trackingErrorEnableBackgroundLocation.
  ///
  /// In en, this message translates to:
  /// **'Please allow background location sharing (Allow all the time).'**
  String get trackingErrorEnableBackgroundLocation;

  /// No description provided for @locationForegroundServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing location'**
  String get locationForegroundServiceTitle;

  /// No description provided for @locationForegroundServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The app runs in background to help protect your child'**
  String get locationForegroundServiceSubtitle;

  /// No description provided for @parentLocationGpsError.
  ///
  /// In en, this message translates to:
  /// **'GPS error: {error}'**
  String parentLocationGpsError(Object error);

  /// No description provided for @parentLocationEnableGpsError.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable GPS: {error}'**
  String parentLocationEnableGpsError(Object error);

  /// No description provided for @parentLocationCurrentLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get current location: {error}'**
  String parentLocationCurrentLocationError(Object error);

  /// No description provided for @parentLocationHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history: {error}'**
  String parentLocationHistoryLoadError(Object error);

  /// No description provided for @parentLocationWatchChildError.
  ///
  /// In en, this message translates to:
  /// **'Failed to watch {childId}: {error}'**
  String parentLocationWatchChildError(Object childId, Object error);

  /// No description provided for @authLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get authLoginRequired;

  /// No description provided for @firebaseAuthCurrentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get firebaseAuthCurrentPasswordIncorrect;

  /// No description provided for @firebaseAuthUserMismatch.
  ///
  /// In en, this message translates to:
  /// **'Authenticated account does not match'**
  String get firebaseAuthUserMismatch;

  /// No description provided for @firebaseAuthTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again later'**
  String get firebaseAuthTooManyRequests;

  /// No description provided for @firebaseAuthNetworkFailed.
  ///
  /// In en, this message translates to:
  /// **'Network connection error. Please check your internet'**
  String get firebaseAuthNetworkFailed;

  /// No description provided for @firebaseAuthChangePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change password. Please try again'**
  String get firebaseAuthChangePasswordFailed;

  /// No description provided for @permissionLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable location access'**
  String get permissionLocationTitle;

  /// No description provided for @permissionLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The app needs location permission to track your child\'s position and support safety features.'**
  String get permissionLocationSubtitle;

  /// No description provided for @permissionLocationRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommended: allow location while using the app first. If background tracking is needed later, you can grant Always permission after that.'**
  String get permissionLocationRecommendation;

  /// No description provided for @permissionLocationAllowButton.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get permissionLocationAllowButton;

  /// No description provided for @permissionNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable SOS Alerts'**
  String get permissionNotificationTitle;

  /// No description provided for @permissionNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The app needs notification permission to send emergency SOS alerts even when the app is closed.'**
  String get permissionNotificationSubtitle;

  /// No description provided for @permissionNotificationRecommendation.
  ///
  /// In en, this message translates to:
  /// **'After granting permission, make sure the \"SOS Alerts\" notification channel has sound enabled in system settings.'**
  String get permissionNotificationRecommendation;

  /// No description provided for @permissionNotificationAllowButton.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get permissionNotificationAllowButton;

  /// No description provided for @permissionSosTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable SOS access'**
  String get permissionSosTitle;

  /// No description provided for @permissionSosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The app needs notification permission to send emergency SOS alerts and play alarm sounds.'**
  String get permissionSosSubtitle;

  /// No description provided for @permissionSosRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Please enable notifications and make sure the \"SOS Alerts\" channel has sound enabled.'**
  String get permissionSosRecommendation;

  /// No description provided for @permissionSosAllowButton.
  ///
  /// In en, this message translates to:
  /// **'Allow SOS'**
  String get permissionSosAllowButton;

  /// No description provided for @permissionOpenSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get permissionOpenSettingsButton;

  /// No description provided for @permissionLaterButton.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get permissionLaterButton;

  /// No description provided for @permissionStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current}/{total}'**
  String permissionStepLabel(int current, int total);

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @commonStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get commonStartLabel;

  /// No description provided for @commonEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get commonEndLabel;

  /// No description provided for @childLocationSosSending.
  ///
  /// In en, this message translates to:
  /// **'Sending SOS...'**
  String get childLocationSosSending;

  /// No description provided for @childLocationSosError.
  ///
  /// In en, this message translates to:
  /// **'SOS error: {error}'**
  String childLocationSosError(String error);

  /// No description provided for @childLocationCurrentJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Current journey'**
  String get childLocationCurrentJourneyTitle;

  /// No description provided for @childLocationTravelHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Movement history'**
  String get childLocationTravelHistoryTitle;

  /// No description provided for @childLocationTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get childLocationTodayLabel;

  /// No description provided for @childLocationRangeAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get childLocationRangeAllDay;

  /// No description provided for @childLocationTagStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get childLocationTagStart;

  /// No description provided for @childLocationTagEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get childLocationTagEnd;

  /// No description provided for @childLocationTagGpsVeryWeak.
  ///
  /// In en, this message translates to:
  /// **'Very weak GPS'**
  String get childLocationTagGpsVeryWeak;

  /// No description provided for @childLocationTagGpsLost.
  ///
  /// In en, this message translates to:
  /// **'GPS lost'**
  String get childLocationTagGpsLost;

  /// No description provided for @childLocationStayedHereLabel.
  ///
  /// In en, this message translates to:
  /// **'Stayed here'**
  String get childLocationStayedHereLabel;

  /// No description provided for @childLocationStayedHereUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get childLocationStayedHereUnavailable;

  /// No description provided for @childLocationSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get childLocationSpeedLabel;

  /// No description provided for @childLocationSpeedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get childLocationSpeedUnavailable;

  /// No description provided for @childLocationGpsAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy'**
  String get childLocationGpsAccuracyLabel;

  /// No description provided for @childLocationMockGpsLabel.
  ///
  /// In en, this message translates to:
  /// **'Mock GPS'**
  String get childLocationMockGpsLabel;

  /// No description provided for @childLocationMockGpsDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get childLocationMockGpsDetected;

  /// No description provided for @childLocationNoLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get childLocationNoLabel;

  /// No description provided for @childLocationTechnicalDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get childLocationTechnicalDetailsTitle;

  /// No description provided for @childLocationDetailFullTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get childLocationDetailFullTimeLabel;

  /// No description provided for @childLocationDetailHeadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get childLocationDetailHeadingLabel;

  /// No description provided for @childLocationDetailCoordinatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get childLocationDetailCoordinatesLabel;

  /// No description provided for @childLocationDetailAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get childLocationDetailAccuracyLabel;

  /// No description provided for @childLocationDurationZeroMinutes.
  ///
  /// In en, this message translates to:
  /// **'0 min'**
  String get childLocationDurationZeroMinutes;

  /// No description provided for @childLocationDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String childLocationDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @childLocationDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String childLocationDurationMinutes(int minutes);

  /// No description provided for @childLocationDurationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec'**
  String childLocationDurationSeconds(int seconds);

  /// No description provided for @childLocationGpsLostTitle.
  ///
  /// In en, this message translates to:
  /// **'GPS signal lost'**
  String get childLocationGpsLostTitle;

  /// No description provided for @childLocationGpsVeryWeakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'GPS signal is very weak. The location may be inaccurate.'**
  String get childLocationGpsVeryWeakSubtitle;

  /// No description provided for @childLocationGpsLostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accuracy is worse than {meters} m'**
  String childLocationGpsLostSubtitle(String meters);

  /// No description provided for @childLocationStoppedNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Currently stopped'**
  String get childLocationStoppedNowTitle;

  /// No description provided for @childLocationStoppedNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stopped here for {duration}'**
  String childLocationStoppedNowSubtitle(String duration);

  /// No description provided for @childLocationStoppedHereTitle.
  ///
  /// In en, this message translates to:
  /// **'Stopped here'**
  String get childLocationStoppedHereTitle;

  /// No description provided for @childLocationStoppedHereSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stopped for about {duration}'**
  String childLocationStoppedHereSubtitle(String duration);

  /// No description provided for @childLocationJourneyStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Journey starting point'**
  String get childLocationJourneyStartSubtitle;

  /// No description provided for @childLocationJourneyEndSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Journey ending point'**
  String get childLocationJourneyEndSubtitle;

  /// No description provided for @childLocationUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at {time}'**
  String childLocationUpdatedAt(String time);

  /// No description provided for @childLocationPassedAt.
  ///
  /// In en, this message translates to:
  /// **'Passed this point at {time}'**
  String childLocationPassedAt(String time);

  /// No description provided for @childLocationHeadlineWalking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get childLocationHeadlineWalking;

  /// No description provided for @childLocationHeadlineBicycle.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get childLocationHeadlineBicycle;

  /// No description provided for @childLocationHeadlineVehicle.
  ///
  /// In en, this message translates to:
  /// **'In vehicle'**
  String get childLocationHeadlineVehicle;

  /// No description provided for @childLocationHeadlineStill.
  ///
  /// In en, this message translates to:
  /// **'Standing still'**
  String get childLocationHeadlineStill;

  /// No description provided for @childLocationHeadlineUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown status'**
  String get childLocationHeadlineUnknown;

  /// No description provided for @childLocationSpeedAlmostStill.
  ///
  /// In en, this message translates to:
  /// **'Almost not moving'**
  String get childLocationSpeedAlmostStill;

  /// No description provided for @childLocationAccuracySevere.
  ///
  /// In en, this message translates to:
  /// **'Severe GPS loss'**
  String get childLocationAccuracySevere;

  /// No description provided for @childLocationAccuracyLost.
  ///
  /// In en, this message translates to:
  /// **'GPS lost'**
  String get childLocationAccuracyLost;

  /// No description provided for @childLocationAccuracyGood.
  ///
  /// In en, this message translates to:
  /// **'Fairly accurate ({meters} m)'**
  String childLocationAccuracyGood(String meters);

  /// No description provided for @childLocationAccuracyModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate accuracy ({meters} m)'**
  String childLocationAccuracyModerate(String meters);

  /// No description provided for @childLocationTimeWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a time range'**
  String get childLocationTimeWindowTitle;

  /// No description provided for @childLocationTimeWindowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only load and show history within the selected time range.'**
  String get childLocationTimeWindowSubtitle;

  /// No description provided for @childLocationPresetMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get childLocationPresetMorning;

  /// No description provided for @childLocationPresetAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get childLocationPresetAfternoon;

  /// No description provided for @childLocationPresetEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get childLocationPresetEvening;

  /// No description provided for @childLocationNoDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No data in this range'**
  String get childLocationNoDataTitle;

  /// No description provided for @childLocationNoDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another time range or another day to review the journey.'**
  String get childLocationNoDataSubtitle;

  /// No description provided for @childLocationSummaryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get childLocationSummaryDateLabel;

  /// No description provided for @childLocationSummaryTimeRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time range'**
  String get childLocationSummaryTimeRangeLabel;

  /// No description provided for @childLocationLiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get childLocationLiveLabel;

  /// No description provided for @childLocationPointCount.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String childLocationPointCount(int count);

  /// No description provided for @locationNoLocationYet.
  ///
  /// In en, this message translates to:
  /// **'No location yet'**
  String get locationNoLocationYet;

  /// No description provided for @locationCoordinatesSummary.
  ///
  /// In en, this message translates to:
  /// **'Lat {lat} • Lng {lng}'**
  String locationCoordinatesSummary(String lat, String lng);

  /// No description provided for @locationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get locationSearchHint;

  /// No description provided for @locationMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get locationMessageSent;

  /// No description provided for @locationChildInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get locationChildInfoTitle;

  /// No description provided for @locationQuickMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Send a quick message...'**
  String get locationQuickMessageHint;

  /// No description provided for @locationStatusStudying.
  ///
  /// In en, this message translates to:
  /// **'Studying'**
  String get locationStatusStudying;

  /// No description provided for @locationStopSearching.
  ///
  /// In en, this message translates to:
  /// **'Stop searching'**
  String get locationStopSearching;

  /// No description provided for @incomingSosConfirmFailed.
  ///
  /// In en, this message translates to:
  /// **'Confirmation failed: {error}'**
  String incomingSosConfirmFailed(Object error);

  /// No description provided for @incomingSosEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'🚨 Emergency SOS alert!'**
  String get incomingSosEmergencyTitle;

  /// No description provided for @incomingSosResolvingButton.
  ///
  /// In en, this message translates to:
  /// **'PROCESSING'**
  String get incomingSosResolvingButton;

  /// No description provided for @incomingSosConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get incomingSosConfirmButton;

  /// No description provided for @sosConfirmedRoleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get sosConfirmedRoleParent;

  /// No description provided for @sosConfirmedRoleChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get sosConfirmedRoleChild;

  /// No description provided for @sosConfirmedNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sosConfirmedNameLabel;

  /// No description provided for @sosConfirmedSenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sosConfirmedSenderLabel;

  /// No description provided for @sosConfirmedSentAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent at'**
  String get sosConfirmedSentAtLabel;

  /// No description provided for @sosConfirmedConfirmedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmed at'**
  String get sosConfirmedConfirmedAtLabel;

  /// No description provided for @sosConfirmedAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get sosConfirmedAccuracyLabel;

  /// No description provided for @sosConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS confirmed'**
  String get sosConfirmedTitle;

  /// No description provided for @sosConfirmedCloseButton.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get sosConfirmedCloseButton;

  /// No description provided for @sosButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosButtonLabel;

  /// No description provided for @parentPhoneSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the phone number'**
  String get parentPhoneSaveFailed;

  /// No description provided for @parentPhoneAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your child\'s phone number'**
  String get parentPhoneAddTitle;

  /// No description provided for @parentPhoneAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact your child even when their phone is in silent mode'**
  String get parentPhoneAddSubtitle;

  /// No description provided for @parentPhoneAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get parentPhoneAddButton;

  /// No description provided for @parentPhoneContactHasNoNumber.
  ///
  /// In en, this message translates to:
  /// **'This contact has no phone number'**
  String get parentPhoneContactHasNoNumber;

  /// No description provided for @parentPhonePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get the phone number from contacts: {error}'**
  String parentPhonePickFailed(Object error);

  /// No description provided for @parentPhonePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose phone number'**
  String get parentPhonePickTitle;

  /// No description provided for @parentPhoneOpenContactsButton.
  ///
  /// In en, this message translates to:
  /// **'Open contacts'**
  String get parentPhoneOpenContactsButton;

  /// No description provided for @appImageReplaceOption.
  ///
  /// In en, this message translates to:
  /// **'Change image'**
  String get appImageReplaceOption;

  /// No description provided for @appImageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get appImageLoadFailed;

  /// No description provided for @photoUpdateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to update photo'**
  String get photoUpdateFailedMessage;

  /// No description provided for @mapTypeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Map type'**
  String get mapTypeSheetTitle;

  /// No description provided for @mapTypeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get mapTypeDefault;

  /// No description provided for @mapTypeSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapTypeSatellite;

  /// No description provided for @mapTypeTerrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get mapTypeTerrain;

  /// No description provided for @phoneHelperSaveSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Added successfully'**
  String get phoneHelperSaveSuccessTitle;

  /// No description provided for @phoneHelperSaveSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'The child\'s phone number has been saved successfully'**
  String get phoneHelperSaveSuccessMessage;

  /// No description provided for @phoneHelperCallActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the call action: {error}'**
  String phoneHelperCallActionFailed(Object error);

  /// No description provided for @phoneHelperOpenDialerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone app'**
  String get phoneHelperOpenDialerFailed;

  /// No description provided for @phoneHelperLaunchCallFailed.
  ///
  /// In en, this message translates to:
  /// **'Phone call failed: {error}'**
  String phoneHelperLaunchCallFailed(Object error);

  /// No description provided for @scheduleRepositoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Schedule not found'**
  String get scheduleRepositoryNotFound;

  /// No description provided for @scheduleRepositoryCurrentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Current schedule not found'**
  String get scheduleRepositoryCurrentNotFound;

  /// No description provided for @scheduleRepositoryHistoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'History record not found'**
  String get scheduleRepositoryHistoryNotFound;

  /// No description provided for @locationRepositoryLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Not logged in. Unable to send location'**
  String get locationRepositoryLoginRequired;

  /// No description provided for @locationRepositoryParentIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Parent account not found'**
  String get locationRepositoryParentIdNotFound;

  /// No description provided for @cupertinoTimePickerDoneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cupertinoTimePickerDoneButton;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
