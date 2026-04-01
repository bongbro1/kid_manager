# Master AI QA Prompt For Recent Changes

Sử dụng prompt dưới đây để giao cho một AI coding agent kiểu Codex/ChatGPT thực hiện một vòng kiểm tra read-only cho các thay đổi gần đây trong repo này.

```text
Bạn đang làm nhiệm vụ QA kỹ thuật/read-only audit cho repo Flutter + Firebase này.

Mục tiêu:
- Thực hiện một vòng xác minh read-only đối với các thay đổi gần đây trong repo.
- Ưu tiên phát hiện regression, bug hành vi, sai RBAC, race condition, stream/query không ổn định, và lỗi production-risk.
- Không được sửa code, không được tạo patch, không được format file, không được mutate repo-tracked files.

Nguyên tắc làm việc:
- Luôn inspect code trước khi kết luận.
- Chỉ dùng các hành động non-mutating:
  - đọc file
  - search bằng rg
  - static inspection
  - chạy check/test/build không sửa file khi cần
- Ưu tiên bằng chứng cụ thể:
  - file path
  - line reference
  - role/flow bị ảnh hưởng
  - command output hoặc log nếu có
- Nếu một điều chưa xác minh được, phải ghi rõ là “chưa xác minh được”, không được đoán.

Phạm vi kiểm tra:

1. Safe-route
- Xác nhận current-trip canonical hiện dùng `safe_route_current_trips/{childId}` làm nguồn chính.
- Kiểm tra child audience chỉ thấy trip monitorable.
- Kiểm tra adult audience vẫn thấy recent completed trong grace window.
- Kiểm tra flow complete/cancel của parent/guardian:
  - nút loading/disable đúng
  - không double-submit
  - dialog success chỉ hiện đúng một lần sau khi backend/state canonical xác nhận complete
  - route/HUD của child chỉ tự clear sau khi canonical state đổi
- Kiểm tra `TrackingPage` không còn chạy side effect trực tiếp trong `build()`.

2. Location + background tracking
- Kiểm tra false-positive `background_disabled` đã được xử lý:
  - app đang foreground không bị báo sai
  - service nền đang chạy không bị báo sai
- Kiểm tra child current location và `historyByDay` vẫn ghi đúng sau các thay đổi runtime/routing/background.
- Kiểm tra timezone/day-key path và fallback đọc history không làm current/history bị regress.

3. RBAC member/location
- Kiểm tra `parent`, `guardian`, `child` nhìn thấy đúng member/child trong các màn member/location.
- Kiểm tra guardian chỉ thấy child được assign.
- Kiểm tra Firestore rules cho `trips`, `routes`, `safe_route_current_trips` đúng theo intended access.

4. SOS
- Kiểm tra `child` có thể tạo SOS nhưng không resolve được.
- Kiểm tra chỉ `parent/guardian` nhận và resolve incoming SOS.
- Kiểm tra confirm SOS thật sự clear overlay, clear local notification, dừng tiếng/ringing.
- Kiểm tra `child` không còn thấy incoming SOS overlay cho SOS do parent/guardian tạo.

5. Notifications
- Kiểm tra notification tracking/location không bị duplicate trong app hoặc trên system tray.
- Kiểm tra notification tracking/background/location vẫn đi đúng channel/path sau refactor gần đây.

6. Mapbox / backend proxy
- Kiểm tra client không còn phụ thuộc backend secret token cho route/search/matching.
- Kiểm tra render map vẫn hoạt động với public client token path.

Cách kiểm tra yêu cầu:
- Đọc các file liên quan trước khi đưa ra nhận xét.
- Dùng targeted search, không được phán đoán chung chung.
- Khi hữu ích, chạy các lệnh non-mutating như:
  - `flutter test` cho test mục tiêu
  - `npm --prefix functions run build`
  - inspect rules, triggers, data sources, viewmodels, repositories
- Nếu command timeout hoặc môi trường không đủ điều kiện, phải ghi rõ.

Output bắt buộc theo đúng thứ tự:

1. Findings
- Liệt kê theo severity cao xuống thấp.
- Mỗi finding phải có:
  - vấn đề là gì
  - vì sao quan trọng
  - file reference cụ thể
  - role/flow bị ảnh hưởng

2. Passes
- Liệt kê ngắn gọn các hành vi đã kiểm mà trông đúng.

3. Gaps / Could not verify
- Những gì chưa verify được
- command nào timeout / không chạy được
- flow nào cần test tay hoặc test trên device thật
- assumption nào đã phải dùng

4. Recommended next tests
- Các test tiếp theo có giá trị cao nhất
- Ưu tiên manual/e2e/device test cho các phần khó xác minh bằng static inspection

Tiêu chuẩn đánh giá:
- Không chỉ nhìn “code có vẻ đúng”, mà phải ưu tiên:
  - path nóng production
  - stream/query/query-cost
  - state sync giữa backend và UI
  - behavior theo từng role
  - background/runtime lifecycle
  - notification duplication hoặc mất notification

Lưu ý:
- Đây là read-only audit.
- Không được đề xuất patch ngay trong quá trình kiểm tra, trừ khi phần “Recommended next tests” hoặc “Follow-up fixes” được yêu cầu rõ trong báo cáo.
- Nếu không có findings, hãy nói rõ “không tìm thấy findings rõ ràng”, nhưng vẫn phải nêu residual risks và testing gaps.
```
