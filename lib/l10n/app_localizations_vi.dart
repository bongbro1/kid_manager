// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get personalInfoTitle => 'Thông tin cá nhân';

  @override
  String get appAppearanceTitle => 'Giao diện ứng dụng';

  @override
  String get aboutAppTitle => 'Về ứng dụng';

  @override
  String get addAccountTitle => 'Thêm tài khoản con';

  @override
  String get logoutTitle => 'Đăng xuất';

  @override
  String get fullNameLabel => 'Họ và tên';

  @override
  String get fullNameHint => 'Nhập họ và tên';

  @override
  String get phoneLabel => 'Số điện thoại';

  @override
  String get phoneHint => '+84 012345678';

  @override
  String get genderLabel => 'Giới tính';

  @override
  String get genderHint => 'Nam';

  @override
  String get birthDateLabel => 'Ngày sinh';

  @override
  String get birthDateHint => '12/12/2003';

  @override
  String get addressLabel => 'Địa chỉ';

  @override
  String get addressHint => 'Xã Điềm Thụy, Tỉnh Thái Nguyên';

  @override
  String get locationTrackingLabel => 'Quyền theo dõi';

  @override
  String get allowLocationTrackingText => 'Cho phép đối phương theo dõi vị trí';

  @override
  String get yearsOld => '%d tuổi';

  @override
  String get updateSuccessTitle => 'Thành công';

  @override
  String get updateSuccessMessage => 'Cập nhật thông tin thành công';

  @override
  String get updateErrorTitle => 'Thất bại';

  @override
  String get invalidBirthDate => 'Ngày sinh không hợp lệ';

  @override
  String get confirmLogoutQuestion => 'Bạn muốn đăng xuất?';

  @override
  String get cancelButton => 'Hủy bỏ';

  @override
  String get confirmButton => 'Xác nhận';

  @override
  String get languageSetting => 'Ngôn ngữ';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get english => 'English';

  @override
  String get changeLanguagePrompt =>
      'Thay đổi ngôn ngữ, ứng dụng sẽ khởi động lại';

  @override
  String get appAppearanceThemeLabel => 'Chủ đề';

  @override
  String get appAppearanceSelectThemeTitle => 'Chọn chủ đề';

  @override
  String get appAppearanceThemeSystem => 'Theo hệ thống';

  @override
  String get appAppearanceThemeLight => 'Sáng';

  @override
  String get appAppearanceThemeDark => 'Tối';

  @override
  String get addAccountSuccessMessage => 'Tạo tài khoản con thành công';

  @override
  String get sessionExpiredLoginAgain =>
      'Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.';

  @override
  String get aboutAppName => 'My Application';

  @override
  String aboutAppVersionLabel(String version) {
    return 'Phiên bản: $version';
  }

  @override
  String get aboutAppDescription =>
      'Ứng dụng giúp quản lý tài khoản, theo dõi hoạt động và cá nhân hóa trải nghiệm người dùng.';

  @override
  String get aboutAppCopyright => '© 2026 My Company';

  @override
  String get accountNotFound => 'Tài khoản không tồn tại';

  @override
  String get accountNotActivated => 'Tài khoản chưa được kích hoạt';

  @override
  String get emailNotRegistered => 'Email chưa đăng ký';

  @override
  String get noLocationPermission => 'Không có quyền vị trí';

  @override
  String get gpsError => 'Lỗi GPS';

  @override
  String get currentLocationError => 'Không lấy được vị trí hiện tại';

  @override
  String get invalidCode => 'Mã không đúng';

  @override
  String get codeExpired => 'Mã đã hết hạn';

  @override
  String get tooManyAttempts => 'Nhập sai quá nhiều lần';

  @override
  String get unknownError => 'Có lỗi xảy ra';

  @override
  String get loginFailed => 'Đăng nhập thất bại';

  @override
  String get weakPassword => 'Mật khẩu quá yếu';

  @override
  String get emailInvalid => 'Email không hợp lệ';

  @override
  String get emailInUse => 'Email đã được sử dụng';

  @override
  String get wrongPassword => 'Sai mật khẩu';

  @override
  String get authStartTitle => 'Bắt Đầu Ngay';

  @override
  String get authStartSubtitle => 'Tiếp tục với ứng dụng ngay thôi!';

  @override
  String get authContinueWithGoogle => 'Tiếp tục với Google';

  @override
  String get authContinueWithFacebook => 'Tiếp tục với Facebook';

  @override
  String get authContinueWithApple => 'Tiếp tục với Apple';

  @override
  String get authContinueWithPhone => 'Tiếp tục với số điện thoại';

  @override
  String get authLoginButton => 'Đăng nhập';

  @override
  String get authSignupButton => 'Đăng ký';

  @override
  String get authPrivacyPolicy => 'Chính sách bảo mật';

  @override
  String get authTermsOfService => 'Điều khoản dịch vụ';

  @override
  String get authEnterAllInfo => 'Vui lòng nhập đầy đủ thông tin';

  @override
  String get authInvalidCredentials => 'Thông tin tài khoản không chính xác';

  @override
  String get authUserProfileLoadFailed => 'Không tải được hồ sơ người dùng';

  @override
  String get authGenericError => 'Có lỗi xảy ra';

  @override
  String get authWelcomeBackTitle => 'CHÀO MỪNG TRỞ LẠI';

  @override
  String get authLoginNowSubtitle => 'Đăng nhập ngay!';

  @override
  String get authEnterEmailHint => 'Nhập email';

  @override
  String get authEnterPasswordHint => 'Nhập mật khẩu';

  @override
  String get authRememberPassword => 'Lưu mật khẩu';

  @override
  String get authForgotPassword => 'Quên mật khẩu?';

  @override
  String get authOr => 'Hoặc';

  @override
  String get authNoAccount => 'Bạn chưa có tài khoản, ';

  @override
  String get authSignUpInline => 'đăng ký';

  @override
  String get authSignupTitle => 'ĐĂNG KÝ\nTÀI KHOẢN NGAY';

  @override
  String get authSignupSubtitle => 'Kiểm tra và quản lí con của bạn!';

  @override
  String get authPasswordMismatch => 'Mật khẩu xác nhận không khớp';

  @override
  String get authSignupFailed => 'Đăng ký thất bại';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Mật khẩu';

  @override
  String get authConfirmPasswordLabel => 'Nhập lại mật khẩu';

  @override
  String get authAgreeTermsPrefix => 'Đồng ý với điều khoản, ';

  @override
  String get authAgreeTermsLink => 'tại đây';

  @override
  String get authHaveAccount => 'Bạn đã có tài khoản, ';

  @override
  String get authLoginInline => 'đăng nhập';

  @override
  String get authForgotPasswordTitle => 'QUÊN MẬT KHẨU?';

  @override
  String get authForgotPasswordSubtitle =>
      'Bạn đã quên mật khẩu? Vui lòng làm theo các bước sau để lấy lại mật khẩu của bạn!';

  @override
  String get authEnterYourEmailLabel => 'Nhập Email của bạn';

  @override
  String get authContinueButton => 'Tiếp tục';

  @override
  String get authSendOtpFailed => 'Gửi OTP thất bại';

  @override
  String get otpTitle => 'NHẬP MÃ OTP';

  @override
  String get otpInstruction =>
      'Chúng tôi đã gửi mã xác minh đến địa chỉ email của bạn';

  @override
  String get otpNeed4Digits => 'Vui lòng nhập đủ 4 số OTP';

  @override
  String get otpDigitsOnly => 'OTP chỉ được chứa số';

  @override
  String get otpIncorrect => 'OTP không đúng';

  @override
  String get otpExpired => 'OTP đã hết hạn';

  @override
  String get otpTooManyAttempts =>
      'Bạn đã nhập sai quá 3 lần. Vui lòng chờ 10 phút.';

  @override
  String get otpRequestNotFound => 'Không tìm thấy yêu cầu OTP';

  @override
  String otpResendIn(int seconds) {
    return 'Gửi lại mã sau ${seconds}s';
  }

  @override
  String get otpResend => 'Gửi lại mã';

  @override
  String get otpVerifyButton => 'Xác minh';

  @override
  String get authRegisterSuccessMessage => 'Đăng ký tài khoản thành công';

  @override
  String get resetPasswordTitle => 'ĐẶT LẠI \nMẬT KHẨU MỚI';

  @override
  String get resetPasswordSubtitle => 'Điền mật khẩu mới của bạn!';

  @override
  String get resetPasswordNewLabel => 'Mật khẩu mới';

  @override
  String get resetPasswordConfirmLabel => 'Nhập lại mật khẩu';

  @override
  String get resetPasswordConfirmMismatch => 'Mật khẩu nhập lại không khớp';

  @override
  String get resetPasswordRuleTitle => 'Mật khẩu cần có';

  @override
  String get resetPasswordRuleMinLength => 'Ít nhất 8 ký tự';

  @override
  String get resetPasswordRuleUppercase => 'Có chữ hoa';

  @override
  String get resetPasswordRuleLowercase => 'Có chữ thường';

  @override
  String get resetPasswordRuleNumber => 'Có số';

  @override
  String get resetPasswordCompleteButton => 'Hoàn tất';

  @override
  String get resetPasswordSuccessMessage => 'Đặt lại mật khẩu thành công';

  @override
  String get authCompleteTitle => 'Hoàn tất!';

  @override
  String get authRegisterCongratsMessage =>
      'Chúc mừng! Bạn đã đăng ký thành công';

  @override
  String get authBackToLogin => 'Về trang đăng nhập';

  @override
  String get flashWelcomeTitle => 'Chào mừng đến với ứng dụng';

  @override
  String get flashWelcomeSubtitle => 'Ứng dụng theo dõi con cái';

  @override
  String get flashNext => 'Tiếp';

  @override
  String get scheduleScreenTitle => 'Lịch trình';

  @override
  String get scheduleNoChild => 'Chưa có bé';

  @override
  String get scheduleFormTitleHint => 'Tên lịch trình';

  @override
  String get scheduleFormDescriptionHint => 'Mô tả';

  @override
  String get scheduleAddHeaderTitle => 'Thêm sự kiện';

  @override
  String get scheduleFormDateLabel => 'Ngày';

  @override
  String get scheduleFormStartTimeLabel => 'Giờ bắt đầu';

  @override
  String get scheduleFormEndTimeLabel => 'Giờ kết thúc';

  @override
  String get scheduleFormEndTimeInvalid => 'Giờ kết thúc phải lớn hơn';

  @override
  String get scheduleFormSavingButton => 'Đang lưu...';

  @override
  String get scheduleAddSubmitButton => 'Tạo lịch trình';

  @override
  String get scheduleAddSuccessMessage => 'Bạn đã tạo lịch trình thành công';

  @override
  String get scheduleDialogWarningTitle => 'Cảnh báo';

  @override
  String get scheduleEditHeaderTitle => 'Chỉnh sửa lịch trình';

  @override
  String get scheduleEditSubmitButton => 'Lưu lịch trình';

  @override
  String get scheduleEditSuccessMessage => 'Bạn đã sửa thành công';

  @override
  String get scheduleSelectChildLabel => 'Chọn bé';

  @override
  String get scheduleYourChild => 'Bé của bạn';

  @override
  String get schedulePleaseSelectChild => 'Vui lòng chọn bé';

  @override
  String get scheduleExportTitle => 'Xuất file Excel';

  @override
  String get scheduleExportDateRangeLabel => 'Khoảng thời gian';

  @override
  String get scheduleExportColumnsHint =>
      'File xuất sẽ gồm các cột: title, description, date, start, end';

  @override
  String get scheduleExportLoadingButton => 'Đang xuất...';

  @override
  String get scheduleExportSubmitButton => 'Xuất file';

  @override
  String get scheduleExportInvalidDateRange =>
      'Ngày bắt đầu không được lớn hơn ngày kết thúc';

  @override
  String get scheduleExportNoDataInRange =>
      'Không có lịch trong khoảng ngày đã chọn';

  @override
  String get scheduleExportSaveCanceled => 'Bạn đã huỷ lưu file';

  @override
  String scheduleExportSuccessMessage(int count) {
    return 'Xuất file Excel thành công ($count lịch)';
  }

  @override
  String scheduleExportFailed(String error) {
    return 'Xuất file thất bại: $error';
  }

  @override
  String get scheduleImportTitle => 'Thêm file Excel';

  @override
  String get scheduleTemplateDownloadButton => 'Tải file mẫu';

  @override
  String get scheduleTemplateSaveCanceled => 'Bạn đã huỷ lưu file mẫu';

  @override
  String get scheduleTemplateSavedSuccess => 'Đã lưu file mẫu thành công';

  @override
  String scheduleTemplateDownloadFailed(String error) {
    return 'Tải file mẫu thất bại: $error';
  }

  @override
  String get scheduleImportCannotReadFile => 'Không đọc được file, thử lại.';

  @override
  String get scheduleImportMissingOwner =>
      'Không xác định được chủ sở hữu lịch';

  @override
  String get scheduleImportNoValidItems => 'Không có lịch hợp lệ để import.';

  @override
  String get scheduleImportSuccessMessage => 'Thêm lịch thành công';

  @override
  String scheduleImportFailed(String error) {
    return 'Import thất bại: $error';
  }

  @override
  String scheduleImportAddCount(int count) {
    return 'Thêm $count lịch';
  }

  @override
  String get scheduleImportPickFileButton => 'Chọn file Excel';

  @override
  String get scheduleImportPickAnotherFileButton => 'Chọn file khác';

  @override
  String scheduleImportSelectedFile(String fileName) {
    return 'Đã chọn: $fileName';
  }

  @override
  String get scheduleImportChangeFileButton => 'Đổi file';

  @override
  String scheduleImportSummaryOk(int count) {
    return 'OK: $count';
  }

  @override
  String scheduleImportSummaryDuplicate(int count) {
    return 'Trùng: $count';
  }

  @override
  String scheduleImportSummaryError(int count) {
    return 'Lỗi: $count';
  }

  @override
  String get scheduleImportPreviewTitle => 'Xem trước dữ liệu';

  @override
  String get scheduleImportStatusOk => 'OK';

  @override
  String get scheduleImportStatusError => 'LỖI';

  @override
  String get scheduleImportStatusDuplicate => 'TRÙNG';

  @override
  String scheduleImportRowError(int row, String error) {
    return 'Dòng $row: $error';
  }

  @override
  String get birthdayMemberFallback => 'Thành viên';

  @override
  String birthdayWishSelfWithAge(int age) {
    return 'Chúc mừng sinh nhật tôi. Chào tuổi $age thật rực rỡ, bình an và nhiều niềm vui.';
  }

  @override
  String get birthdayWishSelfDefault =>
      'Chúc mừng sinh nhật tôi. Chúc mình có một ngày thật vui và đáng nhớ.';

  @override
  String birthdayWishOtherWithAge(String name, int age) {
    return 'Chúc mừng sinh nhật $name. Chúc bạn bước sang tuổi $age luôn mạnh khỏe, vui vẻ và gặp nhiều điều may mắn.';
  }

  @override
  String birthdayWishOtherDefault(String name) {
    return 'Chúc mừng sinh nhật $name. Chúc bạn luôn vui vẻ, mạnh khỏe và có thật nhiều niềm vui.';
  }

  @override
  String get birthdayViewWishButton => 'Xem lời chúc';

  @override
  String get birthdaySendWishButton => 'Gửi lời chúc';

  @override
  String get birthdayCongratsYouTitle => 'Chúc mừng sinh nhật bạn';

  @override
  String get birthdayCongratsTitle => 'Chúc mừng sinh nhật';

  @override
  String get birthdayTodayIsYourDay => 'Hôm nay là ngày của bạn';

  @override
  String birthdayTurnsAge(int age) {
    return 'Tròn $age tuổi';
  }

  @override
  String get birthdaySuggestionTitle => 'Lời chúc gợi ý';

  @override
  String birthdayYouEnteringAge(int age) {
    return 'Hôm nay bạn bước sang tuổi $age. Chúc bạn có một ngày thật tươi vui, nhẹ nhàng và đáng nhớ.';
  }

  @override
  String get birthdayYouSpecialDay =>
      'Hôm nay là ngày đặc biệt của bạn. Chúc bạn có thật nhiều niềm vui và năng lượng tích cực.';

  @override
  String birthdayTodayIsBirthdayWithAge(String name, int age) {
    return 'Hôm nay là sinh nhật của $name, tròn $age tuổi.';
  }

  @override
  String birthdayTodayIsBirthday(String name) {
    return 'Hôm nay là sinh nhật của $name.';
  }

  @override
  String get birthdayCountdownTitle => '✨ Sắp tới sinh nhật';

  @override
  String get birthdayCountdownSelfTitle => '✨ Sắp tới sinh nhật của bạn';

  @override
  String get birthdayCountdownTomorrowChip => 'Ngày mai';

  @override
  String birthdayCountdownDaysChip(int days) {
    return 'Còn $days ngày';
  }

  @override
  String birthdayCountdownOtherBody(String name, int days) {
    return 'Chỉ còn $days ngày nữa là đến sinh nhật của $name.';
  }

  @override
  String birthdayCountdownOtherBodyTomorrow(String name) {
    return 'Ngày mai là sinh nhật của $name.';
  }

  @override
  String birthdayCountdownSelfBody(int days) {
    return 'Chỉ còn $days ngày nữa là đến sinh nhật của bạn.';
  }

  @override
  String get birthdayCountdownSelfBodyTomorrow =>
      'Ngày mai là sinh nhật của bạn.';

  @override
  String get birthdayCountdownSuggestionTitle => 'Gợi ý chuẩn bị';

  @override
  String birthdayCountdownSuggestionOther(String name) {
    return 'Bạn có thể chuẩn bị lời chúc, quà tặng hoặc một điều bất ngờ cho $name ngay từ bây giờ.';
  }

  @override
  String get birthdayCountdownSuggestionSelf =>
      'Bạn có thể chuẩn bị lời chúc, món quà nhỏ hoặc một điều bất ngờ cho chính mình ngay từ bây giờ.';

  @override
  String get birthdayCountdownPlanButton => 'Chuẩn bị lời chúc';

  @override
  String birthdayCopiedFallback(String name) {
    return 'Không tìm thấy chat gia đình. Đã sao chép lời chúc cho $name.';
  }

  @override
  String get birthdayCloseButton => 'Đóng';

  @override
  String get birthdayAwesomeButton => 'Tuyệt vời';

  @override
  String get familyChatLoadingTitle => 'Đang tải cuộc trò chuyện';

  @override
  String get familyChatTitle => 'Trò chuyện gia đình';

  @override
  String get familyChatTitleLarge => 'Trò chuyện gia đình';

  @override
  String familyChatSendFailed(String error) {
    return 'Gửi tin nhắn thất bại: $error';
  }

  @override
  String get familyChatYou => 'Bạn';

  @override
  String get familyChatMemberFallback => 'Thành viên';

  @override
  String get familyChatLoadingMembers => 'Đang tải thành viên...';

  @override
  String get familyChatNoMembersFound => 'Không tìm thấy thành viên';

  @override
  String get familyChatOneMember => '1 thành viên';

  @override
  String familyChatManyMembers(int count) {
    return '$count thành viên';
  }

  @override
  String get familyChatCannotLoadMessages => 'Không thể tải tin nhắn';

  @override
  String get familyChatNoMessagesYet =>
      'Chưa có tin nhắn nào. Hãy bắt đầu cuộc trò chuyện.';

  @override
  String get familyChatStatusFailed => 'thất bại';

  @override
  String get familyChatStatusSending => 'đang gửi...';

  @override
  String get familyChatTypeMessageHint => 'Nhập tin nhắn...';

  @override
  String familyChatMemberCountOverflow(String names, int extra) {
    return '$names +$extra';
  }

  @override
  String get notificationScreenTitle => 'Thông báo';

  @override
  String get notificationDateToday => 'HÔM NAY';

  @override
  String get notificationDateYesterday => 'HÔM QUA';

  @override
  String get notificationFilterTitle => 'Lọc thông báo';

  @override
  String get notificationFilterAll => 'Tất cả';

  @override
  String get notificationFilterActivity => 'Hoạt động';

  @override
  String get notificationFilterAlert => 'Cảnh báo';

  @override
  String get notificationFilterReminder => 'Nhắc nhở';

  @override
  String get notificationFilterSystem => 'Thông báo hệ thống';

  @override
  String get notificationSearchHint => 'Tìm thông báo';

  @override
  String get notificationJustNow => 'Vừa xong';

  @override
  String notificationMinutesAgo(int minutes) {
    return '${minutes}p trước';
  }

  @override
  String notificationHoursAgo(int hours) {
    return '${hours}h trước';
  }

  @override
  String get notificationDetailTitle => 'Chi tiết thông báo';

  @override
  String get notificationDetailSectionTitle => 'CHI TIẾT';

  @override
  String get notificationChildFallback => 'Bé';

  @override
  String get notificationChildInfoNotFound => 'Không tìm thấy thông tin của bé';

  @override
  String get notificationMapLocationNotFound =>
      'Không tìm thấy vị trí để mở bản đồ';

  @override
  String notificationScheduleCreatedTitle(String childName) {
    return 'Lịch trình mới của $childName';
  }

  @override
  String notificationScheduleUpdatedTitle(String childName) {
    return 'Lịch trình của $childName đã thay đổi';
  }

  @override
  String notificationScheduleDeletedTitle(String childName) {
    return 'Lịch trình của $childName đã bị xóa';
  }

  @override
  String notificationScheduleRestoredTitle(String childName) {
    return 'Lịch trình của $childName đã được khôi phục';
  }

  @override
  String notificationZoneEnteredDangerTitle(String childName) {
    return '$childName đã vào vùng nguy hiểm';
  }

  @override
  String notificationZoneExitedSafeTitle(String childName) {
    return '$childName đã rời vùng an toàn';
  }

  @override
  String notificationZoneExitedDangerTitle(String childName) {
    return '$childName đã rời vùng nguy hiểm';
  }

  @override
  String scheduleImportRowTitle(int row, String title) {
    return 'Dòng $row: $title';
  }

  @override
  String get scheduleImportDuplicateInSystem =>
      'Trùng với dữ liệu đã có trên hệ thống';

  @override
  String get scheduleImportDuplicateInFile => 'Trùng trong file';

  @override
  String get scheduleHistoryTitle => 'Lịch sử chỉnh sửa';

  @override
  String get scheduleHistoryEmpty => 'Chưa có lịch sử chỉnh sửa';

  @override
  String get scheduleHistoryToday => 'Hôm nay';

  @override
  String get scheduleHistoryYesterday => 'Hôm qua';

  @override
  String get scheduleHistoryRestoreDialogTitle => 'Khôi phục lịch trình';

  @override
  String get scheduleHistoryRestoreDialogMessage =>
      'Bạn có chắc muốn khôi phục phiên bản này không?';

  @override
  String get scheduleHistoryRestoreButton => 'Khôi phục';

  @override
  String get scheduleHistoryRestoringButton => 'Đang khôi phục...';

  @override
  String get scheduleHistoryRestoreSuccessMessage =>
      'Bạn đã khôi phục thành công';

  @override
  String scheduleHistoryRestoreFailed(String error) {
    return 'Khôi phục thất bại: $error';
  }

  @override
  String scheduleHistoryEditedAt(String time) {
    return 'Đã sửa lúc $time';
  }

  @override
  String get scheduleHistoryLabelTitle => 'Tên lịch trình:';

  @override
  String get scheduleHistoryLabelDescription => 'Mô tả:';

  @override
  String get scheduleHistoryLabelDate => 'Ngày:';

  @override
  String get scheduleHistoryLabelTime => 'Thời gian:';

  @override
  String get scheduleDrawerMenuTitle => 'Menu';

  @override
  String get scheduleCreateButtonAddEvent => '+ Thêm sự kiện';

  @override
  String get schedulePeriodTitle => 'Thời gian';

  @override
  String get schedulePeriodMorning => 'Sáng';

  @override
  String get schedulePeriodAfternoon => 'Chiều';

  @override
  String get schedulePeriodEvening => 'Tối';

  @override
  String get scheduleCalendarFormatMonth => 'Tháng';

  @override
  String get scheduleCalendarFormatWeek => 'Tuần';

  @override
  String scheduleCalendarMonthLabel(int month) {
    return 'Tháng $month';
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
  String get scheduleNoEventsInDay => 'Không có lịch trong ngày';

  @override
  String get scheduleDeleteTitle => 'Xóa lịch trình';

  @override
  String get scheduleDeleteConfirmMessage => 'Bạn có chắc muốn xóa?';

  @override
  String get scheduleDeleteSuccessMessage => 'Bạn đã xóa thành công';

  @override
  String scheduleDeleteFailed(String error) {
    return 'Xóa thất bại: $error';
  }

  @override
  String get memoryDayTitle => 'Ngày đáng nhớ';

  @override
  String get memoryDayEmpty => 'Chưa có ngày đáng nhớ';

  @override
  String get memoryDayDeleteTitle => 'Xóa ngày đáng nhớ';

  @override
  String get memoryDayDeleteConfirmMessage => 'Bạn có chắc muốn xóa?';

  @override
  String get memoryDayDeleteSuccessMessage => 'Bạn đã xóa thành công';

  @override
  String get memoryDayDeleteFailedMessage => 'Xóa thất bại, vui lòng thử lại';

  @override
  String memoryDayDeleteFailedWithError(String error) {
    return 'Xóa thất bại: $error';
  }

  @override
  String memoryDayDaysPassed(int days) {
    return 'Đã qua $days ngày';
  }

  @override
  String get memoryDayToday => 'Hôm nay';

  @override
  String memoryDayDaysLeft(int days) {
    return 'Còn $days ngày';
  }

  @override
  String memoryDayDateText(String date) {
    return 'Ngày: $date';
  }

  @override
  String memoryDayDateRepeatText(String date) {
    return 'Ngày: $date (lặp lại hằng năm)';
  }

  @override
  String get memoryDayUnsavedTitle => 'Chưa lưu';

  @override
  String get memoryDayUnsavedExitMessage =>
      'Bạn chưa lưu, bạn có chắc muốn thoát?';

  @override
  String get memoryDayFormTitleLabel => 'Tiêu đề';

  @override
  String get memoryDayFormDateLabel => 'Ngày';

  @override
  String get memoryDayFormNoteLabel => 'Ghi chú';

  @override
  String get memoryDayReminderLabel => 'Nhắc nhở trước';

  @override
  String get memoryDayReminderNone => 'Không nhắc';

  @override
  String get memoryDayReminderOneDay => 'Trước 1 ngày';

  @override
  String get memoryDayReminderThreeDays => 'Trước 3 ngày';

  @override
  String get memoryDayReminderSevenDays => 'Trước 7 ngày';

  @override
  String get memoryDayRepeatYearlyLabel => 'Lặp lại hàng năm';

  @override
  String get memoryDayEditHeaderTitle => 'Chỉnh sửa ngày đáng nhớ';

  @override
  String get memoryDayAddHeaderTitle => 'Thêm ngày đáng nhớ';

  @override
  String get memoryDayEditSuccessMessage => 'Bạn đã lưu thay đổi thành công';

  @override
  String get memoryDayAddSuccessMessage =>
      'Bạn đã thêm ngày đáng nhớ thành công';

  @override
  String get memoryDaySaveFailedMessage => 'Đã có lỗi xảy ra, vui lòng thử lại';

  @override
  String get memoryDaySavingButton => 'Đang lưu...';

  @override
  String get memoryDaySaveChangesButton => 'Lưu thay đổi';

  @override
  String get memoryDayAddButton => 'Thêm ngày đáng nhớ';

  @override
  String get memoryDayEditAction => 'Sửa';

  @override
  String get memoryDayDeleteAction => 'Xóa';

  @override
  String get notificationsEmptyTitle => 'Chưa có thông báo';

  @override
  String get notificationsEmptySubtitle =>
      'Các thông báo mới sẽ xuất hiện tại đây';

  @override
  String get notificationsDefaultChildName => 'Bé';

  @override
  String get notificationsNoTitle => 'Không có tiêu đề';

  @override
  String get notificationsActionCreated => 'Đã thêm';

  @override
  String get notificationsActionUpdated => 'Đã chỉnh sửa';

  @override
  String get notificationsActionDeleted => 'Đã xóa';

  @override
  String get notificationsActionRestored => 'Đã khôi phục';

  @override
  String get notificationsActionChanged => 'Đã thay đổi';

  @override
  String get notificationsScheduleTitleLabel => 'Tên lịch';

  @override
  String get notificationsChildNameLabel => 'Tên bé';

  @override
  String get notificationsDateLabel => 'Ngày';

  @override
  String get notificationsTimeLabel => 'Thời gian';

  @override
  String get notificationsViewScheduleButton => 'Xem lịch';

  @override
  String get notificationsRepeatLabel => 'Lặp lại';

  @override
  String get notificationsRepeatYearly => 'Hằng năm';

  @override
  String get notificationsRepeatNone => 'Không lặp lại';

  @override
  String get notificationsImportOperatorLabel => 'Người thao tác';

  @override
  String get notificationsChildLabel => 'Bé';

  @override
  String get notificationsImportAddedCountLabel => 'Số lịch đã thêm';

  @override
  String get notificationsActorParent => 'Ba/Mẹ';

  @override
  String get notificationsActorChild => 'Con';

  @override
  String get notificationsBlockedAccountLabel => 'Tài khoản';

  @override
  String get notificationsBlockedAppLabel => 'Ứng dụng';

  @override
  String get notificationsBlockedTimeLabel => 'Thời điểm';

  @override
  String get notificationsBlockedAllowedWindowLabel => 'Khung giờ cho phép';

  @override
  String get notificationsBlockedWarningMessage =>
      'Ứng dụng đã bị chặn tự động bởi hệ thống.';

  @override
  String get notificationsBlockedViewConfigButton => 'Xem cấu hình thời gian';

  @override
  String get notificationsRemovedDeviceOfLabel => 'Thiết bị của';

  @override
  String get notificationsRemovedAppLabel => 'Ứng dụng đã gỡ';

  @override
  String get notificationsRemovedAtLabel => 'Thời điểm gỡ';

  @override
  String get notificationsRemovedWarningMessage =>
      'Ứng dụng đã bị gỡ khỏi thiết bị. Hãy kiểm tra nếu đây là ứng dụng bị quản lý.';

  @override
  String get notificationsRemovedViewAppsButton => 'Xem danh sách ứng dụng';

  @override
  String notificationsZoneDangerEnterDescription(
    String childName,
    String zoneName,
    String time,
  ) {
    return 'Vị trí của $childName đã được ghi nhận tại $zoneName. Hệ thống ghi nhận bé đã vào vùng nguy hiểm lúc $time.';
  }

  @override
  String notificationsZoneSafeExitDescription(
    String childName,
    String zoneName,
    String time,
  ) {
    return 'Vị trí của $childName đã được ghi nhận tại $zoneName. Hệ thống ghi nhận bé đã rời vùng an toàn lúc $time.';
  }

  @override
  String notificationsZoneDangerExitDescription(
    String childName,
    String zoneName,
    String time,
  ) {
    return 'Vị trí của $childName đã được ghi nhận tại $zoneName. Hệ thống ghi nhận bé đã rời vùng nguy hiểm lúc $time.';
  }

  @override
  String notificationsZoneUpdatedDescription(
    String childName,
    String zoneName,
  ) {
    return 'Vị trí của $childName đã được cập nhật tại $zoneName.';
  }

  @override
  String get notificationsZoneViewOnMainMapButton => 'Xem trên bản đồ chính';

  @override
  String get notificationsContactNowButton => 'Liên hệ ngay';

  @override
  String scheduleOverlapConflictMessage(
    String title,
    String start,
    String end,
  ) {
    return 'Trùng với lịch \"$title\" ($start - $end). Vui lòng chọn giờ khác.';
  }

  @override
  String get scheduleExportErrorCreateExcelFile => 'Không tạo được file Excel';

  @override
  String get scheduleImportTemplateSampleTitle1 => 'Học Toán';

  @override
  String get scheduleImportTemplateSampleDescription1 => 'Làm bài 1-5';

  @override
  String get scheduleImportTemplateSampleTitle2 => 'Đá bóng';

  @override
  String get scheduleImportErrorCreateExcelBytes =>
      'Không tạo được dữ liệu Excel';

  @override
  String get scheduleImportErrorMissingTitle => 'Thiếu title';

  @override
  String get scheduleImportErrorEndAfterStart =>
      'Giờ kết thúc phải lớn hơn giờ bắt đầu';

  @override
  String scheduleImportWarningDbCheckFailed(String error) {
    return 'Không kiểm tra trùng DB do lỗi mạng: $error';
  }

  @override
  String get scheduleImportErrorMissingDate => 'Thiếu date';

  @override
  String scheduleImportErrorInvalidDate(String raw) {
    return 'Sai date: \"$raw\"';
  }

  @override
  String scheduleImportErrorInvalidDateSupported(String raw) {
    return 'Sai date: \"$raw\" (hỗ trợ: yyyy-MM-dd, dd/MM/yyyy, MM/dd/yyyy, ISO datetime)';
  }

  @override
  String get scheduleImportErrorMissingTime => 'Thiếu time';

  @override
  String scheduleImportErrorInvalidTimeSupported(String raw) {
    return 'Sai time: \"$raw\" (hỗ trợ: HH:mm, HH:mm:ss, 7:00 AM/PM)';
  }

  @override
  String get scheduleNotifyTitleCreated => 'Lịch trình mới';

  @override
  String get scheduleNotifyTitleUpdated => 'Lịch trình đã thay đổi';

  @override
  String get scheduleNotifyTitleDeleted => 'Lịch trình đã bị xóa';

  @override
  String get scheduleNotifyTitleRestored => 'Lịch trình đã được khôi phục';

  @override
  String get scheduleNotifyTitleChanged => 'Lịch trình có thay đổi';

  @override
  String scheduleNotifyBodyParentCreated(
    String title,
    String childName,
    String date,
    String time,
  ) {
    return 'Cha đã thêm lịch \"$title\" cho $childName vào $date, $time.';
  }

  @override
  String scheduleNotifyBodyParentUpdated(String title, String childName) {
    return 'Cha đã chỉnh sửa lịch \"$title\" của $childName.';
  }

  @override
  String scheduleNotifyBodyParentDeleted(String title, String childName) {
    return 'Cha đã xóa lịch \"$title\" của $childName.';
  }

  @override
  String scheduleNotifyBodyParentRestored(String title, String childName) {
    return 'Cha đã khôi phục một phiên bản cũ của lịch \"$title\" của $childName.';
  }

  @override
  String scheduleNotifyBodyParentChanged(String title, String childName) {
    return 'Cha đã thay đổi lịch \"$title\" của $childName.';
  }

  @override
  String scheduleNotifyBodyChildCreated(
    String childName,
    String title,
    String date,
    String time,
  ) {
    return '$childName đã thêm lịch \"$title\" vào $date, $time.';
  }

  @override
  String scheduleNotifyBodyChildUpdated(String childName, String title) {
    return '$childName đã chỉnh sửa lịch \"$title\".';
  }

  @override
  String scheduleNotifyBodyChildDeleted(String childName, String title) {
    return '$childName đã xóa lịch \"$title\".';
  }

  @override
  String scheduleNotifyBodyChildRestored(String childName, String title) {
    return '$childName đã khôi phục lịch sử sửa của lịch \"$title\".';
  }

  @override
  String scheduleNotifyBodyChildChanged(String childName, String title) {
    return '$childName đã thay đổi lịch \"$title\".';
  }

  @override
  String get memoryDayNotifyTitleCreated => 'Ngày đáng nhớ mới';

  @override
  String get memoryDayNotifyTitleUpdated => 'Ngày đáng nhớ đã thay đổi';

  @override
  String get memoryDayNotifyTitleDeleted => 'Ngày đáng nhớ đã bị xóa';

  @override
  String get memoryDayNotifyTitleChanged => 'Ngày đáng nhớ có thay đổi';

  @override
  String memoryDayNotifyBodyParentCreated(String title) {
    return 'Cha đã thêm ngày đáng nhớ \"$title\".';
  }

  @override
  String memoryDayNotifyBodyParentUpdated(String title) {
    return 'Cha đã chỉnh sửa ngày đáng nhớ \"$title\".';
  }

  @override
  String memoryDayNotifyBodyParentDeleted(String title) {
    return 'Cha đã xóa ngày đáng nhớ \"$title\".';
  }

  @override
  String memoryDayNotifyBodyParentChanged(String title) {
    return 'Cha đã thay đổi ngày đáng nhớ \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildCreated(String actorChildName, String title) {
    return '$actorChildName đã thêm ngày đáng nhớ \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildUpdated(String actorChildName, String title) {
    return '$actorChildName đã chỉnh sửa ngày đáng nhớ \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildDeleted(String actorChildName, String title) {
    return '$actorChildName đã xóa ngày đáng nhớ \"$title\".';
  }

  @override
  String memoryDayNotifyBodyChildChanged(String actorChildName, String title) {
    return '$actorChildName đã thay đổi ngày đáng nhớ \"$title\".';
  }

  @override
  String get scheduleImportNotifyTitle => 'Lịch trình mới được thêm';

  @override
  String scheduleImportNotifyBodyParent(int importCount, String childName) {
    return 'Cha vừa thêm $importCount lịch cho $childName.';
  }

  @override
  String scheduleImportNotifyBodyChild(String actorChildName, int importCount) {
    return '$actorChildName vừa thêm $importCount lịch.';
  }

  @override
  String get parentDashboardTitle => 'Bảng điều khiển';

  @override
  String get parentDashboardTabApps => 'Ứng dụng';

  @override
  String get parentDashboardTabStatistics => 'Thống kê';

  @override
  String get parentDashboardNoDeviceTitle =>
      'Chưa có thiết bị nào được liên kết';

  @override
  String get parentDashboardNoDeviceSubtitle =>
      'Để theo dõi thời gian sử dụng ứng dụng, bạn cần thêm thiết bị của con vào hệ thống.';

  @override
  String get parentDashboardAddDeviceButton => 'Thêm thiết bị';

  @override
  String get parentDashboardHowItWorksButton => 'Tìm hiểu cách hoạt động';

  @override
  String get parentStatsTotalToday => 'TỔNG THỜI GIAN HÔM NAY';

  @override
  String get parentStatsTotalThisWeek => 'TỔNG THỜI GIAN TUẦN NÀY';

  @override
  String get parentStatsSelectRange => 'CHỌN KHOẢNG NGÀY';

  @override
  String get parentStatsSelectEndDate => 'CHỌN NGÀY KẾT THÚC';

  @override
  String parentStatsTotalFromRange(String startDate, String endDate) {
    return 'TỔNG THỜI GIAN TỪ $startDate - $endDate';
  }

  @override
  String get parentStatsSegmentDay => 'Ngày';

  @override
  String get parentStatsSegmentWeek => 'Tuần';

  @override
  String get parentStatsSegmentRange => 'Thêm';

  @override
  String get parentStatsAppDetailsTitle => 'Chi tiết ứng dụng';

  @override
  String get parentStatsCollapse => 'THU GỌN';

  @override
  String get parentStatsViewAll => 'XEM TẤT CẢ';

  @override
  String get parentUsageNoAvailableSlot => 'Không còn khoảng thời gian trống';

  @override
  String get parentUsageStartBeforeEnd =>
      'Giờ bắt đầu phải nhỏ hơn giờ kết thúc';

  @override
  String get parentUsageOverlapTimeRange =>
      'Khoảng thời gian bị trùng với mốc khác';

  @override
  String get parentUsageEndAfterStart =>
      'Giờ kết thúc phải lớn hơn giờ bắt đầu';

  @override
  String get parentUsageEditTitle => 'Cài đặt thời gian sử dụng';

  @override
  String get parentUsageEnableUsage => 'Cho phép sử dụng';

  @override
  String get parentUsageSelectAllowedDays => 'Chọn ngày được phép';

  @override
  String get saveButton => 'Lưu';

  @override
  String get parentUsageDayRuleModalHint => 'Chọn quy tắc cho ngày này';

  @override
  String get parentUsageRuleFollowScheduleTitle => 'Theo lịch đã đặt';

  @override
  String get parentUsageRuleFollowScheduleSubtitle =>
      'Áp dụng khung giờ hàng tuần';

  @override
  String get parentUsageRuleAllowAllDayTitle => 'Cho phép cả ngày';

  @override
  String get parentUsageRuleAllowAllDaySubtitle =>
      'Có thể sử dụng bất cứ lúc nào';

  @override
  String get parentUsageRuleBlockAllDayTitle => 'Chặn cả ngày';

  @override
  String get parentUsageRuleBlockAllDaySubtitle => 'Không được sử dụng hôm nay';

  @override
  String get zonesDeleteConfirmTitle => 'Xác nhận xoá';

  @override
  String get zonesDeleteConfirmMessage =>
      'Bạn có chắc muốn xoá địa điểm này không?';

  @override
  String get zonesDeleteButton => 'Xoá';

  @override
  String get zonesCreateSuccessTitle => 'Tạo thành công';

  @override
  String zonesCreateSuccessMessage(String name) {
    return 'Địa điểm \"$name\" đã được tạo';
  }

  @override
  String get zonesFailedTitle => 'Thất bại';

  @override
  String get zonesCreateFailedMessage =>
      'Không thể tạo địa điểm, vui lòng thử lại';

  @override
  String get zonesEditSuccessTitle => 'Chỉnh sửa thành công';

  @override
  String get zonesEditSuccessMessage => 'Địa điểm đã được cập nhật';

  @override
  String get zonesEditFailedMessage =>
      'Không thể cập nhật địa điểm, vui lòng thử lại';

  @override
  String get zonesDeleteSuccessTitle => 'Xoá thành công';

  @override
  String get zonesDeleteSuccessMessage => 'Địa điểm đã được xoá';

  @override
  String get zonesDeleteFailedMessage =>
      'Không thể xoá địa điểm, vui lòng thử lại';

  @override
  String get zonesEmptyTitle => 'Chưa có vùng nào';

  @override
  String get zonesEmptySubtitle =>
      'Thêm vùng để bắt đầu theo dõi vị trí của bé';

  @override
  String get zonesTypeSafe => 'An toàn';

  @override
  String get zonesTypeDanger => 'Nguy hiểm';

  @override
  String get zonesEditMenu => 'Sửa';

  @override
  String get zonesDeleteMenu => 'Xoá';

  @override
  String get zonesScreenTitle => 'Vùng của bé';

  @override
  String get zonesAddButton => 'Thêm vùng';

  @override
  String zonesErrorWithMessage(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get zonesNewZoneDefaultName => 'Vùng mới';

  @override
  String get zonesEditTitle => 'Chỉnh sửa vùng';

  @override
  String get zonesAddAddressTitle => 'Địa chỉ của địa điểm';

  @override
  String get zonesOverlapWarningText => 'Các địa điểm không nên chồng chéo';

  @override
  String get zonesNameFieldLabel => 'Tên vùng';

  @override
  String get zonesTypeFieldLabel => 'Loại vùng';

  @override
  String get zonesRadiusLabel => 'Bán kính';

  @override
  String zonesOverlappingWith(String name) {
    return 'Đang chồng lên: $name';
  }

  @override
  String get zonesDefaultNameFallback => 'Vùng';

  @override
  String get parentLocationUnknownUser => 'Không rõ';

  @override
  String get parentLocationSosSent => 'Đã gửi SOS';

  @override
  String get parentLocationSosFailed => 'Gửi SOS thất bại';

  @override
  String get parentLocationMapLoadingTitle => 'Đang tải bản đồ';

  @override
  String get parentLocationMapLoadingSubtitle =>
      'Đang chuẩn bị vị trí của các bé';

  @override
  String get parentChildrenListTitle => 'Danh sách thành viên';

  @override
  String get childLocationTransportWalking => 'Đi bộ';

  @override
  String get childLocationTransportBicycle => 'Xe đạp';

  @override
  String get childLocationTransportVehicle => 'Đi xe';

  @override
  String get childLocationTransportStill => 'Đứng yên';

  @override
  String get childLocationTransportUnknown => 'Không rõ';

  @override
  String get childLocationDetailTitle => 'Chi tiết vị trí';

  @override
  String childLocationStatusTitle(String transport) {
    return 'Trạng thái: $transport';
  }

  @override
  String childLocationHistoryTitle(String date) {
    return 'Lịch sử • $date';
  }

  @override
  String get childLocationTooltipHideDots => 'Ẩn điểm';

  @override
  String get childLocationTooltipShowDots => 'Hiện điểm';

  @override
  String get childLocationHistoryButton => 'Lịch sử';

  @override
  String get childLocationZonesButton => 'Vùng';

  @override
  String get zone_default => 'Thông báo hehehe';

  @override
  String get zone_enter_danger_parent => '⚠️ Bé vào vùng nguy hiểm';

  @override
  String get zone_exit_danger_parent => '✅ Bé rời vùng nguy hiểm';

  @override
  String get zone_enter_safe_parent => '✅ Bé vào vùng an toàn';

  @override
  String get zone_exit_safe_parent => 'ℹ️ Bé rời vùng an toàn';

  @override
  String get zone_enter_danger_child => '⚠️ Bạn đang vào vùng nguy hiểm';

  @override
  String get zone_exit_danger_child => '✅ Bạn đã ra khỏi vùng nguy hiểm';

  @override
  String get zone_enter_safe_child => '✅ Bạn đang vào vùng an toàn';

  @override
  String get zone_exit_safe_child => 'ℹ️ Bạn đã ra khỏi vùng an toàn';

  @override
  String get tracking_location_service_off_parent_title => 'Con đã tắt định vị';

  @override
  String get tracking_location_permission_denied_parent_title =>
      'Con đã tắt quyền vị trí';

  @override
  String get tracking_background_disabled_parent_title =>
      'Định vị nền đã bị tắt';

  @override
  String get tracking_location_stale_parent_title =>
      'Không nhận được vị trí mới';

  @override
  String get tracking_ok_parent_title => 'Định vị đã hoạt động lại';

  @override
  String get tracking_location_service_off_child_title => 'Định vị đang tắt';

  @override
  String get tracking_location_permission_denied_child_title =>
      'Quyền vị trí đang tắt';

  @override
  String get tracking_background_disabled_child_title => 'Định vị nền đang tắt';

  @override
  String get tracking_location_stale_child_title => 'Vị trí chưa được cập nhật';

  @override
  String get tracking_ok_child_title => 'Định vị đã hoạt động lại';

  @override
  String get tracking_default_title => 'Thông báo định vị';
}
