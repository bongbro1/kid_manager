# Kế hoạch sửa Responsive cho Kid Manager

## 1. Mục tiêu
- Loại bỏ tình trạng tràn giao diện (`RenderFlex overflow`, text bị cắt, nút bị lệch) trên các màn hình ưu tiên.
- Đảm bảo UI ổn định trên nhiều kích thước máy, không phụ thuộc vào một mẫu máy ảo.
- Giữ trải nghiệm dễ đọc khi người dùng tăng `Font size` hoặc `Display size` trên máy thật.
- Hoàn thành mà không làm thay đổi luồng chức năng hiện có.

## 2. Phạm vi ưu tiên
- Ưu tiên P0: Auth flow, Personal Info, các dialog/sheet, App Appearance, About App.
- Ưu tiên P1: Dashboard và các màn hình có nguy cơ tràn trung bình.
- Ưu tiên P2: Toàn bộ màn còn lại và chuẩn hóa style system.

## 3. Nguyên nhân cần xử lý
- Đang dùng nhiều kích thước cứng (`width/height/font`) tại các màn hình chính.
- Nhiều layout ngang (`Row`) chưa có cơ chế co giãn tốt khi text dài hoặc text scale lớn.
- Có màn hình không cuộn dọc dù nội dung dài trên thiết bị nhỏ.
- Font family đang dùng chưa đồng nhất với danh sách font đã khai báo.
- Chưa có chính sách responsive thống nhất toàn app.

## 4. Danh sách file hotspot cần sửa
- `lib/views/auth/start_screen.dart`
- `lib/views/auth/login_screen.dart`
- `lib/views/auth/signup_screen.dart`
- `lib/widgets/common/social_login_button.dart`
- `lib/widgets/auth/auth_text_field.dart`
- `lib/views/personal_info_screen.dart`
- `lib/widgets/app/app_input_component.dart`
- `lib/widgets/app/app_overlay_sheet.dart`
- `lib/widgets/common/notification_modal.dart`
- `lib/widgets/app/app_notification_dialog.dart`
- `lib/views/setting_pages/app_appearance_screen.dart`
- `lib/views/setting_pages/about_app_screen.dart`
- `lib/views/parent/schedule/schedule_history_screen.dart`
- `pubspec.yaml` (rà soát và chuẩn hóa font family)
- `lib/app.dart` (bổ sung chính sách responsive ở cấp app)

## 5. Nguyên tắc sửa
- Ưu tiên bỏ kích thước cứng cho thành phần chứa text.
- Thay `width` cứng bằng `double.infinity`, `Expanded`, `Flexible`, `LayoutBuilder`, `ConstrainedBox` theo ngữ cảnh.
- Chuyển `height` cứng sang `minHeight` + `padding` để text có thể nở ra mà không tràn.
- Ưu tiên `SingleChildScrollView` cho màn có nhiều khối nội dung dọc.
- Chuẩn hóa font family về những font đã khai báo.
- Không khóa cứng text scale toàn app về `1.0`; thay vào đó sửa layout để chịu được text scale lớn.
- Nếu có widget thứ ba không ổn định, chỉ clamp text scale ở mức cục bộ widget đó.

## 6. Kế hoạch triển khai theo giai đoạn

## Giai đoạn 1 - Đặt nền tảng responsive (P0)
- Tạo utility responsive nhẹ (breakpoint + helper spacing/co giãn) trong `lib/core`.
- Định nghĩa ngưỡng kích thước test chuẩn: `320`, `360`, `390`, `411`, `>=600 dp`.
- Định nghĩa ngưỡng text scale test chuẩn: `1.0`, `1.15`, `1.3`, `1.5`.
- Chốt quy tắc review responsive chung cho team.

