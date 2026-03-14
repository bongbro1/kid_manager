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
  /// **'Add account'**
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
