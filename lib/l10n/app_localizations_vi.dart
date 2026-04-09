// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get personalInfoTitle => 'ThÃ´ng tin cÃ¡ nhÃ¢n';

  @override
  String get appAppearanceTitle => 'Giao diá»‡n á»©ng dá»¥ng';

  @override
  String get aboutAppTitle => 'Vá» á»©ng dá»¥ng';

  @override
  String get addAccountTitle => 'ThÃªm tÃ i khoáº£n';

  @override
  String get logoutTitle => 'ÄÄƒng xuáº¥t';

  @override
  String get fullNameLabel => 'Há» vÃ  tÃªn';

  @override
  String get fullNameHint => 'Nháº­p há» vÃ  tÃªn';

  @override
  String get phoneLabel => 'Sá»‘ Ä‘iá»‡n thoáº¡i';

  @override
  String get phoneHint => 'vÃ­ dá»¥: +84 012345678';

  @override
  String get genderLabel => 'Giá»›i tÃ­nh';

  @override
  String get genderHint => 'Chá»n giá»›i tÃ­nh';

  @override
  String get genderMaleOption => 'Nam';

  @override
  String get genderFemaleOption => 'Ná»¯';

  @override
  String get genderOtherOption => 'KhÃ¡c';

  @override
  String get birthDateLabel => 'NgÃ y sinh';

  @override
  String get birthDateHint => 'Nháº­p ngÃ y sinh';

  @override
  String get addressLabel => 'Äá»‹a chá»‰';

  @override
  String get addressHint => 'Nháº­p Ä‘á»‹a chá»‰';

  @override
  String get locationTrackingLabel => 'Quyá»n theo dÃµi';

  @override
  String get allowLocationTrackingText => 'Cho phÃ©p Ä‘á»‘i phÆ°Æ¡ng theo dÃµi vá»‹ trÃ­';

  @override
  String get yearsOld => '%d tuá»•i';

  @override
  String get updateSuccessTitle => 'ThÃ nh cÃ´ng';

  @override
  String get updateSuccessMessage => 'Cáº­p nháº­t thÃ´ng tin thÃ nh cÃ´ng';

  @override
  String get updateErrorTitle => 'Tháº¥t báº¡i';

  @override
  String get invalidBirthDate => 'NgÃ y sinh khÃ´ng há»£p lá»‡';

  @override
  String get confirmLogoutQuestion => 'Báº¡n muá»‘n Ä‘Äƒng xuáº¥t?';

  @override
  String get cancelButton => 'Há»§y bá»';

  @override
  String get confirmButton => 'XÃ¡c nháº­n';

  @override
  String get cropPhotoAvatarTitle => 'Chá»‰nh áº£nh Ä‘áº¡i diá»‡n';

  @override
  String get cropPhotoCoverTitle => 'Chá»‰nh áº£nh bÃ¬a';

  @override
  String get cropPhotoDoneButton => 'Xong';

  @override
  String get cropPhotoFailedMessage => 'KhÃ´ng thá»ƒ crop áº£nh';

  @override
  String get languageSetting => 'NgÃ´n ngá»¯';

  @override
  String get vietnamese => 'Tiáº¿ng Viá»‡t';

  @override
  String get english => 'English';

  @override
  String get changeLanguagePrompt =>
      'Thay Ä‘á»•i ngÃ´n ngá»¯, á»©ng dá»¥ng sáº½ khá»Ÿi Ä‘á»™ng láº¡i';

  @override
  String get appAppearanceThemeLabel => 'Chá»§ Ä‘á»';

  @override
  String get appAppearanceSelectThemeTitle => 'Chá»n chá»§ Ä‘á»';

  @override
  String get appAppearanceThemeSystem => 'Theo há»‡ thá»‘ng';

  @override
  String get appAppearanceThemeLight => 'SÃ¡ng';

  @override
  String get appAppearanceThemeDark => 'Tá»‘i';

  @override
  String get appAppearanceSectionApp => 'á»¨NG Dá»¤NG';

  @override
  String get appAppearanceThemeSubtitle => 'Thay Ä‘á»•i giao diá»‡n sÃ¡ng/tá»‘i';

  @override
  String get appAppearanceSectionSecurity => 'Báº¢O Máº¬T';

  @override
  String get appAppearanceChangePasswordTitle => 'Äá»•i máº­t kháº©u';

  @override
  String get appAppearanceChangePasswordSubtitle => 'Cáº­p nháº­t máº­t kháº©u má»›i';

  @override
  String get appAppearanceNotificationsTitle => 'ThÃ´ng bÃ¡o';

  @override
  String get appAppearanceNotificationsSubtitle => 'Quáº£n lÃ½ tÃ¹y chá»n thÃ´ng bÃ¡o';

  @override
  String get addAccountSuccessMessage => 'Táº¡o tÃ i khoáº£n con thÃ nh cÃ´ng';

  @override
  String get addAccountNameRequired => 'Vui lÃ²ng nháº­p tÃªn';

  @override
  String get addAccountAccessLabel => 'Quyá»n truy cáº­p';

  @override
  String get addAccountRoleChild => 'Con';

  @override
  String get addAccountRoleGuardian => 'Phá»¥ huynh';

  @override
  String get addAccountSelectBirthDateTitle => 'Chá»n ngÃ y sinh';

  @override
  String get addAccountSelectButton => 'Chá»n';

  @override
  String get sessionExpiredLoginAgain =>
      'PhiÃªn Ä‘Äƒng nháº­p Ä‘Ã£ háº¿t. Vui lÃ²ng Ä‘Äƒng nháº­p láº¡i.';

  @override
  String userVmLoadUserError(String error) {
    return 'Lá»—i load user: $error';
  }

  @override
  String userVmLoadChildrenError(String error) {
    return 'Lá»—i load children: $error';
  }

  @override
  String userVmLoadMembersError(String error) {
    return 'Lá»—i load members: $error';
  }

  @override
  String get userVmFamilyIdNotFound => 'KhÃ´ng tÃ¬m tháº¥y familyId';

  @override
  String userVmLoadFamilyError(String error) {
    return 'Lá»—i load family: $error';
  }

  @override
  String get userVmUserIdNotFound => 'KhÃ´ng tÃ¬m tháº¥y userId';

  @override
  String get userVmFullNameRequired => 'Há» vÃ  tÃªn khÃ´ng Ä‘Æ°á»£c Ä‘á»ƒ trá»‘ng';

  @override
  String get userVmUpdatePhotoFailed => 'Cáº­p nháº­t áº£nh tháº¥t báº¡i';

  @override
  String subscriptionLoadError(String error) {
    return 'KhÃ´ng táº£i Ä‘Æ°á»£c subscription: $error';
  }

  @override
  String subscriptionWatchError(String error) {
    return 'Theo dÃµi subscription tháº¥t báº¡i: $error';
  }

  @override
  String subscriptionUpdateError(String error) {
    return 'Cáº­p nháº­t subscription tháº¥t báº¡i: $error';
  }

  @override
  String subscriptionActivateError(String error) {
    return 'KÃ­ch hoáº¡t gÃ³i tháº¥t báº¡i: $error';
  }

  @override
  String subscriptionStartTrialError(String error) {
    return 'Báº¯t Ä‘áº§u trial tháº¥t báº¡i: $error';
  }

  @override
  String subscriptionMarkExpiredError(String error) {
    return 'ÄÃ¡nh dáº¥u expired tháº¥t báº¡i: $error';
  }

  @override
  String subscriptionClearError(String error) {
    return 'XÃ³a subscription tháº¥t báº¡i: $error';
  }

  @override
  String get appManagementSyncFailed => 'KhÃ´ng thá»ƒ Ä‘á»“ng bá»™ á»©ng dá»¥ng';

  @override
  String get appManagementUserIdNotFound => 'KhÃ´ng tÃ¬m tháº¥y userId';

  @override
  String zoneStatusAtText(String zoneName, String duration) {
    return 'Ä‘ang á»Ÿ $zoneName â€¢ $duration';
  }

  @override
  String zoneStatusWasAtText(String zoneName) {
    return 'Ä‘Ã£ á»Ÿ $zoneName';
  }

  @override
  String zoneStatusWasAtWithAgoText(String zoneName, String ago) {
    return 'Ä‘Ã£ á»Ÿ $zoneName â€¢ $ago';
  }

  @override
  String get zoneStatusLiveUnavailable =>
      'KhÃ´ng xÃ¡c Ä‘á»‹nh Ä‘Æ°á»£c tráº¡ng thÃ¡i vÃ¹ng hiá»‡n táº¡i';

  @override
  String zoneStatusDurationMinutes(int minutes) {
    return '$minutes phÃºt';
  }

  @override
  String zoneStatusDurationHoursMinutes(int hours, int minutes) {
    return '${hours}g$minutes phÃºt';
  }

  @override
  String get zoneStatusJustNow => 'vá»«a xong';

  @override
  String zoneStatusMinutesAgo(int minutes) {
    return '$minutes phÃºt trÆ°á»›c';
  }

  @override
  String zoneStatusHoursAgo(int hours) {
    return '$hours giá» trÆ°á»›c';
  }

  @override
  String zoneStatusDaysAgo(int days) {
    return '$days ngÃ y trÆ°á»›c';
  }

  @override
  String get otpResendCooldownError => 'Vui lÃ²ng chá» trÆ°á»›c khi gá»­i láº¡i mÃ£';

  @override
  String get otpResendLockedError =>
      'Báº¡n Ä‘Ã£ gá»­i OTP quÃ¡ nhiá»u láº§n. Vui lÃ²ng thá»­ láº¡i sau';

  @override
  String get otpResendMaxError => 'Báº¡n Ä‘Ã£ gá»­i OTP quÃ¡ nhiá»u láº§n';

  @override
  String otpRepositoryLockedMessage(int seconds) {
    return 'Báº¡n Ä‘Ã£ bá»‹ khÃ³a gá»­i OTP. Vui lÃ²ng thá»­ láº¡i sau ${seconds}s';
  }

  @override
  String get authLoginCancelled => 'ÄÄƒng nháº­p Ä‘Ã£ bá»‹ há»§y';

  @override
  String get continueButton => 'Tiáº¿p tá»¥c';

  @override
  String zoneDetailsRadiusLabel(String radius) {
    return 'BÃ¡n kÃ­nh ${radius}m';
  }

  @override
  String get zoneDetailsNoCoordinates => 'KhÃ´ng cÃ³ tá»a Ä‘á»™ Ä‘á»ƒ hiá»ƒn thá»‹ báº£n Ä‘á»“';

  @override
  String birthdaySpecialDayHeadline(String name) {
    return 'Sinh nháº­t cá»§a $name!';
  }

  @override
  String get mapTopBarTitle => 'Vá»‹ trÃ­';

  @override
  String childGroupMarkerCount(int count) {
    return '$count tráº»';
  }

  @override
  String get changePasswordTitle => 'Äá»•i máº­t kháº©u';

  @override
  String get changePasswordSuccessMessage => 'Äá»•i máº­t kháº©u thÃ nh cÃ´ng';

  @override
  String get changePasswordCurrentPasswordLabel => 'Máº­t kháº©u hiá»‡n táº¡i';

  @override
  String get changePasswordCurrentPasswordHint => 'Nháº­p máº­t kháº©u hiá»‡n táº¡i';

  @override
  String get changePasswordNewPasswordLabel => 'Máº­t kháº©u má»›i';

  @override
  String get changePasswordNewPasswordHint => 'Nháº­p máº­t kháº©u má»›i';

  @override
  String get changePasswordConfirmPasswordLabel => 'XÃ¡c nháº­n máº­t kháº©u';

  @override
  String get changePasswordConfirmPasswordHint => 'Nháº­p láº¡i máº­t kháº©u má»›i';

  @override
  String get changePasswordUpdateButton => 'Cáº­p nháº­t máº­t kháº©u';

  @override
  String get memberManagementTitle => 'Quáº£n lÃ½ thÃ nh viÃªn';

  @override
  String get memberManagementAddMemberTitle => 'ThÃªm thÃ nh viÃªn';

  @override
  String get memberManagementAddMemberSubtitle =>
      'Káº¿t ná»‘i thiáº¿t bá»‹ má»›i cá»§a con';

  @override
  String get memberManagementAddNowButton => 'ThÃªm ngay';

  @override
  String get memberManagementFamilyMembersLabel => 'THÃ€NH VIÃŠN GIA ÄÃŒNH';

  @override
  String get memberManagementEmpty => 'ChÆ°a cÃ³ thÃ nh viÃªn';

  @override
  String get memberManagementOnline => 'Äang trá»±c tuyáº¿n';

  @override
  String get memberManagementOffline => 'Ngoáº¡i tuyáº¿n';

  @override
  String get memberManagementMessageButton => 'Nháº¯n tin';

  @override
  String get memberManagementLocationButton => 'Vá»‹ trÃ­';

  @override
  String get userRoleParent => 'Phá»¥ huynh';

  @override
  String get userRoleChild => 'Con';

  @override
  String get userRoleGuardian => 'NgÆ°á»i giÃ¡m há»™';

  @override
  String get aboutAppName => 'My Application';

  @override
  String aboutAppVersionLabel(String version) {
    return 'PhiÃªn báº£n: $version';
  }

  @override
  String get aboutAppDescription =>
      'á»¨ng dá»¥ng giÃºp quáº£n lÃ½ tÃ i khoáº£n, theo dÃµi hoáº¡t Ä‘á»™ng vÃ  cÃ¡ nhÃ¢n hÃ³a tráº£i nghiá»‡m ngÆ°á»i dÃ¹ng.';

  @override
  String get aboutAppCopyright => 'Â© 2026 My Company';

  @override
  String get themeSelectorTitle => 'TÃ¹y chá»‰nh giao diá»‡n';

  @override
  String get themeSelectorSubtitle => 'Chá»n mÃ u chá»§ Ä‘áº¡o vÃ  cháº¿ Ä‘á»™ sÃ¡ng/tá»‘i';

  @override
  String get themeSelectorDarkMode => 'Cháº¿ Ä‘á»™ tá»‘i';

  @override
  String get themeSelectorApplyButton => 'Ãp dá»¥ng giao diá»‡n';

  @override
  String get phoneAuthTitle => 'ÄÄƒng nháº­p báº±ng sá»‘ Ä‘iá»‡n thoáº¡i';

  @override
  String get phoneAuthSendOtpButton => 'Gá»­i mÃ£ OTP';

  @override
  String get phoneAuthOtpTitle => 'Nháº­p mÃ£ xÃ¡c thá»±c';

  @override
  String get phoneAuthOtpInstruction =>
      'Vui lÃ²ng nháº­p mÃ£ OTP Ä‘Æ°á»£c gá»­i Ä‘áº¿n sá»‘ Ä‘iá»‡n thoáº¡i cá»§a báº¡n';

  @override
  String get termsTitle => 'Äiá»u khoáº£n';

  @override
  String get termsNoData => 'KhÃ´ng cÃ³ dá»¯ liá»‡u';

  @override
  String termsLastUpdated(String date) {
    return 'Cáº­p nháº­t láº§n cuá»‘i: $date';
  }

  @override
  String get homeTitle => 'Trang chá»§';

  @override
  String get homeGreeting => 'Xin chÃ o';

  @override
  String get homeManageChildButton => 'Quáº£n lÃ½ con';

  @override
  String get accountNotFound => 'TÃ i khoáº£n khÃ´ng tá»“n táº¡i';

  @override
  String get accountNotActivated => 'TÃ i khoáº£n chÆ°a Ä‘Æ°á»£c kÃ­ch hoáº¡t';

  @override
  String get emailNotRegistered => 'Email chÆ°a Ä‘Äƒng kÃ½';

  @override
  String get noLocationPermission => 'KhÃ´ng cÃ³ quyá»n vá»‹ trÃ­';

  @override
  String get gpsError => 'Lá»—i GPS';

  @override
  String get currentLocationError => 'KhÃ´ng láº¥y Ä‘Æ°á»£c vá»‹ trÃ­ hiá»‡n táº¡i';

  @override
  String get invalidCode => 'MÃ£ khÃ´ng Ä‘Ãºng';

  @override
  String get codeExpired => 'MÃ£ Ä‘Ã£ háº¿t háº¡n';

  @override
  String get tooManyAttempts => 'Nháº­p sai quÃ¡ nhiá»u láº§n';

  @override
  String get unknownError => 'CÃ³ lá»—i xáº£y ra';

  @override
  String get loginFailed => 'ÄÄƒng nháº­p tháº¥t báº¡i';

  @override
  String get weakPassword => 'Máº­t kháº©u quÃ¡ yáº¿u';

  @override
  String get emailInvalid => 'Email khÃ´ng há»£p lá»‡';

  @override
  String get emailInUse => 'Email Ä‘Ã£ Ä‘Æ°á»£c sá»­ dá»¥ng';

  @override
  String get wrongPassword => 'Sai máº­t kháº©u';

  @override
  String get authStartTitle => 'Báº¯t Äáº§u Ngay';

  @override
  String get authStartSubtitle => 'Tiáº¿p tá»¥c vá»›i á»©ng dá»¥ng ngay thÃ´i!';

  @override
  String get authContinueWithGoogle => 'Tiáº¿p tá»¥c vá»›i Google';

  @override
  String get authContinueWithFacebook => 'Tiáº¿p tá»¥c vá»›i Facebook';

  @override
  String get authContinueWithApple => 'Tiáº¿p tá»¥c vá»›i Apple';

  @override
  String get authContinueWithPhone => 'Tiáº¿p tá»¥c vá»›i sá»‘ Ä‘iá»‡n thoáº¡i';

  @override
  String get authLoginButton => 'ÄÄƒng nháº­p';

  @override
  String get authSignupButton => 'ÄÄƒng kÃ½';

  @override
  String get authPrivacyPolicy => 'ChÃ­nh sÃ¡ch báº£o máº­t';

  @override
  String get authTermsOfService => 'Äiá»u khoáº£n dá»‹ch vá»¥';

  @override
  String get authEnterAllInfo => 'Vui lÃ²ng nháº­p Ä‘áº§y Ä‘á»§ thÃ´ng tin';

  @override
  String get authInvalidCredentials => 'ThÃ´ng tin tÃ i khoáº£n khÃ´ng chÃ­nh xÃ¡c';

  @override
  String get authUserProfileLoadFailed => 'KhÃ´ng táº£i Ä‘Æ°á»£c há»“ sÆ¡ ngÆ°á»i dÃ¹ng';

  @override
  String get authGenericError => 'ThÃ´ng bÃ¡o';

  @override
  String get authWelcomeBackTitle => 'CHÃ€O Má»ªNG TRá»ž Láº I';

  @override
  String get authLoginNowSubtitle => 'ÄÄƒng nháº­p ngay!';

  @override
  String get authEnterEmailHint => 'Nháº­p email';

  @override
  String get authEnterPasswordHint => 'Nháº­p máº­t kháº©u';

  @override
  String get authRememberPassword => 'LÆ°u máº­t kháº©u';

  @override
  String get authForgotPassword => 'QuÃªn máº­t kháº©u?';

  @override
  String get authOr => 'Hoáº·c';

  @override
  String get authNoAccount => 'Báº¡n chÆ°a cÃ³ tÃ i khoáº£n, ';

  @override
  String get authSignUpInline => 'Ä‘Äƒng kÃ½';

  @override
  String get authSignupTitle => 'ÄÄ‚NG KÃ\nTÃ€I KHOáº¢N NGAY';

  @override
  String get authSignupSubtitle => 'Kiá»ƒm tra vÃ  quáº£n lÃ­ con cá»§a báº¡n!';

  @override
  String get authPasswordMismatch => 'Máº­t kháº©u xÃ¡c nháº­n khÃ´ng khá»›p';

  @override
  String get authSignupFailed => 'ÄÄƒng kÃ½ tháº¥t báº¡i';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Máº­t kháº©u';

  @override
  String get authConfirmPasswordLabel => 'Nháº­p láº¡i máº­t kháº©u';

  @override
  String get authAgreeTermsPrefix => 'Äá»“ng Ã½ vá»›i Ä‘iá»u khoáº£n, ';

  @override
  String get authAgreeTermsLink => 'táº¡i Ä‘Ã¢y';

  @override
  String get authHaveAccount => 'Báº¡n Ä‘Ã£ cÃ³ tÃ i khoáº£n, ';

  @override
  String get authLoginInline => 'Ä‘Äƒng nháº­p';

  @override
  String get authForgotPasswordTitle => 'QUÃŠN Máº¬T KHáº¨U?';

  @override
  String get authForgotPasswordSubtitle =>
      'Báº¡n Ä‘Ã£ quÃªn máº­t kháº©u? Vui lÃ²ng lÃ m theo cÃ¡c bÆ°á»›c sau Ä‘á»ƒ láº¥y láº¡i máº­t kháº©u cá»§a báº¡n!';

  @override
  String get authEnterYourEmailLabel => 'Nháº­p Email cá»§a báº¡n';

  @override
  String get authContinueButton => 'Tiáº¿p tá»¥c';

  @override
  String get authSendOtpFailed => 'Gá»­i OTP tháº¥t báº¡i';

  @override
  String get otpTitle => 'NHáº¬P MÃƒ OTP';

  @override
  String get otpInstruction =>
      'ChÃºng tÃ´i Ä‘Ã£ gá»­i mÃ£ xÃ¡c minh Ä‘áº¿n Ä‘á»‹a chá»‰ email cá»§a báº¡n';

  @override
  String get otpNeed4Digits => 'Vui lÃ²ng nháº­p Ä‘á»§ 6 sá»‘ OTP';

  @override
  String get otpDigitsOnly => 'OTP chá»‰ Ä‘Æ°á»£c chá»©a sá»‘';

  @override
  String get otpIncorrect => 'OTP khÃ´ng Ä‘Ãºng';

  @override
  String get otpExpired => 'OTP Ä‘Ã£ háº¿t háº¡n';

  @override
  String get otpTooManyAttempts =>
      'Báº¡n Ä‘Ã£ nháº­p sai quÃ¡ 3 láº§n. Vui lÃ²ng chá» 10 phÃºt.';

  @override
  String get otpRequestNotFound => 'KhÃ´ng tÃ¬m tháº¥y yÃªu cáº§u OTP';

  @override
  String otpResendIn(int seconds) {
    return 'Gá»­i láº¡i mÃ£ sau ${seconds}s';
  }

  @override
  String get otpResend => 'Gá»­i láº¡i mÃ£';

  @override
  String get otpVerifyButton => 'XÃ¡c minh';

  @override
  String get authRegisterSuccessMessage => 'ÄÄƒng kÃ½ tÃ i khoáº£n thÃ nh cÃ´ng';

  @override
  String get resetPasswordTitle => 'Äáº¶T Láº I \nMáº¬T KHáº¨U Má»šI';

  @override
  String get resetPasswordSubtitle => 'Äiá»n máº­t kháº©u má»›i cá»§a báº¡n!';

  @override
  String get resetPasswordNewLabel => 'Máº­t kháº©u má»›i';

  @override
  String get resetPasswordConfirmLabel => 'Nháº­p láº¡i máº­t kháº©u';

  @override
  String get resetPasswordConfirmMismatch => 'Máº­t kháº©u nháº­p láº¡i khÃ´ng khá»›p';

  @override
  String get resetPasswordRuleTitle => 'Máº­t kháº©u cáº§n cÃ³';

  @override
  String get resetPasswordRuleMinLength => 'Ãt nháº¥t 8 kÃ½ tá»±';

  @override
  String get resetPasswordRuleUppercase => 'CÃ³ chá»¯ hoa';

  @override
  String get resetPasswordRuleLowercase => 'CÃ³ chá»¯ thÆ°á»ng';

  @override
  String get resetPasswordRuleNumber => 'CÃ³ sá»‘';

  @override
  String get resetPasswordCompleteButton => 'HoÃ n táº¥t';

  @override
  String get resetPasswordSuccessMessage => 'Äáº·t láº¡i máº­t kháº©u thÃ nh cÃ´ng';

  @override
  String get authCompleteTitle => 'HoÃ n táº¥t!';

  @override
  String get authRegisterCongratsMessage =>
      'ChÃºc má»«ng! Báº¡n Ä‘Ã£ Ä‘Äƒng kÃ½ thÃ nh cÃ´ng';

  @override
  String get authBackToLogin => 'Vá» trang Ä‘Äƒng nháº­p';

  @override
  String get flashWelcomeTitle => 'ChÃ o má»«ng Ä‘áº¿n vá»›i á»©ng dá»¥ng';

  @override
  String get flashWelcomeSubtitle => 'á»¨ng dá»¥ng quáº£n lÃ½ con';

  @override
  String get flashNext => 'Tiáº¿p';

  @override
  String get scheduleScreenTitle => 'Lá»‹ch trÃ¬nh';

  @override
  String get scheduleNoChild => 'ChÆ°a cÃ³ bÃ©';

  @override
  String get scheduleFormTitleHint => 'TÃªn lá»‹ch trÃ¬nh';

  @override
  String get scheduleFormDescriptionHint => 'MÃ´ táº£';

  @override
  String get scheduleAddHeaderTitle => 'ThÃªm sá»± kiá»‡n';

  @override
  String get scheduleFormDateLabel => 'NgÃ y';

  @override
  String get scheduleFormStartTimeLabel => 'Giá» báº¯t Ä‘áº§u';

  @override
  String get scheduleFormEndTimeLabel => 'Giá» káº¿t thÃºc';

  @override
  String get scheduleFormEndTimeInvalid => 'Giá» káº¿t thÃºc pháº£i lá»›n hÆ¡n';

  @override
  String get scheduleFormSavingButton => 'Äang lÆ°u...';

  @override
  String get scheduleAddSubmitButton => 'Táº¡o lá»‹ch trÃ¬nh';

  @override
  String get scheduleAddSuccessMessage => 'Báº¡n Ä‘Ã£ táº¡o lá»‹ch trÃ¬nh thÃ nh cÃ´ng';

  @override
  String get scheduleDialogWarningTitle => 'Cáº£nh bÃ¡o';

  @override
  String get scheduleEditHeaderTitle => 'Chá»‰nh sá»­a lá»‹ch trÃ¬nh';

  @override
  String get scheduleEditSubmitButton => 'LÆ°u lá»‹ch trÃ¬nh';

  @override
  String get scheduleEditSuccessMessage => 'Báº¡n Ä‘Ã£ sá»­a thÃ nh cÃ´ng';

  @override
  String get scheduleSelectChildLabel => 'Chá»n bÃ©';

  @override
  String get scheduleYourChild => 'BÃ© cá»§a báº¡n';

  @override
  String get schedulePleaseSelectChild => 'Vui lÃ²ng chá»n bÃ©';

  @override
  String get scheduleExportTitle => 'Xuáº¥t file Excel';

  @override
  String get scheduleExportDateRangeLabel => 'Khoáº£ng thá»i gian';

  @override
  String get scheduleExportColumnsHint =>
      'File xuáº¥t sáº½ gá»“m cÃ¡c cá»™t: title, description, date, start, end';

  @override
  String get scheduleExportLoadingButton => 'Äang xuáº¥t...';

  @override
  String get scheduleExportSubmitButton => 'Xuáº¥t file';

  @override
  String get scheduleExportInvalidDateRange =>
      'NgÃ y báº¯t Ä‘áº§u khÃ´ng Ä‘Æ°á»£c lá»›n hÆ¡n ngÃ y káº¿t thÃºc';

  @override
  String get scheduleExportNoDataInRange =>
      'KhÃ´ng cÃ³ lá»‹ch trong khoáº£ng ngÃ y Ä‘Ã£ chá»n';

  @override
  String get scheduleExportSaveCanceled => 'Báº¡n Ä‘Ã£ huá»· lÆ°u file';

  @override
  String scheduleExportSuccessMessage(int count) {
    return 'Xuáº¥t file Excel thÃ nh cÃ´ng ($count lá»‹ch)';
  }

  @override
  String scheduleExportFailed(String error) {
    return 'Xuáº¥t file tháº¥t báº¡i: $error';
  }

  @override
  String get scheduleImportTitle => 'ThÃªm file Excel';

  @override
  String get scheduleTemplateDownloadButton => 'Táº£i file máº«u';

  @override
  String get scheduleTemplateSaveCanceled => 'Báº¡n Ä‘Ã£ huá»· lÆ°u file máº«u';

  @override
  String get scheduleTemplateSavedSuccess => 'ÄÃ£ lÆ°u file máº«u thÃ nh cÃ´ng';

  @override
  String scheduleTemplateDownloadFailed(String error) {
    return 'Táº£i file máº«u tháº¥t báº¡i: $error';
  }

  @override
  String get scheduleImportCannotReadFile => 'KhÃ´ng Ä‘á»c Ä‘Æ°á»£c file, thá»­ láº¡i.';

  @override
  String get scheduleImportMissingOwner =>
      'KhÃ´ng xÃ¡c Ä‘á»‹nh Ä‘Æ°á»£c chá»§ sá»Ÿ há»¯u lá»‹ch';

  @override
  String get scheduleImportNoValidItems => 'KhÃ´ng cÃ³ lá»‹ch há»£p lá»‡ Ä‘á»ƒ import.';

  @override
  String get scheduleImportSuccessMessage => 'ThÃªm lá»‹ch thÃ nh cÃ´ng';

  @override
  String scheduleImportFailed(String error) {
    return 'Import tháº¥t báº¡i: $error';
  }

  @override
  String scheduleImportAddCount(int count) {
    return 'ThÃªm $count lá»‹ch';
  }

  @override
  String get scheduleImportPickFileButton => 'Chá»n file Excel';

  @override
  String get scheduleImportPickAnotherFileButton => 'Chá»n file khÃ¡c';

  @override
  String scheduleImportSelectedFile(String fileName) {
    return 'ÄÃ£ chá»n: $fileName';
  }

  @override
  String get scheduleImportChangeFileButton => 'Äá»•i file';

  @override
  String scheduleImportSummaryOk(int count) {
    return 'OK: $count';
  }

  @override
  String scheduleImportSummaryDuplicate(int count) {
    return 'TrÃ¹ng: $count';
  }

  @override
  String scheduleImportSummaryError(int count) {
    return 'Lá»—i: $count';
  }

  @override
  String get scheduleImportPreviewTitle => 'Xem trÆ°á»›c dá»¯ liá»‡u';

  @override
  String get scheduleImportStatusOk => 'OK';

  @override
  String get scheduleImportStatusError => 'Lá»–I';

  @override
  String get scheduleImportStatusDuplicate => 'TRÃ™NG';

  @override
  String scheduleImportRowError(int row, String error) {
    return 'DÃ²ng $row: $error';
  }

  @override
  String get birthdayMemberFallback => 'ThÃ nh viÃªn';

  @override
  String birthdayWishSelfWithAge(int age) {
    return 'ChÃºc má»«ng sinh nháº­t tÃ´i. ChÃ o tuá»•i $age tháº­t rá»±c rá»¡, bÃ¬nh an vÃ  nhiá»u niá»m vui.';
  }

  @override
  String get birthdayWishSelfDefault =>
      'ChÃºc má»«ng sinh nháº­t tÃ´i. ChÃºc mÃ¬nh cÃ³ má»™t ngÃ y tháº­t vui vÃ  Ä‘Ã¡ng nhá»›.';

  @override
  String birthdayWishOtherWithAge(String name, int age) {
    return 'ChÃºc má»«ng sinh nháº­t $name. ChÃºc báº¡n bÆ°á»›c sang tuá»•i $age luÃ´n máº¡nh khá»e, vui váº» vÃ  gáº·p nhiá»u Ä‘iá»u may máº¯n.';
  }

  @override
  String birthdayWishOtherDefault(String name) {
    return 'ChÃºc má»«ng sinh nháº­t $name. ChÃºc báº¡n luÃ´n vui váº», máº¡nh khá»e vÃ  cÃ³ tháº­t nhiá»u niá»m vui.';
  }

  @override
  String get birthdayViewWishButton => 'Xem lá»i chÃºc';

  @override
  String get birthdaySendWishButton => 'Gá»­i lá»i chÃºc';

  @override
  String get birthdayCongratsYouTitle => 'ChÃºc má»«ng sinh nháº­t báº¡n';

  @override
  String get birthdayCongratsTitle => 'ChÃºc má»«ng sinh nháº­t';

  @override
  String get birthdayTodayIsYourDay => 'HÃ´m nay lÃ  ngÃ y cá»§a báº¡n';

  @override
  String birthdayTurnsAge(int age) {
    return 'TrÃ²n $age tuá»•i';
  }

  @override
  String get birthdaySuggestionTitle => 'Lá»i chÃºc gá»£i Ã½';

  @override
  String birthdayYouEnteringAge(int age) {
    return 'HÃ´m nay báº¡n bÆ°á»›c sang tuá»•i $age. ChÃºc báº¡n cÃ³ má»™t ngÃ y tháº­t tÆ°Æ¡i vui, nháº¹ nhÃ ng vÃ  Ä‘Ã¡ng nhá»›.';
  }

  @override
  String get birthdayYouSpecialDay =>
      'HÃ´m nay lÃ  ngÃ y Ä‘áº·c biá»‡t cá»§a báº¡n. ChÃºc báº¡n cÃ³ tháº­t nhiá»u niá»m vui vÃ  nÄƒng lÆ°á»£ng tÃ­ch cá»±c.';

  @override
  String birthdayTodayIsBirthdayWithAge(String name, int age) {
    return 'HÃ´m nay lÃ  sinh nháº­t cá»§a $name, trÃ²n $age tuá»•i.';
  }

  @override
  String birthdayTodayIsBirthday(String name) {
    return 'HÃ´m nay lÃ  sinh nháº­t cá»§a $name.';
  }

  @override
  String get birthdayCountdownTitle => 'âœ¨ Sáº¯p tá»›i sinh nháº­t';

  @override
  String get birthdayCountdownSelfTitle => 'âœ¨ Sáº¯p tá»›i sinh nháº­t cá»§a báº¡n';

  @override
  String get birthdayCountdownTomorrowChip => 'NgÃ y mai';

  @override
  String birthdayCountdownDaysChip(int days) {
    return 'CÃ²n $days ngÃ y';
  }

  @override
  String birthdayCountdownOtherBody(String name, int days) {
    return 'Chá»‰ cÃ²n $days ngÃ y ná»¯a lÃ  Ä‘áº¿n sinh nháº­t cá»§a $name.';
  }

  @override
  String birthdayCountdownOtherBodyTomorrow(String name) {
    return 'NgÃ y mai lÃ  sinh nháº­t cá»§a $name.';
  }

  @override
  String birthdayCountdownSelfBody(int days) {
    return 'Chá»‰ cÃ²n $days ngÃ y ná»¯a lÃ  Ä‘áº¿n sinh nháº­t cá»§a báº¡n.';
  }

  @override
  String get birthdayCountdownSelfBodyTomorrow =>
      'NgÃ y mai lÃ  sinh nháº­t cá»§a báº¡n.';

  @override
  String get birthdayCountdownSuggestionTitle => 'Gá»£i Ã½ chuáº©n bá»‹';

  @override
  String birthdayCountdownSuggestionOther(String name) {
    return 'Báº¡n cÃ³ thá»ƒ chuáº©n bá»‹ lá»i chÃºc, quÃ  táº·ng hoáº·c má»™t Ä‘iá»u báº¥t ngá» cho $name ngay tá»« bÃ¢y giá».';
  }

  @override
  String get birthdayCountdownSuggestionSelf =>
      'Báº¡n cÃ³ thá»ƒ chuáº©n bá»‹ lá»i chÃºc, mÃ³n quÃ  nhá» hoáº·c má»™t Ä‘iá»u báº¥t ngá» cho chÃ­nh mÃ¬nh ngay tá»« bÃ¢y giá».';

  @override
  String get birthdayCountdownPlanButton => 'Chuáº©n bá»‹ lá»i chÃºc';

  @override
  String birthdayCopiedFallback(String name) {
    return 'KhÃ´ng tÃ¬m tháº¥y chat gia Ä‘Ã¬nh. ÄÃ£ sao chÃ©p lá»i chÃºc cho $name.';
  }

  @override
  String get birthdayCloseButton => 'ÄÃ³ng';

  @override
  String get birthdayAwesomeButton => 'Tuyá»‡t vá»i';

  @override
  String get familyChatLoadingTitle => 'Äang táº£i cuá»™c trÃ² chuyá»‡n';

  @override
  String get familyChatTitle => 'TrÃ² chuyá»‡n gia Ä‘Ã¬nh';

  @override
  String get familyChatTitleLarge => 'TrÃ² chuyá»‡n gia Ä‘Ã¬nh';

  @override
  String familyChatSendFailed(String error) {
    return 'Gá»­i tin nháº¯n tháº¥t báº¡i: $error';
  }

  @override
  String get familyChatYou => 'Báº¡n';

  @override
  String get familyChatMemberFallback => 'ThÃ nh viÃªn';

  @override
  String get familyChatLoadingMembers => 'Äang táº£i thÃ nh viÃªn...';

  @override
  String get familyChatNoMembersFound => 'KhÃ´ng tÃ¬m tháº¥y thÃ nh viÃªn';

  @override
  String get familyChatOneMember => '1 thÃ nh viÃªn';

  @override
  String familyChatManyMembers(int count) {
    return '$count thÃ nh viÃªn';
  }

  @override
  String get familyChatCannotLoadMessages => 'KhÃ´ng thá»ƒ táº£i tin nháº¯n';

  @override
  String get familyChatNoMessagesYet =>
      'ChÆ°a cÃ³ tin nháº¯n nÃ o. HÃ£y báº¯t Ä‘áº§u cuá»™c trÃ² chuyá»‡n.';

  @override
  String get familyChatStatusFailed => 'tháº¥t báº¡i';

  @override
  String get familyChatStatusSending => 'Ä‘ang gá»­i...';

  @override
  String get familyChatTypeMessageHint => 'Nháº­p tin nháº¯n...';

  @override
  String familyChatMemberCountOverflow(String names, int extra) {
    return '$names +$extra';
  }

  @override
  String get notificationScreenTitle => 'ThÃ´ng bÃ¡o';

  @override
  String get notificationDateToday => 'HÃ”M NAY';

  @override
  String get notificationDateYesterday => 'HÃ”M QUA';

  @override
  String get notificationFilterTitle => 'Lá»c thÃ´ng bÃ¡o';

  @override
  String get notificationFilterAll => 'Táº¥t cáº£';

  @override
  String get notificationFilterActivity => 'Hoáº¡t Ä‘á»™ng';

  @override
  String get notificationFilterAlert => 'Cáº£nh bÃ¡o';

  @override
  String get notificationFilterReminder => 'Nháº¯c nhá»Ÿ';

  @override
  String get notificationFilterSystem => 'ThÃ´ng bÃ¡o há»‡ thá»‘ng';

  @override
  String get notificationSearchHint => 'TÃ¬m thÃ´ng bÃ¡o';

  @override
  String get notificationJustNow => 'Vá»«a xong';

  @override
  String notificationMinutesAgo(int minutes) {
    return '${minutes}p trÆ°á»›c';
  }

  @override
  String notificationHoursAgo(int hours) {
    return '${hours}h trÆ°á»›c';
  }

  @override
  String get notificationDetailTitle => 'Chi tiáº¿t thÃ´ng bÃ¡o';

  @override
  String get notificationDetailSectionTitle => 'CHI TIáº¾T';

  @override
  String get accessibilityNoticeBarrierLabel => 'Há»™p thoáº¡i thÃ´ng bÃ¡o';

  @override
  String get accessibilityImageModalBarrierLabel => 'TrÃ¬nh xem áº£nh';

  @override
  String get notificationChildFallback => 'BÃ©';

  @override
  String get notificationChildInfoNotFound => 'KhÃ´ng tÃ¬m tháº¥y thÃ´ng tin cá»§a bÃ©';

  @override
  String get notificationMapLocationNotFound =>
      'KhÃ´ng tÃ¬m tháº¥y vá»‹ trÃ­ Ä‘á»ƒ má»Ÿ báº£n Ä‘á»“';

  @override
  String get notificationTrackingDetailNotFound =>
      'KhÃ´ng tÃ¬m tháº¥y thÃ´ng tin hÃ nh trÃ¬nh cá»§a bÃ©';

  @override
  String get notificationTrackingUnknownValue => 'KhÃ´ng rÃµ';

  @override
  String get notificationTrackingChildLabel => 'BÃ©';

  @override
  String get notificationTrackingRouteLabel => 'Tuyáº¿n Ä‘Æ°á»ng';

  @override
  String get notificationTrackingDistanceToRouteLabel =>
      'Khoáº£ng cÃ¡ch tá»›i tuyáº¿n';

  @override
  String get notificationTrackingHazardLabel => 'VÃ¹ng nguy hiá»ƒm';

  @override
  String get notificationTrackingStationaryLabel => 'Äá»©ng yÃªn';

  @override
  String get notificationTrackingTimeLabel => 'Thá»i Ä‘iá»ƒm';

  @override
  String get notificationTrackingOpenHint =>
      'Má»Ÿ trang theo dÃµi Ä‘á»ƒ xem vá»‹ trÃ­ hiá»‡n táº¡i cá»§a bÃ©, tuyáº¿n Ä‘ang bÃ¡m vÃ  toÃ n bá»™ tráº¡ng thÃ¡i hÃ nh trÃ¬nh trÃªn báº£n Ä‘á»“.';

  @override
  String get notificationTrackingOpenButton => 'Má»Ÿ theo dÃµi hÃ nh trÃ¬nh';

  @override
  String get notificationTrackingStatusOffRoute => 'Lá»‡ch tuyáº¿n';

  @override
  String get notificationTrackingStatusBackOnRoute => 'Quay láº¡i tuyáº¿n';

  @override
  String get notificationTrackingStatusReturnedToStart => 'Vá» Ä‘iá»ƒm Ä‘áº§u';

  @override
  String get notificationTrackingStatusStationary => 'Äá»©ng yÃªn quÃ¡ lÃ¢u';

  @override
  String get notificationTrackingStatusArrived => 'ÄÃ£ Ä‘áº¿n nÆ¡i';

  @override
  String get notificationTrackingStatusDanger => 'Nguy hiá»ƒm';

  @override
  String get notificationTrackingStatusDefault => 'Safe Route';

  @override
  String get notificationTrackingHeadlineOffRoute =>
      'BÃ© Ä‘ang Ä‘i lá»‡ch khá»i tuyáº¿n Ä‘Ã£ chá»n';

  @override
  String get notificationTrackingHeadlineBackOnRoute =>
      'BÃ© Ä‘Ã£ quay láº¡i tuyáº¿n an toÃ n';

  @override
  String get notificationTrackingHeadlineReturnedToStart =>
      'BÃ© Ä‘ang quay láº¡i gáº§n Ä‘iá»ƒm xuáº¥t phÃ¡t';

  @override
  String get notificationTrackingHeadlineStationary =>
      'BÃ© Ä‘ang Ä‘á»©ng yÃªn lÃ¢u hÆ¡n bÃ¬nh thÆ°á»ng';

  @override
  String get notificationTrackingHeadlineArrived => 'BÃ© Ä‘Ã£ Ä‘áº¿n nÆ¡i an toÃ n';

  @override
  String get notificationTrackingHeadlineDanger =>
      'BÃ© Ä‘ang Ä‘i vÃ o vÃ¹ng nguy hiá»ƒm';

  @override
  String notificationTrackingFallbackOffRoute(String routeName) {
    return 'Há»‡ thá»‘ng phÃ¡t hiá»‡n bÃ© Ä‘Ã£ ra ngoÃ i hÃ nh lang an toÃ n cá»§a tuyáº¿n $routeName.';
  }

  @override
  String notificationTrackingFallbackBackOnRoute(String routeName) {
    return 'Há»‡ thá»‘ng ghi nháº­n bÃ© Ä‘Ã£ quay láº¡i hÃ nh lang an toÃ n cá»§a tuyáº¿n $routeName.';
  }

  @override
  String notificationTrackingFallbackReturnedToStart(String routeName) {
    return 'BÃ© Ä‘ang quay láº¡i gáº§n vá»‹ trÃ­ xuáº¥t phÃ¡t cá»§a tuyáº¿n $routeName.';
  }

  @override
  String notificationTrackingFallbackStationary(String routeName) {
    return 'BÃ© Ä‘Ã£ Ä‘á»©ng gáº§n cÃ¹ng má»™t vá»‹ trÃ­ quÃ¡ lÃ¢u khi Ä‘ang Ä‘i trÃªn $routeName.';
  }

  @override
  String notificationTrackingFallbackArrived(String routeName) {
    return 'BÃ© Ä‘Ã£ Ä‘áº¿n Ä‘iá»ƒm Ä‘Ã­ch cá»§a $routeName.';
  }

  @override
  String get notificationTrackingFallbackDangerGeneric =>
      'BÃ© Ä‘Ã£ Ä‘i vÃ o má»™t vÃ¹ng nguy hiá»ƒm trÃªn hÃ nh trÃ¬nh hiá»‡n táº¡i.';

  @override
  String notificationTrackingFallbackDangerWithHazard(
    String hazardName,
    String routeName,
  ) {
    return 'BÃ© Ä‘Ã£ Ä‘i vÃ o $hazardName khi Ä‘ang theo tuyáº¿n $routeName.';
  }

  @override
  String notificationScheduleCreatedTitle(String childName) {
    return 'Lá»‹ch trÃ¬nh má»›i cá»§a $childName';
  }

  @override
  String notificationScheduleUpdatedTitle(String childName) {
    return 'Lá»‹ch trÃ¬nh cá»§a $childName Ä‘Ã£ thay Ä‘á»•i';
  }

  @override
  String notificationScheduleDeletedTitle(String childName) {
    return 'Lá»‹ch trÃ¬nh cá»§a $childName Ä‘Ã£ bá»‹ xÃ³a';
  }

  @override
  String notificationScheduleRestoredTitle(String childName) {
    return 'Lá»‹ch trÃ¬nh cá»§a $childName Ä‘Ã£ Ä‘Æ°á»£c khÃ´i phá»¥c';
  }

  @override
  String notificationZoneEnteredDangerTitle(String childName) {
    return '$childName Ä‘Ã£ vÃ o vÃ¹ng nguy hiá»ƒm';
  }

  @override
  String notificationZoneExitedSafeTitle(String childName) {
    return '$childName Ä‘Ã£ rá»i vÃ¹ng an toÃ n';
  }

  @override
  String notificationZoneExitedDangerTitle(String childName) {
    return '$childName Ä‘Ã£ rá»i vÃ¹ng nguy hiá»ƒm';
  }

  @override
  String scheduleImportRowTitle(int row, String title) {
    return 'DÃ²ng $row: $title';
  }

  @override
  String get scheduleImportDuplicateInSystem =>
      'TrÃ¹ng vá»›i dá»¯ liá»‡u Ä‘Ã£ cÃ³ trÃªn há»‡ thá»‘ng';

  @override
  String get scheduleImportDuplicateInFile => 'TrÃ¹ng trong file';

  @override
  String get scheduleHistoryTitle => 'Lá»‹ch sá»­ chá»‰nh sá»­a';

  @override
  String get scheduleHistoryEmpty => 'ChÆ°a cÃ³ lá»‹ch sá»­ chá»‰nh sá»­a';

  @override
  String get scheduleHistoryToday => 'HÃ´m nay';

  @override
  String get scheduleHistoryYesterday => 'HÃ´m qua';

  @override
  String get scheduleHistoryRestoreDialogTitle => 'KhÃ´i phá»¥c lá»‹ch trÃ¬nh';

  @override
  String get scheduleHistoryRestoreDialogMessage =>
      'Báº¡n cÃ³ cháº¯c muá»‘n khÃ´i phá»¥c phiÃªn báº£n nÃ y khÃ´ng?';

  @override
  String get scheduleHistoryRestoreButton => 'KhÃ´i phá»¥c';

  @override
  String get scheduleHistoryRestoringButton => 'Äang khÃ´i phá»¥c...';

  @override
  String get scheduleHistoryRestoreSuccessMessage =>
      'Báº¡n Ä‘Ã£ khÃ´i phá»¥c thÃ nh cÃ´ng';

  @override
  String scheduleHistoryRestoreFailed(String error) {
    return 'KhÃ´i phá»¥c tháº¥t báº¡i: $error';
  }

  @override
  String scheduleHistoryEditedAt(String time) {
    return 'ÄÃ£ sá»­a lÃºc $time';
  }

  @override
  String get scheduleHistoryLabelTitle => 'TÃªn lá»‹ch trÃ¬nh:';

  @override
  String get scheduleHistoryLabelDescription => 'MÃ´ táº£:';

  @override
  String get scheduleHistoryLabelDate => 'NgÃ y:';

  @override
  String get scheduleHistoryLabelTime => 'Thá»i gian:';

  @override
  String get scheduleDrawerMenuTitle => 'Menu';

  @override
  String get scheduleCreateButtonAddEvent => '+ ThÃªm sá»± kiá»‡n';

  @override
  String get schedulePeriodTitle => 'Thá»i gian';

  @override
  String get schedulePeriodMorning => 'SÃ¡ng';

  @override
  String get schedulePeriodAfternoon => 'Chiá»u';

  @override
  String get schedulePeriodEvening => 'Tá»‘i';

  @override
  String get scheduleCalendarFormatMonth => 'ThÃ¡ng';

  @override
  String get scheduleCalendarFormatWeek => 'Tuáº§n';

  @override
  String scheduleCalendarMonthLabel(int month) {
    return 'ThÃ¡ng $month';
  }

  @override
  String get scheduleWeekdayMon => 'T2';

  @override
  String get scheduleWeekdayTue => 'T3';

  @override
  String get scheduleWeekdayWed => 'T4';

  @override
  String get scheduleWeekdayThu => 'T5';

  @override
  String get scheduleWeekdayFri => 'T6';

  @override
  String get scheduleWeekdaySat => 'T7';

  @override
  String get scheduleWeekdaySun => 'CN';

  @override
  String get scheduleNoEventsInDay => 'KhÃ´ng cÃ³ lá»‹ch trong ngÃ y';

  @override
  String get scheduleDeleteTitle => 'XÃ³a lá»‹ch trÃ¬nh';

  @override
  String get scheduleDeleteConfirmMessage => 'Báº¡n cÃ³ cháº¯c muá»‘n xÃ³a?';

  @override
  String get scheduleDeleteSuccessMessage => 'Báº¡n Ä‘Ã£ xÃ³a thÃ nh cÃ´ng';

  @override
  String scheduleDeleteFailed(String error) {
    return 'XÃ³a tháº¥t báº¡i: $error';
  }

  @override
  String get memoryDayTitle => 'NgÃ y Ä‘Ã¡ng nhá»›';

  @override
  String get memoryDayEmpty => 'ChÆ°a cÃ³ ngÃ y Ä‘Ã¡ng nhá»›';

  @override
  String get memoryDayDeleteTitle => 'XÃ³a ngÃ y Ä‘Ã¡ng nhá»›';

  @override
  String get memoryDayDeleteConfirmMessage => 'Báº¡n cÃ³ cháº¯c muá»‘n xÃ³a?';

  @override
  String get memoryDayDeleteSuccessMessage => 'Báº¡n Ä‘Ã£ xÃ³a thÃ nh cÃ´ng';

  @override
  String get memoryDayDeleteFailedMessage => 'XÃ³a tháº¥t báº¡i, vui lÃ²ng thá»­ láº¡i';

  @override
  String memoryDayDeleteFailedWithError(String error) {
    return 'XÃ³a tháº¥t báº¡i: $error';
  }

  @override
  String memoryDayDaysPassed(int days) {
    return 'ÄÃ£ qua $days ngÃ y';
  }

  @override
  String get memoryDayToday => 'HÃ´m nay';

  @override
  String memoryDayDaysLeft(int days) {
    return 'CÃ²n $days ngÃ y';
  }

  @override
  String memoryDayDateText(String date) {
    return 'NgÃ y: $date';
  }

  @override
  String memoryDayDateRepeatText(String date) {
    return 'NgÃ y: $date (láº·p láº¡i háº±ng nÄƒm)';
  }

  @override
  String get memoryDayUnsavedTitle => 'ChÆ°a lÆ°u';

  @override
  String get memoryDayUnsavedExitMessage =>
      'Báº¡n chÆ°a lÆ°u, báº¡n cÃ³ cháº¯c muá»‘n thoÃ¡t?';

  @override
  String get memoryDayFormTitleLabel => 'TiÃªu Ä‘á»';

  @override
  String get memoryDayFormDateLabel => 'NgÃ y';

  @override
  String get memoryDayFormNoteLabel => 'Ghi chÃº';

  @override
  String get memoryDayReminderLabel => 'Nháº¯c nhá»Ÿ trÆ°á»›c';

  @override
  String get memoryDayReminderNone => 'KhÃ´ng nháº¯c';

  @override
  String get memoryDayReminderOneDay => 'TrÆ°á»›c 1 ngÃ y';

  @override
  String get memoryDayReminderThreeDays => 'TrÆ°á»›c 3 ngÃ y';

  @override
  String get memoryDayReminderSevenDays => 'TrÆ°á»›c 7 ngÃ y';

  @override
  String get memoryDayRepeatYearlyLabel => 'Láº·p láº¡i hÃ ng nÄƒm';

  @override
  String get memoryDayEditHeaderTitle => 'Chá»‰nh sá»­a ngÃ y Ä‘Ã¡ng nhá»›';

  @override
  String get memoryDayAddHeaderTitle => 'ThÃªm ngÃ y Ä‘Ã¡ng nhá»›';

  @override
  String get memoryDayEditSuccessMessage => 'Báº¡n Ä‘Ã£ lÆ°u thay Ä‘á»•i thÃ nh cÃ´ng';

  @override
  String get memoryDayAddSuccessMessage =>
      'Báº¡n Ä‘Ã£ thÃªm ngÃ y Ä‘Ã¡ng nhá»› thÃ nh cÃ´ng';

  @override
  String get memoryDaySaveFailedMessage => 'ÄÃ£ cÃ³ lá»—i xáº£y ra, vui lÃ²ng thá»­ láº¡i';

  @override
  String get memoryDaySavingButton => 'Äang lÆ°u...';

  @override
  String get memoryDaySaveChangesButton => 'LÆ°u thay Ä‘á»•i';

  @override
  String get memoryDayAddButton => 'ThÃªm ngÃ y Ä‘Ã¡ng nhá»›';

  @override
  String get memoryDayEditAction => 'Sá»­a';

  @override
  String get memoryDayDeleteAction => 'XÃ³a';

  @override
  String get notificationsEmptyTitle => 'ChÆ°a cÃ³ thÃ´ng bÃ¡o';

  @override
  String get notificationsEmptySubtitle =>
      'CÃ¡c thÃ´ng bÃ¡o má»›i sáº½ xuáº¥t hiá»‡n táº¡i Ä‘Ã¢y';

  @override
  String get notificationsDefaultChildName => 'BÃ©';

  @override
  String get notificationsNoTitle => 'KhÃ´ng cÃ³ tiÃªu Ä‘á»';

  @override
  String get notificationsActionCreated => 'ÄÃ£ thÃªm';

  @override
  String get notificationsActionUpdated => 'ÄÃ£ chá»‰nh sá»­a';

  @override
  String get notificationsActionDeleted => 'ÄÃ£ xÃ³a';

  @override
  String get notificationsActionRestored => 'ÄÃ£ khÃ´i phá»¥c';

  @override
  String get notificationsActionChanged => 'ÄÃ£ thay Ä‘á»•i';

  @override
  String get notificationsScheduleTitleLabel => 'TÃªn lá»‹ch';

  @override
  String get notificationsChildNameLabel => 'TÃªn bÃ©';

  @override
  String get notificationsDateLabel => 'NgÃ y';

  @override
  String get notificationsTimeLabel => 'Thá»i gian';

  @override
  String get notificationsViewScheduleButton => 'Xem lá»‹ch';

  @override
  String get notificationsRepeatLabel => 'Láº·p láº¡i';

  @override
  String get notificationsRepeatYearly => 'Háº±ng nÄƒm';

  @override
  String get notificationsRepeatNone => 'KhÃ´ng láº·p láº¡i';

  @override
  String get notificationsImportOperatorLabel => 'NgÆ°á»i thao tÃ¡c';

  @override
  String get notificationsChildLabel => 'BÃ©';

  @override
  String get notificationsImportAddedCountLabel => 'Sá»‘ lá»‹ch Ä‘Ã£ thÃªm';

  @override
  String get notificationsActorParent => 'Ba/Máº¹';

  @override
  String get notificationsActorChild => 'Con';

  @override
  String get notificationsBlockedAccountLabel => 'TÃ i khoáº£n';

  @override
  String get notificationsBlockedAppLabel => 'á»¨ng dá»¥ng';

  @override
  String get notificationsBlockedTimeLabel => 'Thá»i Ä‘iá»ƒm';

  @override
  String get notificationsBlockedAllowedWindowLabel => 'Khung giá» cho phÃ©p';

  @override
  String get notificationsBlockedWarningMessage =>
      'á»¨ng dá»¥ng Ä‘Ã£ bá»‹ cháº·n tá»± Ä‘á»™ng bá»Ÿi há»‡ thá»‘ng.';

  @override
  String get notificationsBlockedViewConfigButton => 'Xem cáº¥u hÃ¬nh thá»i gian';

  @override
  String get notificationsRemovedDeviceOfLabel => 'Thiáº¿t bá»‹ cá»§a';

  @override
  String get notificationsRemovedAppLabel => 'á»¨ng dá»¥ng Ä‘Ã£ gá»¡';

  @override
  String get notificationsRemovedAtLabel => 'Thá»i Ä‘iá»ƒm gá»¡';

  @override
  String get notificationsRemovedWarningMessage =>
      'á»¨ng dá»¥ng Ä‘Ã£ bá»‹ gá»¡ khá»i thiáº¿t bá»‹. HÃ£y kiá»ƒm tra náº¿u Ä‘Ã¢y lÃ  á»©ng dá»¥ng bá»‹ quáº£n lÃ½.';

  @override
  String get notificationsRemovedViewAppsButton => 'Xem danh sÃ¡ch á»©ng dá»¥ng';

  @override
  String notificationsZoneDangerEnterDescription(
    String childName,
    String zoneName,
    String time,
  ) {
    return 'Vá»‹ trÃ­ cá»§a $childName Ä‘Ã£ Ä‘Æ°á»£c ghi nháº­n táº¡i $zoneName. Há»‡ thá»‘ng ghi nháº­n bÃ© Ä‘Ã£ vÃ o vÃ¹ng nguy hiá»ƒm lÃºc $time.';
  }

  @override
  String notificationsZoneSafeExitDescription(
    String childName,
    String zoneName,
    String time,
  ) {
    return 'Vá»‹ trÃ­ cá»§a $childName Ä‘Ã£ Ä‘Æ°á»£c ghi nháº­n táº¡i $zoneName. Há»‡ thá»‘ng ghi nháº­n bÃ© Ä‘Ã£ rá»i vÃ¹ng an toÃ n lÃºc $time.';
  }

  @override
  String notificationsZoneDangerExitDescription(
    String childName,
    String zoneName,
    String time,
  ) {
    return 'Vá»‹ trÃ­ cá»§a $childName Ä‘Ã£ Ä‘Æ°á»£c ghi nháº­n táº¡i $zoneName. Há»‡ thá»‘ng ghi nháº­n bÃ© Ä‘Ã£ rá»i vÃ¹ng nguy hiá»ƒm lÃºc $time.';
  }

  @override
  String notificationsZoneUpdatedDescription(
    String childName,
    String zoneName,
  ) {
    return 'Vá»‹ trÃ­ cá»§a $childName Ä‘Ã£ Ä‘Æ°á»£c cáº­p nháº­t táº¡i $zoneName.';
  }

  @override
  String get notificationsZoneViewOnMainMapButton => 'Xem trÃªn báº£n Ä‘á»“ chÃ­nh';

  @override
  String get notificationsContactNowButton => 'LiÃªn há»‡ ngay';

  @override
  String get notificationsLocalChannelName => 'Máº·c Ä‘á»‹nh';

  @override
  String get notificationsLocalChannelDescription => 'ThÃ´ng bÃ¡o máº·c Ä‘á»‹nh';

  @override
  String get notificationsDefaultTitle => 'ThÃ´ng bÃ¡o';

  @override
  String get notificationsDefaultBody => 'Báº¡n cÃ³ thÃ´ng bÃ¡o má»›i';

  @override
  String get notificationsFamilyChatTitle => 'Tin nháº¯n gia Ä‘Ã¬nh';

  @override
  String get notificationsFamilyChatBody => 'Báº¡n cÃ³ tin nháº¯n má»›i';

  @override
  String get notificationsFamilyEventTitle => 'Sá»± kiá»‡n gia Ä‘Ã¬nh';

  @override
  String get notificationsFamilyEventBody => 'Gia Ä‘Ã¬nh báº¡n cÃ³ sá»± kiá»‡n má»›i';

  @override
  String get notificationsBirthdayTitle => 'Sinh nháº­t';

  @override
  String notificationsBirthdayUpcomingBody(String name) {
    return 'Sáº¯p tá»›i sinh nháº­t cá»§a $name!';
  }

  @override
  String notificationsBirthdayTodayBody(String name) {
    return 'HÃ´m nay lÃ  sinh nháº­t cá»§a $name!';
  }

  @override
  String get notificationsTrackingDefaultBody =>
      'Tráº¡ng thÃ¡i Ä‘á»‹nh vá»‹ Ä‘Ã£ thay Ä‘á»•i.';

  @override
  String scheduleOverlapConflictMessage(
    String title,
    String start,
    String end,
  ) {
    return 'TrÃ¹ng vá»›i lá»‹ch \"$title\" ($start - $end). Vui lÃ²ng chá»n giá» khÃ¡c.';
  }

  @override
  String get scheduleExportErrorCreateExcelFile => 'KhÃ´ng táº¡o Ä‘Æ°á»£c file Excel';

  @override
  String get scheduleImportTemplateSampleTitle1 => 'Há»c ToÃ¡n';

  @override
  String get scheduleImportTemplateSampleDescription1 => 'LÃ m bÃ i 1-5';

  @override
  String get scheduleImportTemplateSampleTitle2 => 'ÄÃ¡ bÃ³ng';

  @override
  String get scheduleImportErrorCreateExcelBytes =>
      'KhÃ´ng táº¡o Ä‘Æ°á»£c dá»¯ liá»‡u Excel';

  @override
  String get scheduleImportErrorMissingTitle => 'Thiáº¿u title';

  @override
  String get scheduleImportErrorEndAfterStart =>
      'Giá» káº¿t thÃºc pháº£i lá»›n hÆ¡n giá» báº¯t Ä‘áº§u';

  @override
  String scheduleImportWarningDbCheckFailed(String error) {
    return 'KhÃ´ng kiá»ƒm tra trÃ¹ng DB do lá»—i máº¡ng: $error';
  }

  @override
  String get scheduleImportErrorMissingDate => 'Thiáº¿u date';

  @override
  String scheduleImportErrorInvalidDate(String raw) {
    return 'Sai date: \"$raw\"';
  }

  @override
  String scheduleImportErrorInvalidDateSupported(String raw) {
    return 'Sai date: \"$raw\" (há»— trá»£: yyyy-MM-dd, dd/MM/yyyy, MM/dd/yyyy, ISO datetime)';
  }

  @override
  String get scheduleImportErrorMissingTime => 'Thiáº¿u time';

  @override
  String scheduleImportErrorInvalidTimeSupported(String raw) {
    return 'Sai time: \"$raw\" (há»— trá»£: HH:mm, HH:mm:ss, 7:00 AM/PM)';
  }

  @override
  String get scheduleNotifyTitleCreated => 'Lá»‹ch trÃ¬nh má»›i';

  @override
  String get scheduleNotifyTitleUpdated => 'Lá»‹ch trÃ¬nh Ä‘Ã£ thay Ä‘á»•i';

  @override
  String get scheduleNotifyTitleDeleted => 'Lá»‹ch trÃ¬nh Ä‘Ã£ bá»‹ xÃ³a';

  @override
  String get scheduleNotifyTitleRestored => 'Lá»‹ch trÃ¬nh Ä‘Ã£ Ä‘Æ°á»£c khÃ´i phá»¥c';

  @override
  String get scheduleNotifyTitleChanged => 'Lá»‹ch trÃ¬nh cÃ³ thay Ä‘á»•i';

  @override
  String scheduleNotifyBodyParentCreated(
    String title,
    String childName,
    String date,
    String time,
  ) {
    return 'Cha Ä‘Ã£ thÃªm lá»‹ch \"$title\" cho $childName vÃ o $date, $time.';
  }

  @override
  String scheduleNotifyBodyParentUpdated(String title, String childName) {
    return 'Cha Ä‘Ã£ chá»‰nh sá»­a lá»‹ch \"$title\" cá»§a $childName.';
  }

  @override
  String scheduleNotifyBodyParentDeleted(String title, String childName) {
    return 'Cha Ä‘Ã£ xÃ³a lá»‹ch \"$title\" cá»§a $childName.';
  }

  @override
  String scheduleNotifyBodyParentRestored(String title, String childName) {
    return 'Cha Ä‘Ã£ khÃ´i phá»¥c má»™t phiÃªn báº£n cÅ© cá»§a lá»‹ch \"$title\" cá»§a $childName.';
  }

  @override
  String scheduleNotifyBodyParentChanged(String title, String childName) {
    return 'Cha Ä‘Ã£ thay Ä‘á»•i lá»‹ch \"$title\" cá»§a $childName.';
  }

  @override
  String scheduleNotifyBodyChildCreated(
    String childName,
    String title,
    String date,
    String time,
  ) {
    return '$childName Ä‘Ã£ thÃªm lá»‹ch \"$title\" vÃ o $date, $time.';
  }

  @override
  String scheduleNotifyBodyChildUpdated(String childName, String title) {
    return '$childName Ä‘Ã£ chá»‰nh sá»­a lá»‹ch \"$title\".';
  }

  @override
  String scheduleNotifyBodyChildDeleted(String childName, String title) {
    return '$childName Ä‘Ã£ xÃ³a lá»‹ch \"$title\".';
  }

  @override
  String scheduleNotifyBodyChildRestored(String childName, String title) {
    return '$childName Ä‘Ã£ khÃ´i phá»¥c lá»‹ch sá»­ sá»­a cá»§a lá»‹ch \"$title\".';
  }

  @override
  String scheduleNotifyBodyChildChanged(String childName, String title) {
    return '$childName Ä‘Ã£ thay Ä‘á»•i lá»‹ch \"$title\".';
  }

  @override
  String get memoryDayNotifyTitleCreated => 'NgÃ y Ä‘Ã¡ng nhá»› má»›i';

  @override
  String get memoryDayNotifyTitleUpdated => 'NgÃ y Ä‘Ã¡ng nhá»› Ä‘Ã£ thay Ä‘á»•i';

  @override
  String get memoryDayNotifyTitleDeleted => 'NgÃ y Ä‘Ã¡ng nhá»› Ä‘Ã£ bá»‹ xÃ³a';

  @override
  String get memoryDayNotifyTitleChanged => 'NgÃ y Ä‘Ã¡ng nhá»› cÃ³ thay Ä‘á»•i';

  @override
  String get memoryDayNotifyTitleReminder => 'Sáº¯p Ä‘áº¿n ngÃ y Ä‘Ã¡ng nhá»›';

  @override
  String memoryDayNotifyBodyReminderTomorrow(String title, String date) {
    return 'NgÃ y mai lÃ  \"$title\" ($date).';
  }

  @override
  String memoryDayNotifyBodyReminderInDays(
    String title,
    int days,
    String date,
  ) {
    return 'CÃ²n $days ngÃ y Ä‘áº¿n \"$title\" ($date).';
  }

  @override
  String memoryDayNotifyBodyParentCreated(String title) {
    return 'Cha Ä‘Ã£ thÃªm ngÃ y Ä‘Ã¡ng nhá»› \"$title\".';
  }

  @override
  String memoryDayNotifyBodyParentUpdated(String title) {
    return 'Cha Ä‘Ã£ chá»‰nh sá»­a ngÃ y Ä‘Ã¡ng nhá»› \"$title\".';
  }

  @override
  String memoryDayNotifyBodyParentDeleted(String title) {
    return 'Cha Ä‘Ã£ xÃ³a ngÃ y Ä‘Ã¡ng nhá»› \"$title\".';
  }

  @override
  String memoryDayNotifyBodyParentChanged(String title) {
    return 'Cha Ä‘Ã£ thay Ä‘á»•i ngÃ y Ä‘Ã¡ng nhá»› \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildCreated(String actorChildName, String title) {
    return '$actorChildName Ä‘Ã£ thÃªm ngÃ y Ä‘Ã¡ng nhá»› \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildUpdated(String actorChildName, String title) {
    return '$actorChildName Ä‘Ã£ chá»‰nh sá»­a ngÃ y Ä‘Ã¡ng nhá»› \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildDeleted(String actorChildName, String title) {
    return '$actorChildName Ä‘Ã£ xÃ³a ngÃ y Ä‘Ã¡ng nhá»› \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildChanged(String actorChildName, String title) {
    return '$actorChildName Ä‘Ã£ thay Ä‘á»•i ngÃ y Ä‘Ã¡ng nhá»› \"$title\".';
  }

  @override
  String get scheduleImportNotifyTitle => 'Lá»‹ch trÃ¬nh má»›i Ä‘Æ°á»£c thÃªm';

  @override
  String scheduleImportNotifyBodyParent(int importCount, String childName) {
    return 'Cha vá»«a thÃªm $importCount lá»‹ch cho $childName.';
  }

  @override
  String scheduleImportNotifyBodyChild(String actorChildName, int importCount) {
    return '$actorChildName vá»«a thÃªm $importCount lá»‹ch.';
  }

  @override
  String get parentDashboardTitle => 'Báº£ng Ä‘iá»u khiá»ƒn';

  @override
  String get parentDashboardTabApps => 'á»¨ng dá»¥ng';

  @override
  String get parentDashboardTabStatistics => 'Thá»‘ng kÃª';

  @override
  String get parentDashboardNoDeviceTitle =>
      'ChÆ°a cÃ³ thiáº¿t bá»‹ nÃ o Ä‘Æ°á»£c liÃªn káº¿t';

  @override
  String get parentDashboardNoDeviceSubtitle =>
      'Äá»ƒ theo dÃµi thá»i gian sá»­ dá»¥ng á»©ng dá»¥ng, báº¡n cáº§n thÃªm thiáº¿t bá»‹ cá»§a con vÃ o há»‡ thá»‘ng.';

  @override
  String get parentDashboardAddDeviceButton => 'ThÃªm con';

  @override
  String get parentDashboardHowItWorksButton => 'TÃ¬m hiá»ƒu cÃ¡ch hoáº¡t Ä‘á»™ng';

  @override
  String get parentStatsTotalToday => 'Tá»”NG THá»œI GIAN HÃ”M NAY';

  @override
  String get parentStatsTotalThisWeek => 'Tá»”NG THá»œI GIAN TUáº¦N NÃ€Y';

  @override
  String get parentStatsSelectRange => 'CHá»ŒN KHOáº¢NG NGÃ€Y';

  @override
  String get parentStatsSelectEndDate => 'CHá»ŒN NGÃ€Y Káº¾T THÃšC';

  @override
  String parentStatsTotalFromRange(String startDate, String endDate) {
    return 'Tá»”NG THá»œI GIAN Tá»ª $startDate - $endDate';
  }

  @override
  String get parentStatsSegmentDay => 'NgÃ y';

  @override
  String get parentStatsSegmentWeek => 'Tuáº§n';

  @override
  String get parentStatsSegmentRange => 'ThÃªm';

  @override
  String get parentStatsAppDetailsTitle => 'Chi tiáº¿t á»©ng dá»¥ng';

  @override
  String get parentStatsCollapse => 'THU Gá»ŒN';

  @override
  String get parentStatsViewAll => 'XEM Táº¤T Cáº¢';

  @override
  String get parentStatsDurationZero => '0p';

  @override
  String parentStatsDurationMinutes(int minutes) {
    return '${minutes}p';
  }

  @override
  String parentStatsDurationHours(int hours) {
    return '${hours}g';
  }

  @override
  String parentStatsDurationHoursMinutes(int hours, int minutes) {
    return '${hours}g ${minutes}p';
  }

  @override
  String parentStatsHourLabel(int hour) {
    return '${hour}g';
  }

  @override
  String get parentUsageNoAvailableSlot => 'KhÃ´ng cÃ²n khoáº£ng thá»i gian trá»‘ng';

  @override
  String get parentUsageStartBeforeEnd =>
      'Giá» báº¯t Ä‘áº§u pháº£i nhá» hÆ¡n giá» káº¿t thÃºc';

  @override
  String get parentUsageOverlapTimeRange =>
      'Khoáº£ng thá»i gian bá»‹ trÃ¹ng vá»›i má»‘c khÃ¡c';

  @override
  String get parentUsageEndAfterStart =>
      'Giá» káº¿t thÃºc pháº£i lá»›n hÆ¡n giá» báº¯t Ä‘áº§u';

  @override
  String get parentUsageEditTitle => 'CÃ i Ä‘áº·t thá»i gian sá»­ dá»¥ng';

  @override
  String get parentUsageEnableUsage => 'Cho phÃ©p sá»­ dá»¥ng';

  @override
  String get parentUsageSelectAllowedDays => 'Chá»n ngÃ y Ä‘Æ°á»£c phÃ©p';

  @override
  String get saveButton => 'LÆ°u';

  @override
  String get parentUsageDayRuleModalHint => 'Chá»n quy táº¯c cho ngÃ y nÃ y';

  @override
  String get parentUsageRuleFollowScheduleTitle => 'Theo lá»‹ch Ä‘Ã£ Ä‘áº·t';

  @override
  String get parentUsageRuleFollowScheduleSubtitle =>
      'Ãp dá»¥ng khung giá» hÃ ng tuáº§n';

  @override
  String get parentUsageRuleAllowAllDayTitle => 'Cho phÃ©p cáº£ ngÃ y';

  @override
  String get parentUsageRuleAllowAllDaySubtitle =>
      'CÃ³ thá»ƒ sá»­ dá»¥ng báº¥t cá»© lÃºc nÃ o';

  @override
  String get parentUsageRuleBlockAllDayTitle => 'Cháº·n cáº£ ngÃ y';

  @override
  String get parentUsageRuleBlockAllDaySubtitle => 'KhÃ´ng Ä‘Æ°á»£c sá»­ dá»¥ng hÃ´m nay';

  @override
  String get zonesDeleteConfirmTitle => 'XÃ¡c nháº­n xoÃ¡';

  @override
  String get zonesDeleteConfirmMessage =>
      'Báº¡n cÃ³ cháº¯c muá»‘n xoÃ¡ Ä‘á»‹a Ä‘iá»ƒm nÃ y khÃ´ng?';

  @override
  String get zonesDeleteButton => 'XoÃ¡';

  @override
  String get zonesCreateSuccessTitle => 'Táº¡o thÃ nh cÃ´ng';

  @override
  String zonesCreateSuccessMessage(String name) {
    return 'Äá»‹a Ä‘iá»ƒm \"$name\" Ä‘Ã£ Ä‘Æ°á»£c táº¡o';
  }

  @override
  String get zonesFailedTitle => 'Tháº¥t báº¡i';

  @override
  String get zonesCreateFailedMessage =>
      'KhÃ´ng thá»ƒ táº¡o Ä‘á»‹a Ä‘iá»ƒm, vui lÃ²ng thá»­ láº¡i';

  @override
  String get zonesEditSuccessTitle => 'Chá»‰nh sá»­a thÃ nh cÃ´ng';

  @override
  String get zonesEditSuccessMessage => 'Äá»‹a Ä‘iá»ƒm Ä‘Ã£ Ä‘Æ°á»£c cáº­p nháº­t';

  @override
  String get zonesEditFailedMessage =>
      'KhÃ´ng thá»ƒ cáº­p nháº­t Ä‘á»‹a Ä‘iá»ƒm, vui lÃ²ng thá»­ láº¡i';

  @override
  String get zonesDeleteSuccessTitle => 'XoÃ¡ thÃ nh cÃ´ng';

  @override
  String get zonesDeleteSuccessMessage => 'Äá»‹a Ä‘iá»ƒm Ä‘Ã£ Ä‘Æ°á»£c xoÃ¡';

  @override
  String get zonesDeleteFailedMessage =>
      'KhÃ´ng thá»ƒ xoÃ¡ Ä‘á»‹a Ä‘iá»ƒm, vui lÃ²ng thá»­ láº¡i';

  @override
  String get zonesEmptyTitle => 'ChÆ°a cÃ³ vÃ¹ng nÃ o';

  @override
  String get zonesEmptySubtitle =>
      'ThÃªm vÃ¹ng Ä‘á»ƒ báº¯t Ä‘áº§u theo dÃµi vá»‹ trÃ­ cá»§a bÃ©';

  @override
  String get zonesTypeSafe => 'An toÃ n';

  @override
  String get zonesTypeDanger => 'Nguy hiá»ƒm';

  @override
  String get zonesEditMenu => 'Sá»­a';

  @override
  String get zonesDeleteMenu => 'XoÃ¡';

  @override
  String get zonesScreenTitle => 'VÃ¹ng cá»§a bÃ©';

  @override
  String get zonesAddButton => 'ThÃªm vÃ¹ng';

  @override
  String zonesErrorWithMessage(String error) {
    return 'Lá»—i: $error';
  }

  @override
  String get zonesNewZoneDefaultName => 'VÃ¹ng má»›i';

  @override
  String get zonesEditTitle => 'Chá»‰nh sá»­a vÃ¹ng';

  @override
  String get zonesAddAddressTitle => 'Äá»‹a chá»‰ cá»§a Ä‘á»‹a Ä‘iá»ƒm';

  @override
  String get zonesOverlapWarningText => 'CÃ¡c Ä‘á»‹a Ä‘iá»ƒm khÃ´ng nÃªn chá»“ng chÃ©o';

  @override
  String get zonesNameFieldLabel => 'TÃªn vÃ¹ng';

  @override
  String get zonesTypeFieldLabel => 'Loáº¡i vÃ¹ng';

  @override
  String get zonesRadiusLabel => 'BÃ¡n kÃ­nh';

  @override
  String get zonesOverlappingPrefix => 'Äang chá»“ng lÃªn: ';

  @override
  String zonesOverlappingWith(String name) {
    return 'Äang chá»“ng lÃªn: $name';
  }

  @override
  String get zonesDefaultNameFallback => 'VÃ¹ng';

  @override
  String get parentLocationUnknownUser => 'KhÃ´ng rÃµ';

  @override
  String get parentLocationSosSent => 'ÄÃ£ gá»­i SOS';

  @override
  String get parentLocationSosFailed => 'Gá»­i SOS tháº¥t báº¡i';

  @override
  String get parentLocationMapLoadingTitle => 'Äang táº£i báº£n Ä‘á»“';

  @override
  String get parentLocationMapLoadingSubtitle =>
      'Äang chuáº©n bá»‹ vá»‹ trÃ­ cá»§a cÃ¡c bÃ©';

  @override
  String get parentChildrenListTitle => 'Danh sÃ¡ch thÃ nh viÃªn';

  @override
  String get personalInfoManageAccountsTitle => 'Quáº£n lÃ½ tÃ i khoáº£n';

  @override
  String get personalInfoManageAccountsSubtitle =>
      'Quáº£n lÃ½ tÃ i khoáº£n cá»§a thÃ nh viÃªn';

  @override
  String get personalInfoDetailsButton => 'Chi tiáº¿t';

  @override
  String get childLocationTransportWalking => 'Äi bá»™';

  @override
  String get childLocationTransportBicycle => 'Xe Ä‘áº¡p';

  @override
  String get childLocationTransportVehicle => 'Äi xe';

  @override
  String get childLocationTransportStill => 'Äá»©ng yÃªn';

  @override
  String get childLocationTransportUnknown => 'KhÃ´ng rÃµ';

  @override
  String get childLocationDetailTitle => 'Chi tiáº¿t vá»‹ trÃ­';

  @override
  String childLocationStatusTitle(String transport) {
    return 'Tráº¡ng thÃ¡i: $transport';
  }

  @override
  String childLocationHistoryTitle(String date) {
    return 'Lá»‹ch sá»­ â€¢ $date';
  }

  @override
  String get childLocationTooltipHideDots => 'áº¨n Ä‘iá»ƒm';

  @override
  String get childLocationTooltipShowDots => 'Hiá»‡n Ä‘iá»ƒm';

  @override
  String get childLocationHistoryButton => 'Lá»‹ch sá»­';

  @override
  String get childLocationZonesButton => 'VÃ¹ng';

  @override
  String get zone_default => 'ThÃ´ng bÃ¡o hehehe';

  @override
  String get zone_enter_danger_parent => 'âš ï¸ BÃ© vÃ o vÃ¹ng nguy hiá»ƒm';

  @override
  String get zone_exit_danger_parent => 'âœ… BÃ© rá»i vÃ¹ng nguy hiá»ƒm';

  @override
  String get zone_enter_safe_parent => 'âœ… BÃ© vÃ o vÃ¹ng an toÃ n';

  @override
  String get zone_exit_safe_parent => 'â„¹ï¸ BÃ© rá»i vÃ¹ng an toÃ n';

  @override
  String get zone_enter_danger_child => 'âš ï¸ Báº¡n Ä‘ang vÃ o vÃ¹ng nguy hiá»ƒm';

  @override
  String get zone_exit_danger_child => 'âœ… Báº¡n Ä‘Ã£ ra khá»i vÃ¹ng nguy hiá»ƒm';

  @override
  String get zone_enter_safe_child => 'âœ… Báº¡n Ä‘ang vÃ o vÃ¹ng an toÃ n';

  @override
  String get zone_exit_safe_child => 'â„¹ï¸ Báº¡n Ä‘Ã£ ra khá»i vÃ¹ng an toÃ n';

  @override
  String get tracking_location_service_off_parent_title => 'Con Ä‘Ã£ táº¯t Ä‘á»‹nh vá»‹';

  @override
  String get tracking_location_permission_denied_parent_title =>
      'Con Ä‘Ã£ táº¯t quyá»n vá»‹ trÃ­';

  @override
  String get tracking_background_disabled_parent_title =>
      'Äá»‹nh vá»‹ ná»n Ä‘Ã£ bá»‹ táº¯t';

  @override
  String get tracking_location_stale_parent_title =>
      'KhÃ´ng nháº­n Ä‘Æ°á»£c vá»‹ trÃ­ má»›i';

  @override
  String get tracking_ok_parent_title => 'Äá»‹nh vá»‹ Ä‘Ã£ hoáº¡t Ä‘á»™ng láº¡i';

  @override
  String tracking_location_service_off_parent_body(String childName) {
    return '$childName vá»«a táº¯t GPS hoáº·c vá»‹ trÃ­ trÃªn thiáº¿t bá»‹.';
  }

  @override
  String tracking_location_permission_denied_parent_body(String childName) {
    return '$childName Ä‘Ã£ táº¯t quyá»n truy cáº­p vá»‹ trÃ­ cá»§a á»©ng dá»¥ng.';
  }

  @override
  String tracking_background_disabled_parent_body(String childName) {
    return '$childName Ä‘Ã£ táº¯t chia sáº» vá»‹ trÃ­ ná»n.';
  }

  @override
  String tracking_location_stale_parent_body(String childName) {
    return '$childName chÆ°a cáº­p nháº­t vá»‹ trÃ­ trong hÆ¡n 2 phÃºt.';
  }

  @override
  String tracking_ok_parent_body(String childName) {
    return '$childName Ä‘Ã£ báº­t láº¡i Ä‘á»‹nh vá»‹ vÃ  vá»‹ trÃ­ Ä‘ang cáº­p nháº­t bÃ¬nh thÆ°á»ng.';
  }

  @override
  String get tracking_location_service_off_child_title => 'Äá»‹nh vá»‹ Ä‘ang táº¯t';

  @override
  String get tracking_location_permission_denied_child_title =>
      'Quyá»n vá»‹ trÃ­ Ä‘ang táº¯t';

  @override
  String get tracking_background_disabled_child_title => 'Äá»‹nh vá»‹ ná»n Ä‘ang táº¯t';

  @override
  String get tracking_location_stale_child_title => 'Vá»‹ trÃ­ chÆ°a Ä‘Æ°á»£c cáº­p nháº­t';

  @override
  String get tracking_ok_child_title => 'Äá»‹nh vá»‹ Ä‘Ã£ hoáº¡t Ä‘á»™ng láº¡i';

  @override
  String get tracking_default_title => 'ThÃ´ng bÃ¡o Ä‘á»‹nh vá»‹';

  @override
  String get sosChannelName => 'Cáº£nh bÃ¡o SOS';

  @override
  String get sosChannelDescription => 'ThÃ´ng bÃ¡o SOS kháº©n cáº¥p';

  @override
  String get sosFallbackTitle => 'SOS kháº©n cáº¥p';

  @override
  String get sosFallbackBody => 'CÃ³ thÃ nh viÃªn Ä‘ang cáº§u cá»©u.';

  @override
  String get localAlarmDangerChannelName => 'Cáº£nh bÃ¡o vÃ¹ng nguy hiá»ƒm';

  @override
  String get localAlarmDangerChannelDescription =>
      'ThÃ´ng bÃ¡o khi bÃ© vÃ o hoáº·c rá»i vÃ¹ng nguy hiá»ƒm';

  @override
  String get localAlarmDangerEnterTitle => 'Cáº£nh bÃ¡o vÃ¹ng nguy hiá»ƒm';

  @override
  String localAlarmDangerEnterBody(String zoneName) {
    return 'Báº¡n Ä‘Ã£ vÃ o: $zoneName';
  }

  @override
  String get localAlarmDangerExitTitle => 'ÄÃ£ rá»i vÃ¹ng nguy hiá»ƒm';

  @override
  String localAlarmDangerExitBody(String zoneName) {
    return 'Báº¡n Ä‘Ã£ rá»i: $zoneName';
  }

  @override
  String get trackingStatusLocationServiceOffMessage =>
      'Vui lÃ²ng báº­t GPS hoáº·c Dá»‹ch vá»¥ vá»‹ trÃ­ trÃªn thiáº¿t bá»‹ Ä‘á»ƒ tiáº¿p tá»¥c cáº­p nháº­t vá»‹ trÃ­.';

  @override
  String get trackingStatusLocationPermissionDeniedMessage =>
      'Vui lÃ²ng cáº¥p quyá»n vá»‹ trÃ­ cho á»©ng dá»¥ng trÃªn thiáº¿t bá»‹ Ä‘á»ƒ tiáº¿p tá»¥c cáº­p nháº­t vá»‹ trÃ­.';

  @override
  String get trackingStatusPreciseLocationDeniedMessage =>
      'Thiáº¿t bá»‹ chÆ°a cáº¥p vá»‹ trÃ­ chÃ­nh xÃ¡c';

  @override
  String get trackingStatusBackgroundDisabledMessage =>
      'ÄÃ£ táº¯t chia sáº» vá»‹ trÃ­ ná»n';

  @override
  String get trackingStatusOkMessage => 'Äá»‹nh vá»‹ hoáº¡t Ä‘á»™ng bÃ¬nh thÆ°á»ng';

  @override
  String get trackingErrorEnableLocationService =>
      'Vui lÃ²ng báº­t GPS/vá»‹ trÃ­ trÃªn thiáº¿t bá»‹.';

  @override
  String get trackingErrorEnablePreciseLocation =>
      'Vui lÃ²ng báº­t vá»‹ trÃ­ chÃ­nh xÃ¡c.';

  @override
  String get trackingErrorEnableBackgroundLocation =>
      'Vui lÃ²ng báº­t chia sáº» vá»‹ trÃ­ ná»n (Allow all the time).';

  @override
  String get locationForegroundServiceTitle => 'Äang chia sáº» vá»‹ trÃ­';

  @override
  String get locationForegroundServiceSubtitle =>
      'á»¨ng dá»¥ng cháº¡y ná»n Ä‘á»ƒ báº£o vá»‡ con';

  @override
  String parentLocationGpsError(Object error) {
    return 'Lá»—i GPS: $error';
  }

  @override
  String parentLocationEnableGpsError(Object error) {
    return 'Lá»—i báº­t GPS: $error';
  }

  @override
  String parentLocationCurrentLocationError(Object error) {
    return 'KhÃ´ng láº¥y Ä‘Æ°á»£c vá»‹ trÃ­ hiá»‡n táº¡i: $error';
  }

  @override
  String parentLocationHistoryLoadError(Object error) {
    return 'Lá»—i táº£i lá»‹ch sá»­: $error';
  }

  @override
  String parentLocationWatchChildError(Object childId, Object error) {
    return 'Lá»—i theo dÃµi $childId: $error';
  }

  @override
  String get authLoginRequired => 'ChÆ°a Ä‘Äƒng nháº­p';

  @override
  String get firebaseAuthCurrentPasswordIncorrect =>
      'Máº­t kháº©u hiá»‡n táº¡i khÃ´ng Ä‘Ãºng';

  @override
  String get firebaseAuthUserMismatch => 'TÃ i khoáº£n xÃ¡c thá»±c khÃ´ng khá»›p';

  @override
  String get firebaseAuthTooManyRequests =>
      'Báº¡n thá»­ sai quÃ¡ nhiá»u láº§n. Vui lÃ²ng thá»­ láº¡i sau';

  @override
  String get firebaseAuthNetworkFailed =>
      'Lá»—i káº¿t ná»‘i máº¡ng. Vui lÃ²ng kiá»ƒm tra Internet';

  @override
  String get firebaseAuthChangePasswordFailed =>
      'KhÃ´ng thá»ƒ Ä‘á»•i máº­t kháº©u. Vui lÃ²ng thá»­ láº¡i';

  @override
  String get permissionLocationTitle => 'Báº­t quyá»n vá»‹ trÃ­';

  @override
  String get permissionLocationSubtitle =>
      'á»¨ng dá»¥ng cáº§n quyá»n vá»‹ trÃ­ Ä‘á»ƒ theo dÃµi vá»‹ trÃ­ cá»§a tráº» vÃ  há»— trá»£ cÃ¡c tÃ­nh nÄƒng an toÃ n.';

  @override
  String get permissionLocationRecommendation =>
      'Khuyáº¿n nghá»‹: cho phÃ©p vá»‹ trÃ­ khi dÃ¹ng á»©ng dá»¥ng trÆ°á»›c. Náº¿u app cáº§n cháº¡y ná»n sau nÃ y, báº¡n cÃ³ thá»ƒ xin thÃªm quyá»n Always.';

  @override
  String get permissionLocationAllowButton => 'Cho phÃ©p vá»‹ trÃ­';

  @override
  String get permissionNotificationTitle => 'Báº­t SOS Alerts';

  @override
  String get permissionNotificationSubtitle =>
      'á»¨ng dá»¥ng cáº§n quyá»n thÃ´ng bÃ¡o Ä‘á»ƒ gá»­i cáº£nh bÃ¡o SOS kháº©n cáº¥p ngay cáº£ khi báº¡n khÃ´ng má»Ÿ app.';

  @override
  String get permissionNotificationRecommendation =>
      'LÆ°u Ã½: Sau khi cáº¥p quyá»n, hÃ£y Ä‘áº£m báº£o kÃªnh \"SOS Alerts\" Ä‘Æ°á»£c báº­t Ã¢m thanh trong cÃ i Ä‘áº·t thÃ´ng bÃ¡o.';

  @override
  String get permissionNotificationAllowButton => 'Cho phÃ©p thÃ´ng bÃ¡o';

  @override
  String get permissionSosTitle => 'Báº­t quyá»n SOS';

  @override
  String get permissionSosSubtitle =>
      'á»¨ng dá»¥ng cáº§n quyá»n thÃ´ng bÃ¡o Ä‘á»ƒ gá»­i cáº£nh bÃ¡o SOS kháº©n cáº¥p vÃ  phÃ¡t Ã¢m thanh cáº£nh bÃ¡o.';

  @override
  String get permissionSosRecommendation =>
      'HÃ£y báº­t thÃ´ng bÃ¡o vÃ  Ä‘áº£m báº£o kÃªnh \"SOS Alerts\" cÃ³ Ã¢m thanh.';

  @override
  String get permissionSosAllowButton => 'Cho phÃ©p SOS';

  @override
  String get permissionOpenSettingsButton => 'Má»Ÿ cÃ i Ä‘áº·t';

  @override
  String get permissionLaterButton => 'Äá»ƒ sau';

  @override
  String get permissionSkipButton => 'Bá» qua';

  @override
  String permissionStepLabel(int current, int total) {
    return 'BÆ°á»›c $current/$total';
  }

  @override
  String get permissionOnboardingAccessibilityTitle => 'Báº­t trá»£ nÄƒng';

  @override
  String get permissionOnboardingAccessibilitySubtitle =>
      'ÄÆ°á»£c dÃ¹ng cho kiá»ƒm soÃ¡t cá»§a phá»¥ huynh trÃªn Android Ä‘á»ƒ nháº­n biáº¿t á»©ng dá»¥ng nÃ o Ä‘ang má»Ÿ trÃªn thiáº¿t bá»‹ cá»§a tráº» vÃ  Ã¡p dá»¥ng quy táº¯c cháº·n do phá»¥ huynh Ä‘áº·t. ThÃ´ng tin nÃ y Ä‘Æ°á»£c hiá»ƒn thá»‹ cho phá»¥ huynh hoáº·c ngÆ°á»i giÃ¡m há»™ Ä‘Æ°á»£c chá»‰ Ä‘á»‹nh Ä‘á»ƒ phá»¥c vá»¥ an toÃ n vÃ  sá»©c khá»e sá»‘.';

  @override
  String get permissionOnboardingAccessibilityPrimaryButton => 'Cho phÃ©p';

  @override
  String get permissionOnboardingAccessibilitySettingsButton =>
      'Má»Ÿ cÃ i Ä‘áº·t chung';

  @override
  String get permissionOnboardingBackgroundLocationTitle =>
      'Chá»n \"LuÃ´n cho phÃ©p\"';

  @override
  String get permissionOnboardingBackgroundLocationSubtitle =>
      'á»¨ng dá»¥ng nÃ y thu tháº­p dá»¯ liá»‡u vá»‹ trÃ­ Ä‘á»ƒ hiá»ƒn thá»‹ vá»‹ trÃ­ trá»±c tiáº¿p cá»§a tráº», táº¡o cáº£nh bÃ¡o VÃ¹ng an toÃ n vÃ  há»— trá»£ Safe Route ngay cáº£ khi á»©ng dá»¥ng Ä‘Ã£ Ä‘Ã³ng hoáº·c khÃ´ng sá»­ dá»¥ng. Vá»‹ trÃ­ Ä‘Æ°á»£c chia sáº» vá»›i phá»¥ huynh hoáº·c ngÆ°á»i giÃ¡m há»™ Ä‘Æ°á»£c chá»‰ Ä‘á»‹nh trong cÃ¹ng gia Ä‘Ã¬nh cho cÃ¡c tÃ­nh nÄƒng an toÃ n.';

  @override
  String get permissionOnboardingBackgroundLocationPrimaryButton => 'Tiáº¿p tá»¥c';

  @override
  String get permissionOnboardingBackgroundLocationSettingsButton =>
      'Má»Ÿ cÃ i Ä‘áº·t vá»‹ trÃ­';

  @override
  String get permissionOnboardingBatteryTitle => 'Táº¯t giá»›i háº¡n pin';

  @override
  String get permissionOnboardingBatterySubtitle =>
      'Cho phÃ©p theo dÃµi vÃ  cáº£nh bÃ¡o an toÃ n tiáº¿p tá»¥c hoáº¡t Ä‘á»™ng khi Android cÃ³ thá»ƒ dá»«ng á»©ng dá»¥ng á»Ÿ cháº¿ Ä‘á»™ ná»n.';

  @override
  String get permissionOnboardingBatteryPrimaryButton => 'Cho phÃ©p';

  @override
  String get permissionOnboardingBatterySettingsButton => 'Má»Ÿ cÃ i Ä‘áº·t chung';

  @override
  String get permissionOnboardingLocationTitle =>
      'Báº­t \"Truy cáº­p vá»‹ trÃ­ cá»§a tÃ´i\"';

  @override
  String get permissionOnboardingLocationSubtitle =>
      'Náº¿u khÃ´ng, app sáº½ khÃ´ng thá»ƒ theo dÃµi vá»‹ trÃ­.';

  @override
  String get permissionOnboardingLocationPrimaryButton => 'Cho phÃ©p';

  @override
  String get permissionOnboardingLocationSettingsButton =>
      'Má»Ÿ cÃ i Ä‘áº·t á»©ng dá»¥ng';

  @override
  String get permissionOnboardingMediaTitle => 'Cho phÃ©p áº£nh vÃ  media';

  @override
  String get permissionOnboardingMediaSubtitle =>
      'Äá»ƒ Ä‘á»•i áº£nh Ä‘áº¡i diá»‡n vÃ  chá»n hÃ¬nh trong app.';

  @override
  String get permissionOnboardingMediaPrimaryButton => 'Cho phÃ©p';

  @override
  String get permissionOnboardingMediaSettingsButton => 'Má»Ÿ cÃ i Ä‘áº·t';

  @override
  String get permissionOnboardingNotificationTitle => 'Báº­t thÃ´ng bÃ¡o';

  @override
  String get permissionOnboardingNotificationSubtitle =>
      'Äá»ƒ nháº­n SOS vÃ  cáº£nh bÃ¡o an toÃ n ngay láº­p tá»©c.';

  @override
  String get permissionOnboardingNotificationPrimaryButton => 'Cho phÃ©p';

  @override
  String get permissionOnboardingNotificationSettingsButton =>
      'Má»Ÿ cÃ i Ä‘áº·t thÃ´ng bÃ¡o';

  @override
  String get permissionOnboardingUsageTitle => 'Báº­t quyá»n sá»­ dá»¥ng á»©ng dá»¥ng';

  @override
  String get permissionOnboardingUsageSubtitle =>
      'ÄÆ°á»£c dÃ¹ng Ä‘á»ƒ Ä‘o á»©ng dá»¥ng nÃ o tráº» sá»­ dá»¥ng vÃ  thá»i gian sá»­ dá»¥ng trÃªn Android, sau Ä‘Ã³ hiá»ƒn thá»‹ dá»¯ liá»‡u nÃ y cho phá»¥ huynh hoáº·c ngÆ°á»i giÃ¡m há»™ Ä‘Æ°á»£c chá»‰ Ä‘á»‹nh Ä‘á»ƒ quáº£n lÃ½ thá»i gian mÃ n hÃ¬nh.';

  @override
  String get permissionOnboardingUsagePrimaryButton => 'Cho phÃ©p';

  @override
  String get permissionOnboardingUsageSettingsButton => 'Má»Ÿ cÃ i Ä‘áº·t chung';

  @override
  String get permissionOnboardingStepNotificationsLabel => 'ThÃ´ng bÃ¡o';

  @override
  String get permissionOnboardingStepLocationLabel => 'Vá»‹ trÃ­';

  @override
  String get permissionOnboardingStepBackgroundLocationLabel => 'LuÃ´n cho phÃ©p';

  @override
  String get permissionOnboardingStepMediaLabel => 'áº¢nh';

  @override
  String get permissionOnboardingStepUsageLabel => 'Sá»­ dá»¥ng';

  @override
  String get permissionOnboardingStepAccessibilityLabel => 'Trá»£ nÄƒng';

  @override
  String get permissionOnboardingStepBatteryLabel => 'Pin';

  @override
  String get permissionOnboardingSystemDeniedMessage =>
      'Quyá»n nÃ y Ä‘ang bá»‹ tá»« chá»‘i á»Ÿ há»‡ thá»‘ng. HÃ£y má»Ÿ cÃ i Ä‘áº·t Ä‘á»ƒ cáº¥p láº¡i.';

  @override
  String get permissionOnboardingNotGrantedMessage =>
      'Quyá»n nÃ y chÆ°a Ä‘Æ°á»£c cáº¥p. Báº¡n cÃ³ thá»ƒ thá»­ láº¡i hoáº·c thiáº¿t láº­p sau.';

  @override
  String get permissionOnboardingNotificationHelperText =>
      'Chá»‰ cáº§n cáº¥p quyá»n khi dÃ¹ng app trÆ°á»›c. Ngay sau bÆ°á»›c nÃ y app sáº½ hÆ°á»›ng dáº«n báº­t thÃªm \"Allow all the time\" Ä‘á»ƒ tracking ná»n hoáº¡t Ä‘á»™ng á»•n Ä‘á»‹nh.';

  @override
  String get permissionOnboardingGuideVideoLoadFailed =>
      'KhÃ´ng táº£i Ä‘Æ°á»£c video hÆ°á»›ng dáº«n';

  @override
  String get permissionOnboardingGuideVideoPlaceholder =>
      'Video hÆ°á»›ng dáº«n sáº½ hiá»ƒn thá»‹ táº¡i Ä‘Ã¢y';

  @override
  String get applyButton => 'Ãp dá»¥ng';

  @override
  String get commonStartLabel => 'Báº¯t Ä‘áº§u';

  @override
  String get commonEndLabel => 'Káº¿t thÃºc';

  @override
  String get childLocationSosSending => 'Äang gá»­i SOS...';

  @override
  String childLocationSosError(String error) {
    return 'Lá»—i gá»­i SOS: $error';
  }

  @override
  String get childLocationCurrentJourneyTitle => 'HÃ nh trÃ¬nh hiá»‡n táº¡i';

  @override
  String get childLocationTravelHistoryTitle => 'Lá»‹ch sá»­ di chuyá»ƒn';

  @override
  String get childLocationSelectedHistoryLabel => 'Lá»‹ch sá»­ Ä‘Ã£ chá»n';

  @override
  String get childLocationTodayLabel => 'HÃ´m nay';

  @override
  String get childLocationUpdatedJustNow => 'Cáº­p nháº­t vá»«a xong';

  @override
  String get childLocationUpdatedOneMinuteAgo => 'Cáº­p nháº­t 1 phÃºt trÆ°á»›c';

  @override
  String childLocationUpdatedMinutesAgo(int minutes) {
    return 'Cáº­p nháº­t $minutes phÃºt trÆ°á»›c';
  }

  @override
  String get childLocationRangeAllDay => 'Cáº£ ngÃ y';

  @override
  String get childLocationTooltipManageZones => 'Quáº£n lÃ½ vÃ¹ng';

  @override
  String get childLocationTooltipSafeRoute => 'Tuyáº¿n Ä‘Æ°á»ng an toÃ n';

  @override
  String get childLocationTooltipChooseMap => 'Chá»n báº£n Ä‘á»“';

  @override
  String get childLocationTagStart => 'Báº¯t Ä‘áº§u';

  @override
  String get childLocationTagEnd => 'Káº¿t thÃºc';

  @override
  String get childLocationTagGpsVeryWeak => 'GPS ráº¥t yáº¿u';

  @override
  String get childLocationTagGpsLost => 'Máº¥t GPS';

  @override
  String get childLocationStayedHereLabel => 'á»ž Ä‘Ã¢y Ä‘Æ°á»£c';

  @override
  String get childLocationStayedHereUnavailable => 'KhÃ´ng xÃ¡c Ä‘á»‹nh á»•n Ä‘á»‹nh';

  @override
  String get childLocationStopDurationHint => 'Thá»i gian dá»«ng';

  @override
  String get childLocationSpeedLabel => 'Tá»‘c Ä‘á»™';

  @override
  String get childLocationSpeedUnavailable => 'KhÃ´ng á»•n Ä‘á»‹nh';

  @override
  String get childLocationGpsTitle => 'GPS';

  @override
  String get childLocationPointCountTitle => 'Sá»‘ Ä‘iá»ƒm';

  @override
  String get childLocationPointCountUnit => 'Ä‘iá»ƒm';

  @override
  String get childLocationGpsAccuracyLabel => 'Sai sá»‘ GPS';

  @override
  String get childLocationMockGpsLabel => 'GPS giáº£ láº­p';

  @override
  String get childLocationMockGpsDetected => 'CÃ³ dáº¥u hiá»‡u';

  @override
  String get childLocationNoLabel => 'KhÃ´ng';

  @override
  String get childLocationDeviceStatusHint => 'Tráº¡ng thÃ¡i thiáº¿t bá»‹';

  @override
  String get childLocationTechnicalDetailsTitle => 'Xem chi tiáº¿t ká»¹ thuáº­t';

  @override
  String get childLocationDetailFullTimeLabel => 'Thá»i gian Ä‘áº§y Ä‘á»§';

  @override
  String get childLocationDetailHeadingLabel => 'HÆ°á»›ng di chuyá»ƒn';

  @override
  String get childLocationDetailCoordinatesLabel => 'Tá»a Ä‘á»™';

  @override
  String get childLocationDetailAccuracyLabel => 'Äá»™ chÃ­nh xÃ¡c';

  @override
  String get childLocationDurationZeroMinutes => '0 phÃºt';

  @override
  String childLocationDurationHoursMinutes(int hours, int minutes) {
    return '$hours giá» $minutes phÃºt';
  }

  @override
  String childLocationDurationMinutes(int minutes) {
    return '$minutes phÃºt';
  }

  @override
  String childLocationDurationSeconds(int seconds) {
    return '$seconds giÃ¢y';
  }

  @override
  String get childLocationGpsLostTitle => 'Máº¥t GPS Ä‘á»‹nh vá»‹';

  @override
  String get childLocationGpsVeryWeakSubtitle =>
      'TÃ­n hiá»‡u GPS ráº¥t yáº¿u, vá»‹ trÃ­ cÃ³ thá»ƒ khÃ´ng chÃ­nh xÃ¡c.';

  @override
  String childLocationGpsLostSubtitle(String meters) {
    return 'Sai sá»‘ lá»›n hÆ¡n $meters m';
  }

  @override
  String get childLocationStoppedNowTitle => 'Äang Ä‘á»©ng yÃªn';

  @override
  String childLocationStoppedNowSubtitle(String duration) {
    return 'Dá»«ng táº¡i Ä‘Ã¢y $duration';
  }

  @override
  String get childLocationStoppedHereTitle => 'Äá»©ng yÃªn táº¡i Ä‘Ã¢y';

  @override
  String childLocationStoppedHereSubtitle(String duration) {
    return 'Dá»«ng khoáº£ng $duration';
  }

  @override
  String get childLocationJourneyStartSubtitle => 'Äiá»ƒm báº¯t Ä‘áº§u hÃ nh trÃ¬nh';

  @override
  String get childLocationJourneyEndSubtitle => 'Äiá»ƒm káº¿t thÃºc hÃ nh trÃ¬nh';

  @override
  String childLocationUpdatedAt(String time) {
    return 'Cáº­p nháº­t lÃºc $time';
  }

  @override
  String childLocationPassedAt(String time) {
    return 'Äi qua Ä‘iá»ƒm nÃ y lÃºc $time';
  }

  @override
  String get childLocationHeadlineWalking => 'Äang Ä‘i bá»™';

  @override
  String get childLocationHeadlineBicycle => 'Äang Ä‘i xe Ä‘áº¡p';

  @override
  String get childLocationHeadlineVehicle => 'Äang Ä‘i xe';

  @override
  String get childLocationHeadlineStill => 'Äang Ä‘á»©ng yÃªn';

  @override
  String get childLocationHeadlineUnknown => 'KhÃ´ng rÃµ tráº¡ng thÃ¡i';

  @override
  String get childLocationSpeedAlmostStill => 'Gáº§n nhÆ° khÃ´ng di chuyá»ƒn';

  @override
  String get childLocationAccuracySevere => 'Máº¥t GPS nghiÃªm trá»ng';

  @override
  String get childLocationAccuracyLost => 'Máº¥t GPS Ä‘á»‹nh vá»‹';

  @override
  String childLocationAccuracyGood(String meters) {
    return 'KhÃ¡ chÃ­nh xÃ¡c ($meters m)';
  }

  @override
  String childLocationAccuracyModerate(String meters) {
    return 'ChÃ­nh xÃ¡c vá»«a ($meters m)';
  }

  @override
  String get childLocationTimeWindowTitle => 'Chá»n khung giá»';

  @override
  String get childLocationTimeWindowSubtitle =>
      'Chá»‰ táº£i vÃ  hiá»ƒn thá»‹ lá»‹ch sá»­ trong khoáº£ng giá» Ä‘ang chá»n.';

  @override
  String get childLocationPresetMorning => 'SÃ¡ng';

  @override
  String get childLocationPresetAfternoon => 'Chiá»u';

  @override
  String get childLocationPresetEvening => 'Tá»‘i';

  @override
  String get childLocationNoDataTitle => 'ChÆ°a cÃ³ dá»¯ liá»‡u trong khung nÃ y';

  @override
  String get childLocationNoDataSubtitle =>
      'Thá»­ Ä‘á»•i khung giá» khÃ¡c hoáº·c chá»n ngÃ y khÃ¡c Ä‘á»ƒ xem láº¡i hÃ nh trÃ¬nh.';

  @override
  String get childLocationSummaryDateLabel => 'NgÃ y';

  @override
  String get childLocationSummaryTimeRangeLabel => 'Khung giá»';

  @override
  String get childLocationLiveLabel => 'Trá»±c tiáº¿p';

  @override
  String get childLocationRecentPointsTitle => 'CÃ¡c Ä‘iá»ƒm gáº§n Ä‘Ã¢y';

  @override
  String childLocationLoadMoreRecentHours(Object label) {
    return 'Táº£i thÃªm $label';
  }

  @override
  String get childLocationViewAllButton => 'Xem táº¥t cáº£';

  @override
  String get childLocationTapToSeeDetails => 'Báº¥m Ä‘á»ƒ xem chi tiáº¿t';

  @override
  String get childLocationWeakGpsSignal => 'TÃ­n hiá»‡u GPS yáº¿u';

  @override
  String childLocationPointCount(int count) {
    return '$count Ä‘iá»ƒm';
  }

  @override
  String get childLocationNetworkGapTitle => 'Máº¥t máº¡ng';

  @override
  String childLocationNetworkGapSubtitle(Object duration) {
    return 'Báº£n Ä‘á»“ ná»‘i táº¡m 2 Ä‘áº§u vÃ¬ dá»¯ liá»‡u bá»‹ ngáº¯t trong $duration.';
  }

  @override
  String get childLocationNetworkGapChip => 'Máº¥t káº¿t ná»‘i';

  @override
  String get childLocationNetworkGapFromLabel => 'Máº¥t tá»«';

  @override
  String get childLocationNetworkGapToLabel => 'CÃ³ láº¡i lÃºc';

  @override
  String get childLocationMapSearchSubtitle =>
      'TÃ¬m kiáº¿m Ä‘á»‹a Ä‘iá»ƒm Ä‘á»ƒ chá»n nhanh trÃªn báº£n Ä‘á»“.';

  @override
  String get childLocationMapSearchInputHint =>
      'Nháº­p tÃªn Ä‘Æ°á»ng, trÆ°á»ng há»c, Ä‘á»‹a chá»‰...';

  @override
  String get childLocationMapSearchMinChars =>
      'Nháº­p Ã­t nháº¥t 2 kÃ½ tá»± Ä‘á»ƒ tÃ¬m Ä‘á»‹a Ä‘iá»ƒm.';

  @override
  String get childLocationMapSearchNoResults =>
      'KhÃ´ng tÃ¬m tháº¥y Ä‘á»‹a Ä‘iá»ƒm phÃ¹ há»£p.';

  @override
  String get childLocationSafeRouteRecoveredBanner =>
      'ÄÃ£ quay láº¡i tuyáº¿n an toÃ n';

  @override
  String get locationNoLocationYet => 'ChÆ°a cÃ³ vá»‹ trÃ­';

  @override
  String locationCoordinatesSummary(String lat, String lng) {
    return 'Lat $lat â€¢ Lng $lng';
  }

  @override
  String get locationSearchHint => 'TÃ¬m kiáº¿m';

  @override
  String get locationMessageSent => 'ÄÃ£ gá»­i tin nháº¯n';

  @override
  String get locationChildInfoTitle => 'ThÃ´ng tin';

  @override
  String get locationQuickMessageHint => 'Gá»­i tin nháº¯n nhanh...';

  @override
  String get locationStatusStudying => 'Äang há»c';

  @override
  String get locationStopSearching => 'Táº¯t tÃ¬m kiáº¿m';

  @override
  String incomingSosConfirmFailed(Object error) {
    return 'XÃ¡c nháº­n tháº¥t báº¡i: $error';
  }

  @override
  String get incomingSosEmergencyTitle => 'ðŸš¨ CÃ³ SOS kháº©n cáº¥p!';

  @override
  String get incomingSosResolvingButton => 'ÄANG Xá»¬ LÃ';

  @override
  String get incomingSosConfirmButton => 'XÃC NHáº¬N';

  @override
  String get sosConfirmedRoleParent => 'Phá»¥ huynh';

  @override
  String get sosConfirmedRoleChild => 'Tráº»';

  @override
  String get sosConfirmedNameLabel => 'TÃªn';

  @override
  String get sosConfirmedSenderLabel => 'NgÆ°á»i gá»­i';

  @override
  String get sosConfirmedSentAtLabel => 'Gá»­i lÃºc';

  @override
  String get sosConfirmedConfirmedAtLabel => 'XÃ¡c nháº­n lÃºc';

  @override
  String get sosConfirmedAccuracyLabel => 'Äá»™ chÃ­nh xÃ¡c';

  @override
  String get sosConfirmedTitle => 'ÄÃ£ xÃ¡c nháº­n SOS';

  @override
  String get sosConfirmedCloseButton => 'ÄÃ“NG';

  @override
  String get sosButtonLabel => 'SOS';

  @override
  String get parentPhoneSaveFailed => 'KhÃ´ng thá»ƒ lÆ°u sá»‘ Ä‘iá»‡n thoáº¡i';

  @override
  String get parentPhoneAddTitle => 'ThÃªm sá»‘ Ä‘iá»‡n thoáº¡i cá»§a con báº¡n';

  @override
  String get parentPhoneAddSubtitle =>
      'LiÃªn láº¡c vá»›i con ngay cáº£ khi Ä‘iá»‡n thoáº¡i cá»§a con Ä‘ang á»Ÿ cháº¿ Ä‘á»™ im láº·ng';

  @override
  String get parentPhoneAddButton => 'ThÃªm vÃ o';

  @override
  String get parentPhoneContactHasNoNumber =>
      'LiÃªn há»‡ nÃ y khÃ´ng cÃ³ sá»‘ Ä‘iá»‡n thoáº¡i';

  @override
  String parentPhonePickFailed(Object error) {
    return 'KhÃ´ng thá»ƒ láº¥y sá»‘ Ä‘iá»‡n thoáº¡i tá»« danh báº¡: $error';
  }

  @override
  String get parentPhonePickTitle => 'Chá»n sá»‘ Ä‘iá»‡n thoáº¡i';

  @override
  String get parentPhoneOpenContactsButton => 'Má»Ÿ danh báº¡';

  @override
  String get appImageReplaceOption => 'Thay Ä‘á»•i áº£nh';

  @override
  String get appImageLoadFailed => 'KhÃ´ng táº£i Ä‘Æ°á»£c áº£nh';

  @override
  String get photoUpdateFailedMessage => 'Cáº­p nháº­t áº£nh tháº¥t báº¡i';

  @override
  String get mapTypeSheetTitle => 'Loáº¡i báº£n Ä‘á»“';

  @override
  String get mapTypeDefault => 'Máº·c Ä‘á»‹nh';

  @override
  String get mapTypeSatellite => 'Vá»‡ tinh';

  @override
  String get mapTypeTerrain => 'Äá»‹a hÃ¬nh';

  @override
  String get phoneHelperSaveSuccessTitle => 'ThÃªm thÃ nh cÃ´ng';

  @override
  String get phoneHelperSaveSuccessMessage =>
      'Sá»‘ Ä‘iá»‡n thoáº¡i cá»§a bÃ© Ä‘Ã£ Ä‘Æ°á»£c lÆ°u thÃ nh cÃ´ng';

  @override
  String phoneHelperCallActionFailed(Object error) {
    return 'KhÃ´ng thá»ƒ thá»±c hiá»‡n cuá»™c gá»i: $error';
  }

  @override
  String get phoneHelperOpenDialerFailed => 'KhÃ´ng thá»ƒ má»Ÿ á»©ng dá»¥ng Ä‘iá»‡n thoáº¡i';

  @override
  String phoneHelperLaunchCallFailed(Object error) {
    return 'Gá»i Ä‘iá»‡n tháº¥t báº¡i: $error';
  }

  @override
  String get scheduleRepositoryNotFound => 'Lá»‹ch trÃ¬nh khÃ´ng tá»“n táº¡i';

  @override
  String get scheduleRepositoryCurrentNotFound =>
      'Lá»‹ch trÃ¬nh hiá»‡n táº¡i khÃ´ng tá»“n táº¡i';

  @override
  String get scheduleRepositoryHistoryNotFound => 'Báº£n lá»‹ch sá»­ khÃ´ng tá»“n táº¡i';

  @override
  String get locationRepositoryLoginRequired =>
      'ChÆ°a Ä‘Äƒng nháº­p, khÃ´ng thá»ƒ gá»­i vá»‹ trÃ­';

  @override
  String get locationRepositoryParentIdNotFound =>
      'KhÃ´ng tÃ¬m tháº¥y tÃ i khoáº£n phá»¥ huynh';

  @override
  String get safeRouteTripStatusActive => 'Äang theo dÃµi';

  @override
  String get safeRouteTripStatusTemporarilyDeviated => 'Táº¡m lá»‡ch tuyáº¿n';

  @override
  String get safeRouteTripStatusDeviated => 'Lá»‡ch tuyáº¿n';

  @override
  String get safeRouteTripStatusCompleted => 'ÄÃ£ Ä‘áº¿n nÆ¡i';

  @override
  String get safeRouteTripStatusCancelled => 'ÄÃ£ há»§y';

  @override
  String get safeRouteTripStatusPlanned => 'ÄÃ£ lÃªn lá»‹ch';

  @override
  String get safeRouteTripStatusNoTrip => 'ChÆ°a cÃ³ chuyáº¿n Ä‘i';

  @override
  String get safeRouteTravelModeWalking => 'Äi bá»™';

  @override
  String get safeRouteTravelModeMotorbike => 'Xe mÃ¡y';

  @override
  String get safeRouteTravelModePickup => 'ÄÃ³n con';

  @override
  String get safeRouteTravelModeOtherVehicle => 'PhÆ°Æ¡ng tiá»‡n khÃ¡c';

  @override
  String safeRouteDistanceMeters(int value) {
    return '$value m';
  }

  @override
  String safeRouteDistanceKilometers(Object value) {
    return '$value km';
  }

  @override
  String safeRouteDurationMinutes(int minutes) {
    return '$minutes phÃºt';
  }

  @override
  String safeRouteDurationHours(int hours) {
    return '$hours giá»';
  }

  @override
  String safeRouteDurationHoursMinutes(int hours, int minutes) {
    return '$hours giá» $minutes phÃºt';
  }

  @override
  String safeRouteDurationHoursMinutesShort(int hours, int minutes) {
    return '$hours giá» ${minutes}p';
  }

  @override
  String safeRouteEtaApproxMinutes(int minutes) {
    return '~$minutes phÃºt';
  }

  @override
  String safeRouteEtaApproxHours(int hours) {
    return '~$hours giá»';
  }

  @override
  String safeRouteEtaApproxHoursMinutes(int hours, int minutes) {
    return '~$hours giá» ${minutes}p';
  }

  @override
  String get safeRouteTodayLabel => 'HÃ´m nay';

  @override
  String get safeRouteTomorrowLabel => 'NgÃ y mai';

  @override
  String get safeRouteNowLabel => 'BÃ¢y giá»';

  @override
  String safeRouteSecondsAgo(int seconds) {
    return '${seconds}s';
  }

  @override
  String safeRouteFormatTime(Object hour, Object minute) {
    return '$hour:$minute';
  }

  @override
  String get safeRouteTrackNowLabel => 'Theo dÃµi ngay';

  @override
  String get safeRouteNoRepeatSummary =>
      'KhÃ´ng láº·p láº¡i, tuyáº¿n sáº½ Ä‘Æ°á»£c Ã¡p dá»¥ng cho má»™t lá»‹ch theo dÃµi gáº§n nháº¥t.';

  @override
  String safeRouteRepeatSummaryText(Object labels) {
    return 'Láº·p láº¡i vÃ o: $labels';
  }

  @override
  String get safeRouteCurrentRoutePrimary => 'Äang Ä‘i trÃªn tuyáº¿n chÃ­nh';

  @override
  String safeRouteCurrentRouteAlternativeIndexed(int index) {
    return 'Äang Ä‘i trÃªn tuyáº¿n phá»¥ $index';
  }

  @override
  String get safeRouteCurrentRouteAlternative => 'Äang Ä‘i trÃªn tuyáº¿n phá»¥';

  @override
  String safeRouteRouteFallbackNameText(Object id) {
    return 'Tuyáº¿n $id';
  }

  @override
  String get safeRouteSelectedRouteFallbackName => 'Tuyáº¿n Ä‘Ã£ chá»n';

  @override
  String get safeRouteGuidanceLoadingRoute => 'Äang táº£i tuyáº¿n Ä‘Æ°á»ng...';

  @override
  String get safeRouteGuidanceDangerArea => 'vÃ¹ng nguy hiá»ƒm';

  @override
  String get safeRouteGuidanceReturnToSafeRoute => 'Quay láº¡i tuyáº¿n an toÃ n';

  @override
  String get safeRouteGuidanceArrivedInstruction => 'Sáº¯p tá»›i nÆ¡i rá»“i';

  @override
  String get safeRouteGuidanceArrivedDescription =>
      'Äi tiáº¿p Ä‘áº¿n Ä‘iá»ƒm Ä‘Ã­ch Ä‘á»ƒ hoÃ n thÃ nh hÃ nh trÃ¬nh.';

  @override
  String get safeRouteGuidanceStatusOnRoute => 'ÄÃºng tuyáº¿n';

  @override
  String get safeRouteGuidanceStatusOffRoute => 'Lá»‡ch tuyáº¿n';

  @override
  String get safeRouteGuidanceStatusAlmostThere => 'Sáº¯p Ä‘áº¿n nÆ¡i';

  @override
  String get safeRouteGuidanceStatusSafeRoute => 'Tuyáº¿n an toÃ n';

  @override
  String safeRouteGuidanceLeaveDangerZone(Object hazardName) {
    return 'Rá»i khá»i $hazardName ngay';
  }

  @override
  String safeRouteGuidanceDangerDescription(Object hazardName) {
    return 'Äi ra khá»i $hazardName vÃ  quay láº¡i tuyáº¿n an toÃ n.';
  }

  @override
  String safeRouteGuidanceOffRouteDescription(Object distanceLabel) {
    return 'Báº¡n Ä‘ang cÃ¡ch tuyáº¿n khoáº£ng $distanceLabel.';
  }

  @override
  String safeRouteGuidanceRemainingDescription(Object distanceLabel) {
    return 'CÃ²n $distanceLabel Ä‘á»ƒ Ä‘áº¿n Ä‘iá»ƒm Ä‘Ã­ch.';
  }

  @override
  String safeRouteGuidanceContinueStraight(Object distanceLabel) {
    return 'Äi tháº³ng $distanceLabel';
  }

  @override
  String safeRouteGuidanceTurnLeft(Object distanceLabel) {
    return 'Ráº½ trÃ¡i sau $distanceLabel';
  }

  @override
  String safeRouteGuidanceTurnRight(Object distanceLabel) {
    return 'Ráº½ pháº£i sau $distanceLabel';
  }

  @override
  String safeRouteGuidanceKeepLeft(Object distanceLabel) {
    return 'Cháº¿ch trÃ¡i sau $distanceLabel';
  }

  @override
  String safeRouteGuidanceKeepRight(Object distanceLabel) {
    return 'Cháº¿ch pháº£i sau $distanceLabel';
  }

  @override
  String safeRouteGuidanceMakeUTurn(Object distanceLabel) {
    return 'Quay Ä‘áº§u sau $distanceLabel';
  }

  @override
  String get safeRouteGuidanceEtaNow => 'Äáº¿n ngay bÃ¢y giá»';

  @override
  String get safeRouteVisualDangerTitle => 'Äi vÃ o vÃ¹ng nguy hiá»ƒm!';

  @override
  String safeRouteVisualDangerSubtitle(Object hazardName) {
    return 'BÃ© Ä‘ang á»Ÿ gáº§n $hazardName.';
  }

  @override
  String get safeRouteVisualDangerBadge => 'NGUY HIá»‚M';

  @override
  String safeRouteVisualOffRouteTitle(Object distanceLabel) {
    return 'Äang lá»‡ch tuyáº¿n ~$distanceLabel';
  }

  @override
  String get safeRouteVisualOffRouteSubtitle =>
      'BÃ© Ä‘ang Ä‘i ra ngoÃ i hÃ nh lang an toÃ n Ä‘Ã£ chá»n.';

  @override
  String get safeRouteVisualOffRouteBadge => 'Lá»†CH TUYáº¾N';

  @override
  String get safeRouteVisualCompletedTitle => 'BÃ© Ä‘Ã£ Ä‘áº¿n nÆ¡i an toÃ n';

  @override
  String get safeRouteVisualCompletedSubtitle =>
      'HÃ nh trÃ¬nh vá»«a Ä‘Æ°á»£c Ä‘Ã¡nh dáº¥u hoÃ n thÃ nh.';

  @override
  String get safeRouteVisualCompletedBadge => 'HOÃ€N THÃ€NH';

  @override
  String get safeRouteVisualCancelledTitle => 'ÄÃ£ dá»«ng theo dÃµi hÃ nh trÃ¬nh';

  @override
  String get safeRouteVisualCancelledSubtitle =>
      'Phá»¥ huynh Ä‘Ã£ káº¿t thÃºc cháº¿ Ä‘á»™ giÃ¡m sÃ¡t hiá»‡n táº¡i.';

  @override
  String get safeRouteVisualCancelledBadge => 'ÄÃƒ Dá»ªNG';

  @override
  String get safeRouteVisualPlannedTitle => 'Tuyáº¿n Ä‘ang chá» kÃ­ch hoáº¡t';

  @override
  String get safeRouteVisualPlannedSubtitle =>
      'Safe Route sáº½ tá»± báº¯t Ä‘áº§u theo ngÃ y giá» Ä‘Ã£ cÃ i Ä‘áº·t.';

  @override
  String get safeRouteVisualPlannedBadge => 'ÄÃƒ LÃŠN Lá»ŠCH';

  @override
  String get safeRouteVisualActiveTitle => 'Äang Ä‘i Ä‘Ãºng tuyáº¿n';

  @override
  String get safeRouteVisualActiveSubtitle =>
      'BÃ© Ä‘ang trong hÃ nh lang an toÃ n Ä‘Ã£ chá»n.';

  @override
  String get safeRouteVisualActiveBadge => 'AN TOÃ€N';

  @override
  String get safeRouteErrorMaxAlternative =>
      'Chá»‰ nÃªn chá»n tá»‘i Ä‘a 2 tuyáº¿n phá»¥ cho má»—i chuyáº¿n.';

  @override
  String get safeRouteErrorNoCurrentLocation =>
      'ChÆ°a cÃ³ vá»‹ trÃ­ hiá»‡n táº¡i cá»§a tráº».';

  @override
  String get safeRouteErrorNeedStartEnd => 'Cáº§n chá»n Ä‘iá»ƒm A vÃ  Ä‘iá»ƒm B trÆ°á»›c.';

  @override
  String get safeRouteErrorLoadHistoryRoute =>
      'KhÃ´ng táº£i Ä‘Æ°á»£c tuyáº¿n Ä‘Æ°á»ng trong lá»‹ch sá»­.';

  @override
  String get safeRouteErrorNeedRoute => 'Cáº§n chá»n má»™t tuyáº¿n Ä‘Æ°á»ng an toÃ n.';

  @override
  String get safeRouteErrorLoginAgain =>
      'Báº¡n cáº§n Ä‘Äƒng nháº­p láº¡i Ä‘á»ƒ báº¯t Ä‘áº§u chuyáº¿n Ä‘i.';

  @override
  String get safeRouteErrorSelectTimeForRepeat =>
      'Chá»n giá» Ã¡p dá»¥ng náº¿u muá»‘n láº·p láº¡i theo ngÃ y.';

  @override
  String get safeRouteUseCurrentLocationLabel => 'Vá»‹ trÃ­ hiá»‡n táº¡i';

  @override
  String get safeRouteStartPointOfRoute => 'Äiá»ƒm báº¯t Ä‘áº§u cá»§a tuyáº¿n';

  @override
  String get safeRouteEndPointOfRoute => 'Äiá»ƒm káº¿t thÃºc cá»§a tuyáº¿n';

  @override
  String get safeRouteCancelledByParentReason => 'ÄÃ£ há»§y bá»Ÿi phá»¥ huynh';

  @override
  String safeRouteSpeedValue(Object value) {
    return '$value km/h';
  }

  @override
  String get safeRoutePageSelectRouteTitle => 'Chá»n tuyáº¿n an toÃ n';

  @override
  String get safeRoutePageJourneyTitle => 'HÃ nh trÃ¬nh an toÃ n';

  @override
  String get safeRouteSnackbarAutoFollowEnabled => 'ÄÃ£ báº­t Auto follow';

  @override
  String get safeRouteSnackbarAutoFollowDisabled => 'ÄÃ£ táº¯t Auto follow';

  @override
  String get safeRouteSearchStartTitle => 'TÃ¬m Ä‘iá»ƒm Ä‘i';

  @override
  String get safeRouteSearchStartHint =>
      'TÃ¬m nhÃ , Ä‘iá»ƒm Ä‘Ã³n hoáº·c vá»‹ trÃ­ báº¯t Ä‘áº§u hÃ nh trÃ¬nh.';

  @override
  String get safeRouteSearchEndTitle => 'TÃ¬m Ä‘iá»ƒm Ä‘áº¿n';

  @override
  String get safeRouteSearchEndHint =>
      'TÃ¬m trÆ°á»ng há»c, nhÃ  ngÆ°á»i thÃ¢n hoáº·c Ä‘iá»ƒm Ä‘áº¿n cáº§n theo dÃµi.';

  @override
  String safeRouteScheduledAutoActivationPrefix(Object summary) {
    return 'Tá»± kÃ­ch hoáº¡t theo lá»‹ch Â· $summary';
  }

  @override
  String get safeRouteTopSubtitleWarning => 'Äang lá»‡ch tuyáº¿n';

  @override
  String get safeRouteTopSubtitleDanger => 'Cáº£nh bÃ¡o nguy hiá»ƒm';

  @override
  String get safeRouteTopSubtitleReady => 'Äiá»ƒm Ä‘i vÃ  Ä‘iá»ƒm Ä‘áº¿n Ä‘Ã£ sáºµn sÃ ng';

  @override
  String get safeRouteTopSubtitleOnlyStart =>
      'ÄÃ£ chá»n Ä‘iá»ƒm Ä‘i, tiáº¿p tá»¥c chá»n Ä‘iá»ƒm Ä‘áº¿n';

  @override
  String get safeRouteTopSubtitleChoosePoints =>
      'Chá»n Ä‘iá»ƒm Ä‘i vÃ  Ä‘iá»ƒm Ä‘áº¿n theo phong cÃ¡ch báº£n Ä‘á»“';

  @override
  String get safeRouteSelectScheduleDateHelp => 'Chá»n ngÃ y Ã¡p dá»¥ng';

  @override
  String get safeRouteSelectScheduleTimeTitle => 'Chá»n giá» Ã¡p dá»¥ng';

  @override
  String get safeRouteArrivedDialogTitle => 'BÃ© Ä‘Ã£ Ä‘áº¿n nÆ¡i an toÃ n';

  @override
  String get safeRouteArrivedDialogMessage =>
      'HÃ nh trÃ¬nh nÃ y Ä‘Ã£ Ä‘Æ°á»£c hoÃ n táº¥t. Báº¡n cÃ³ thá»ƒ quay láº¡i Ä‘á»ƒ chá»n tuyáº¿n Ä‘Æ°á»ng má»›i cho bÃ©.';

  @override
  String get safeRouteArrivedDialogConfirm => 'Quay láº¡i chá»n tuyáº¿n Ä‘Æ°á»ng';

  @override
  String get safeRouteCancelPlannedTitle => 'XÃ¡c nháº­n há»§y lá»‹ch Safe Route';

  @override
  String get safeRouteCancelActiveTitle => 'XÃ¡c nháº­n há»§y tuyáº¿n Safe Route';

  @override
  String get safeRouteCancelPlannedMessage =>
      'Lá»‹ch theo dÃµi nÃ y sáº½ khÃ´ng tá»± kÃ­ch hoáº¡t ná»¯a. Báº¡n cÃ³ cháº¯c muá»‘n há»§y khÃ´ng?';

  @override
  String get safeRouteCancelActiveMessage =>
      'Tuyáº¿n Ä‘Æ°á»ng an toÃ n hiá»‡n táº¡i sáº½ dá»«ng theo dÃµi ngay. Báº¡n cÃ³ cháº¯c muá»‘n há»§y khÃ´ng?';

  @override
  String get safeRouteCancelPlannedConfirm => 'XÃ¡c nháº­n há»§y lá»‹ch';

  @override
  String get safeRouteCancelActiveConfirm => 'XÃ¡c nháº­n há»§y tuyáº¿n';

  @override
  String get safeRouteDialogBack => 'Quay láº¡i';

  @override
  String get safeRouteTooltipFocusChild => 'ÄÆ°a camera tá»›i bÃ©';

  @override
  String get safeRouteTooltipDisableAutoFollow => 'Táº¯t Auto follow';

  @override
  String get safeRouteTooltipEnableAutoFollow => 'Báº­t Auto follow';

  @override
  String get safeRouteAutoFollowLabel => 'Auto follow';

  @override
  String get safeRouteTooltipHideHazards => 'áº¨n vÃ¹ng nguy hiá»ƒm';

  @override
  String get safeRouteTooltipShowHazards => 'Hiá»‡n vÃ¹ng nguy hiá»ƒm';

  @override
  String get safeRouteTooltipMapType => 'Chá»n kiá»ƒu báº£n Ä‘á»“';

  @override
  String get safeRouteMapHintPlaceStart => 'Cháº¡m trÃªn báº£n Ä‘á»“ Ä‘á»ƒ Ä‘áº·t Ä‘iá»ƒm Ä‘i';

  @override
  String get safeRouteMapHintPlaceEnd => 'Cháº¡m trÃªn báº£n Ä‘á»“ Ä‘á»ƒ Ä‘áº·t Ä‘iá»ƒm Ä‘áº¿n';

  @override
  String get safeRouteMapHintTapStart =>
      'Cháº¡m trÃªn báº£n Ä‘á»“ Ä‘á»ƒ chá»n Ä‘iá»ƒm Ä‘i cho bÃ©.';

  @override
  String get safeRouteMapHintTapEnd =>
      'Cháº¡m trÃªn báº£n Ä‘á»“ Ä‘á»ƒ chá»n Ä‘iá»ƒm Ä‘áº¿n cá»§a bÃ©.';

  @override
  String get safeRouteSnackbarSelectedEndPoint =>
      'ÄÃ£ chá»n Ä‘iá»ƒm Ä‘áº¿n trÃªn báº£n Ä‘á»“';

  @override
  String get safeRouteSnackbarSelectedStartPoint =>
      'ÄÃ£ chá»n Ä‘iá»ƒm Ä‘i trÃªn báº£n Ä‘á»“';

  @override
  String get safeRouteSelectSafeRouteTitle => 'Chá»n tuyáº¿n an toÃ n';

  @override
  String get safeRouteSuggestedRoutesTitle => 'CÃ¡c tuyáº¿n Ä‘Æ°á»ng gá»£i Ã½';

  @override
  String get safeRouteSuggestedRoutesSubtitle =>
      'Æ¯u tiÃªn an toÃ n, dá»… theo dÃµi vÃ  Ã­t Ä‘i qua vÃ¹ng nguy hiá»ƒm';

  @override
  String get safeRouteHistoryButton => 'Lá»‹ch sá»­';

  @override
  String get safeRouteRefreshingRoutes => 'Äang tÃ¬m...';

  @override
  String get safeRouteRefreshButton => 'LÃ m má»›i';

  @override
  String get safeRouteConfirmingRoute => 'Äang xÃ¡c nháº­n tuyáº¿n...';

  @override
  String get safeRouteFetchSuggestedRoutes => 'Láº¥y gá»£i Ã½ tuyáº¿n Ä‘Æ°á»ng';

  @override
  String get safeRouteHintSelectingStart =>
      'Cháº¡m trÃªn báº£n Ä‘á»“ Ä‘á»ƒ chá»n Ä‘iá»ƒm Ä‘i cho bÃ©.';

  @override
  String get safeRouteHintSelectingEnd =>
      'Cháº¡m trÃªn báº£n Ä‘á»“ Ä‘á»ƒ chá»n Ä‘iá»ƒm Ä‘áº¿n cá»§a bÃ©.';

  @override
  String get safeRouteHintMissingPoints =>
      'Chá»n Ä‘iá»ƒm A vÃ  Ä‘iá»ƒm B theo phong cÃ¡ch báº£n Ä‘á»“, sau Ä‘Ã³ xem cÃ¡c tuyáº¿n gá»£i Ã½.';

  @override
  String get safeRouteHintReadyChooseRoute =>
      'ÄÃ£ cÃ³ Ä‘á»§ Ä‘iá»ƒm Ä‘i vÃ  Ä‘iá»ƒm Ä‘áº¿n. Báº¡n cÃ³ thá»ƒ chá»n tuyáº¿n an toÃ n nháº¥t Ä‘á»ƒ báº¯t Ä‘áº§u giÃ¡m sÃ¡t.';

  @override
  String get safeRouteEmptyRoutesNeedPoints =>
      'HÃ£y chá»n cáº£ Ä‘iá»ƒm Ä‘i vÃ  Ä‘iá»ƒm Ä‘áº¿n Ä‘á»ƒ app Ä‘á» xuáº¥t cÃ¡c tuyáº¿n Ä‘Æ°á»ng an toÃ n.';

  @override
  String get safeRouteEmptyRoutesRefresh =>
      'Nháº¥n \"LÃ m má»›i\" hoáº·c nÃºt phÃ­a dÆ°á»›i Ä‘á»ƒ láº¥y láº¡i danh sÃ¡ch tuyáº¿n gá»£i Ã½.';

  @override
  String get safeRoutePrimaryActionSaveSchedule =>
      'LÆ°u tuyáº¿n vÃ  lÃªn lá»‹ch theo dÃµi';

  @override
  String get safeRoutePrimaryActionStartSelectedRoutes =>
      'Báº¯t Ä‘áº§u theo dÃµi cÃ¡c tuyáº¿n Ä‘Ã£ chá»n';

  @override
  String get safeRoutePrimaryActionSelectThisRoute =>
      'Chá»n tuyáº¿n nÃ y vÃ  báº¯t Ä‘áº§u theo dÃµi';

  @override
  String get safeRouteSelectedRoutesNeedPrimary =>
      'HÃ£y chá»n 1 tuyáº¿n chÃ­nh vÃ  cÃ³ thá»ƒ thÃªm tá»‘i Ä‘a 2 tuyáº¿n phá»¥.';

  @override
  String get safeRouteSelectedRoutesPrimaryOnly =>
      'ÄÃ£ chá»n 1 tuyáº¿n chÃ­nh. Báº¡n cÃ³ thá»ƒ thÃªm tá»‘i Ä‘a 2 tuyáº¿n phá»¥.';

  @override
  String safeRouteSelectedRoutesWithAlternatives(int count) {
    return 'ÄÃ£ chá»n 1 tuyáº¿n chÃ­nh vÃ  $count tuyáº¿n phá»¥.';
  }

  @override
  String get safeRouteActionStopTracking => 'Dá»«ng theo dÃµi';

  @override
  String get safeRouteActionViewRoute => 'Xem tuyáº¿n';

  @override
  String get safeRouteActionMarkArrived => 'ÄÃ¡nh dáº¥u Ä‘Ã£ Ä‘áº¿n';

  @override
  String get safeRouteActionCancelSchedule => 'Há»§y lá»‹ch';

  @override
  String get safeRouteActionChooseNewRoute => 'Chá»n tuyáº¿n má»›i';

  @override
  String get safeRouteActionRouteDetails => 'Chi tiáº¿t tuyáº¿n';

  @override
  String get safeRouteStatusSubtitleActive => 'BÃ© Ä‘ang bÃ¡m sÃ¡t tuyáº¿n Ä‘Ã£ chá»n';

  @override
  String get safeRouteStatusSubtitleTemporarilyDeviated =>
      'CÃ³ dáº¥u hiá»‡u lá»‡ch nháº¹, há»‡ thá»‘ng Ä‘ang tiáº¿p tá»¥c theo dÃµi';

  @override
  String get safeRouteStatusSubtitleDeviated =>
      'BÃ© Ä‘Ã£ lá»‡ch khá»i corridor an toÃ n';

  @override
  String get safeRouteStatusSubtitleCompleted => 'HÃ nh trÃ¬nh Ä‘Ã£ hoÃ n táº¥t';

  @override
  String get safeRouteStatusSubtitleCancelled => 'Phá»¥ huynh Ä‘Ã£ dá»«ng giÃ¡m sÃ¡t';

  @override
  String get safeRouteStatusSubtitlePlanned =>
      'Tuyáº¿n Ä‘ang chá» tá»›i giá» Ä‘á»ƒ tá»± kÃ­ch hoáº¡t';

  @override
  String get safeRouteStatusSubtitleNoData => 'ChÆ°a cÃ³ dá»¯ liá»‡u giÃ¡m sÃ¡t';

  @override
  String get safeRouteSpeedStanding => 'Äá»©ng yÃªn';

  @override
  String get safeRouteSpeedWalking => 'Äi bá»™';

  @override
  String get safeRouteSpeedCycling => 'Äi xe Ä‘áº¡p';

  @override
  String get safeRouteSpeedMoving => 'Di chuyá»ƒn';

  @override
  String get safeRouteMetricSpeed => 'Tá»‘c Ä‘á»™';

  @override
  String get safeRouteMetricOffRoute => 'Lá»‡ch tuyáº¿n';

  @override
  String get safeRouteMetricOffCorridor => 'NgoÃ i corridor';

  @override
  String get safeRouteMetricEta => 'Äáº¿n nÆ¡i';

  @override
  String get safeRouteMetricEtaEstimate => 'Æ¯á»›c tÃ­nh';

  @override
  String get safeRouteDangerCheckNow => 'Cáº§n kiá»ƒm tra ngay';

  @override
  String get safeRouteDeviceBatteryLabel => 'Pin thiáº¿t bá»‹';

  @override
  String get safeRouteProgressTitle => 'Tiáº¿n Ä‘á»™ hÃ nh trÃ¬nh';

  @override
  String safeRouteProgressCompletedPercent(int percent) {
    return 'ÄÃ£ Ä‘i $percent%';
  }

  @override
  String safeRouteProgressTraveled(Object traveled, Object total) {
    return 'ÄÃ£ Ä‘i $traveled/$total';
  }

  @override
  String safeRouteProgressRemainingPercent(int percent) {
    return 'CÃ²n láº¡i $percent%';
  }

  @override
  String safeRouteProgressRemaining(Object distance) {
    return 'CÃ²n $distance';
  }

  @override
  String get safeRouteFromLabel => 'Tá»«';

  @override
  String get safeRouteToLabel => 'Äáº¿n';

  @override
  String get safeRouteSearchOrSelectStart => 'TÃ¬m hoáº·c chá»n Ä‘iá»ƒm Ä‘i';

  @override
  String get safeRouteSearchOrSelectEnd => 'TÃ¬m hoáº·c chá»n Ä‘iá»ƒm Ä‘áº¿n';

  @override
  String get safeRouteScheduleTitle => 'Lá»‹ch Ã¡p dá»¥ng tuyáº¿n';

  @override
  String get safeRouteScheduleSubtitle =>
      'Äáº·t ngÃ y, giá» vÃ  chá»n cÃ¡c ngÃ y láº·p láº¡i cho tuyáº¿n Ä‘Æ°á»ng an toÃ n nÃ y.';

  @override
  String get safeRouteDateLabel => 'NgÃ y';

  @override
  String get safeRouteTimeLabel => 'Giá»';

  @override
  String get safeRouteRepeatByDayLabel => 'Láº·p láº¡i theo ngÃ y';

  @override
  String get safeRouteHistoryTripsTitle => 'Lá»‹ch sá»­ chuyáº¿n Ä‘Æ°á»ng an toÃ n';

  @override
  String get safeRouteHistoryTripsEmpty =>
      'ChÆ°a cÃ³ chuyáº¿n nÃ o Ä‘Æ°á»£c lÆ°u cho bÃ©.';

  @override
  String get safeRouteHistoryTripsSubtitle =>
      'Cháº¡m vÃ o tá»«ng chuyáº¿n Ä‘á»ƒ xem láº¡i tuyáº¿n Ä‘Æ°á»ng vÃ  tráº¡ng thÃ¡i di chuyá»ƒn.';

  @override
  String get safeRouteHistoryPageTitle => 'Lá»‹ch sá»­ tuyáº¿n Ä‘Æ°á»ng';

  @override
  String get safeRouteHistoryPageReviewSaved =>
      'Xem láº¡i toÃ n bá»™ hÃ nh trÃ¬nh an toÃ n Ä‘Ã£ lÆ°u';

  @override
  String get safeRouteHistoryEmptyState =>
      'ChÆ°a cÃ³ tuyáº¿n Ä‘Æ°á»ng nÃ o Ä‘Æ°á»£c lÆ°u trong lá»‹ch sá»­ Safe Route.';

  @override
  String get safeRouteNoRepeatLabel => 'KhÃ´ng láº·p láº¡i';

  @override
  String get safeRouteBadgeSafest => 'An toÃ n nháº¥t';

  @override
  String get safeRouteBadgeFewerHazards => 'Ãt vÃ¹ng nguy hiá»ƒm';

  @override
  String get safeRouteBadgeFaster => 'Nhanh hÆ¡n';

  @override
  String get safeRouteBadgeAlternative => 'Tuyáº¿n phá»¥';

  @override
  String get safeRouteRolePrimary => 'Tuyáº¿n chÃ­nh';

  @override
  String get safeRouteRoleAlternative => 'Tuyáº¿n phá»¥';

  @override
  String safeRouteCorridorLabel(Object distance) {
    return '$distance corridor';
  }

  @override
  String get safeRouteActionPrimarySelected => 'Äang lÃ  tuyáº¿n chÃ­nh';

  @override
  String get safeRouteActionSetPrimary => 'Äáº·t lÃ m tuyáº¿n chÃ­nh';

  @override
  String get safeRouteActionRemoveAlternative => 'Bá» tuyáº¿n phá»¥';

  @override
  String get safeRouteActionSelectAlternative => 'Chá»n tuyáº¿n phá»¥';

  @override
  String get safeRouteActionAlternativeLimitReached => 'ÄÃ£ Ä‘á»§ tuyáº¿n phá»¥';

  @override
  String get safeRouteRouteDescriptionStable =>
      'Tuyáº¿n khÃ¡ á»•n Ä‘á»‹nh, gáº§n nhÆ° khÃ´ng Ä‘i vÃ o vÃ¹ng nguy hiá»ƒm.';

  @override
  String get safeRouteRouteDescriptionOneHazard =>
      'CÃ³ 1 Ä‘iá»ƒm cáº§n lÆ°u Ã½ nhÆ°ng váº«n phÃ¹ há»£p Ä‘á»ƒ theo dÃµi an toÃ n.';

  @override
  String get safeRouteRouteDescriptionMoreHazards =>
      'Tuyáº¿n Ä‘i nhanh hÆ¡n nhÆ°ng cáº§n chÃº Ã½ vÃ¬ cÃ³ nhiá»u vÃ¹ng cáº£nh bÃ¡o hÆ¡n.';

  @override
  String safeRouteHazardCount(int count) {
    return '$count vÃ¹ng nguy hiá»ƒm';
  }

  @override
  String safeRouteAlternativeRouteCount(int count) {
    return '+$count tuyáº¿n phá»¥';
  }

  @override
  String get cupertinoTimePickerDoneButton => 'Xong';

  @override
  String get childLocationUpdatedOneHourAgo => 'Cáº­p nháº­t 1 giá» trÆ°á»›c';

  @override
  String childLocationUpdatedHoursAgo(int hours) {
    return 'Cáº­p nháº­t $hours giá» trÆ°á»›c';
  }

  @override
  String get validationPasswordRequired => 'Vui lÃ²ng nháº­p máº­t kháº©u';

  @override
  String get validationPasswordMinLength => 'Máº­t kháº©u pháº£i cÃ³ Ã­t nháº¥t 6 kÃ½ tá»±';

  @override
  String get validationPasswordUppercaseRequired =>
      'Máº­t kháº©u pháº£i cÃ³ Ã­t nháº¥t 1 chá»¯ hoa';

  @override
  String get validationPasswordLowercaseRequired =>
      'Máº­t kháº©u pháº£i cÃ³ Ã­t nháº¥t 1 chá»¯ thÆ°á»ng';

  @override
  String get validationPasswordNumberRequired =>
      'Máº­t kháº©u pháº£i cÃ³ Ã­t nháº¥t 1 chá»¯ sá»‘';

  @override
  String get validationPasswordConfirmRequired => 'Vui lÃ²ng nháº­p láº¡i máº­t kháº©u';

  @override
  String get firebaseAuthOperationNotAllowed =>
      'Chá»©c nÄƒng táº¡o tÃ i khoáº£n chÆ°a Ä‘Æ°á»£c báº­t trong Firebase Auth';

  @override
  String get userRepositoryCreateAccountFailed => 'KhÃ´ng thá»ƒ táº¡o tÃ i khoáº£n';

  @override
  String get firestorePermissionDenied => 'Báº¡n khÃ´ng cÃ³ quyá»n ghi dá»¯ liá»‡u';

  @override
  String get firestoreUnavailable => 'Firestore táº¡m thá»i khÃ´ng kháº£ dá»¥ng';

  @override
  String get firestoreGenericError => 'Lá»—i Firestore';

  @override
  String get userRepositoryCreateChildFailed => 'KhÃ´ng thá»ƒ táº¡o tÃ i khoáº£n con';

  @override
  String get mapPlaceSearchMissingAccessToken =>
      'Thiáº¿u ACCESS_TOKEN Mapbox cho tÃ¬m kiáº¿m Ä‘á»‹a Ä‘iá»ƒm.';

  @override
  String mapPlaceSearchRequestFailed(int statusCode) {
    return 'TÃ¬m kiáº¿m Ä‘á»‹a Ä‘iá»ƒm tháº¥t báº¡i ($statusCode).';
  }

  @override
  String get mapPlaceSearchInvalidResponse =>
      'Dá»¯ liá»‡u tráº£ vá» tá»« Mapbox khÃ´ng há»£p lá»‡.';

  @override
  String get mapPlaceSearchTimeout =>
      'TÃ¬m kiáº¿m Ä‘á»‹a Ä‘iá»ƒm quÃ¡ thá»i gian, vui lÃ²ng thá»­ láº¡i.';

  @override
  String get mapPlaceSearchDecodeFailed => 'KhÃ´ng thá»ƒ Ä‘á»c dá»¯ liá»‡u Ä‘á»‹a Ä‘iá»ƒm.';

  @override
  String get mapPlaceSearchUnexpectedError =>
      'CÃ³ lá»—i xáº£y ra khi tÃ¬m kiáº¿m Ä‘á»‹a Ä‘iá»ƒm.';

  @override
  String get mapPlaceSearchNoAddress => 'KhÃ´ng cÃ³ Ä‘á»‹a chá»‰';

  @override
  String get mapPlaceSearchDefaultName => 'Äá»‹a Ä‘iá»ƒm';
}