## Giai đoạn 2 - Sửa widget dùng chung (P0)
- `app_input_component.dart`: bỏ `height` cứng `55/65`, đổi sang chiều cao linh hoạt.
- `app_notification_dialog.dart` + `notification_modal.dart`: tối ưu `max width/max height` + xử lý text dài.
- `app_overlay_sheet.dart`: bỏ giá trị chiều cao mặc định có nguy cơ tràn, dùng constraints theo màn hình.
- `auth_text_field.dart` + `social_login_button.dart` + `app_button.dart`: bỏ `width/height` cứng và đảm bảo text có thể wrap hoặc scale an toàn.

## Giai đoạn 3 - Sửa màn hình ưu tiên cao (P0)
- `start_screen.dart`: cho phép cuộn dọc, bỏ width button cứng, cân bằng khoảng cách theo màn hình.
- `login_screen.dart` và `signup_screen.dart`: bỏ các `SizedBox(width: xxx)` không cần thiết, tối ưu trên máy hẹp.
- `personal_info_screen.dart`: xử lý các khối có width lớn, row có nút bên phải, và khối confirm logout.
- `app_appearance_screen.dart` và `about_app_screen.dart`: đảm bảo text dài không tràn khi đổi ngôn ngữ/text scale.

## Giai đoạn 4 - Mở rộng P1/P2
- `schedule_history_screen.dart` và dashboard card: sửa row/label có width cứng.
- Quét thêm các màn còn lại có width/height cứng lớn hoặc không có scroll.
- Chuẩn hóa style typography và spacing để giảm nguy cơ tái phát.

## Giai đoạn 5 - QA, hồi quy và chấp nhận
- Test tay theo ma trận thiết bị + text scale + ngôn ngữ.
- Kiểm tra log runtime, đảm bảo không còn thông báo overflow.
- Chụp screenshot đối chiếu trước/sau ở các màn P0.
- Nghiệm thu với 1 máy ảo + ít nhất 2 máy thật.

## 7. Tiêu chí hoàn thành (Definition of Done)
- Không còn `RenderFlex overflow` trên tất cả màn P0 ở text scale đến `1.3`.
- Các dialog/sheet không bị cắt nội dung, nút bấm vẫn nhấn được.
- Các màn Auth và Personal Info hiển thị ổn định trên `320-411 dp`.
- Font family trong code thống nhất với font đã khai báo trong `pubspec.yaml`.
- QA checklist được đánh dấu đầy đủ và có bằng chứng screenshot.

## 8. Kế hoạch test chi tiết
- Kích thước màn: `320x568`, `360x780`, `390x844`, `411x891`, tablet `>=600dp`.
- Hệ điều hành: Android tối thiểu 2 máy thật (1 máy nhỏ, 1 máy trung bình).
- Font scale hệ thống: `1.0`, `1.15`, `1.3`, `1.5`.
- Ngôn ngữ: `vi`, `en` (ưu tiên string dài nếu có).
- Luồng test: Auth -> Home -> Personal Info -> App Appearance -> About App -> Dialog/Sheet.

## 9. Ước lượng và thứ tự ưu tiên
- Đợt 1 (Giai đoạn 1 + 2): 1-2 ngày.
- Đợt 2 (Giai đoạn 3): 1-2 ngày.
- Đợt 3 (Giai đoạn 4 + 5): 1 ngày.
- Tổng ước lượng: 3-5 ngày làm việc.

## 10. Rủi ro và cách giảm rủi ro
- Rủi ro: Sửa responsive làm thay đổi visual so với mock cũ.
- Giảm rủi ro: Chốt lại quy tắc spacing/typography trước khi sửa hàng loạt.
- Rủi ro: Fix nhanh từng màn dễ sinh inconsistency.
- Giảm rủi ro: Ưu tiên sửa widget dùng chung trước, màn hình sau.
- Rủi ro: Deadline gấp.
- Giảm rủi ro: Chia P0/P1/P2 rõ ràng, giao trước P0 để giải quyết lỗi tràn nghiêm trọng.

## 11. Bước tiếp theo để triển khai
- Chốt phê duyệt kế hoạch này.
- Bắt đầu thực hiện Giai đoạn 1 và 2 trong cùng một nhánh.
- Sau khi xong P0, demo bản test trên máy thật trước khi mở rộng P1/P2.
