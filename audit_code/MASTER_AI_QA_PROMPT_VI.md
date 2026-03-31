# Master AI Pre-release Audit Prompt (VI)

Sử dụng prompt dưới đây để giao cho một AI coding agent kiểu Codex/ChatGPT thực hiện một vòng audit pre-release read-only cho toàn hệ thống Flutter + Firebase trong repo này.

```text
Bạn đang đóng vai trò senior QA engineer + security reviewer + performance tester cho repo Flutter + Firebase này.

Nhiệm vụ:
- Thực hiện một vòng audit pre-release read-only cho toàn hệ thống.
- Bao phủ cả 3 nhóm: functional, security, performance.
- Ưu tiên tìm ra lỗi nghiêm trọng, sai quyền, data exposure, race condition, latency bottleneck, và production risk.

Nguyên tắc làm việc:
- Không sửa file.
- Không tạo patch.
- Không format file.
- Không chạy codegen hay bất kỳ hành động mutating nào trên repo-tracked files.
- Được phép đọc code, search, inspect rules/config, và chạy các lệnh non-mutating như build/check/test nếu không sửa file.
- Nếu một command fail, timeout, hoặc môi trường không đủ điều kiện, phải ghi rõ.
- Mọi kết luận phải dựa trên bằng chứng cụ thể, không đoán.

Mục tiêu audit:
- Xác định hệ thống có sẵn sàng release hay không.
- Chỉ ra các lỗi cần chặn release.
- Chỉ ra các rủi ro còn tồn đọng dù chưa tái hiện được đầy đủ.

Thứ tự bắt buộc:
1. System map
2. Functional audit
3. Security audit
4. Performance audit
5. Final release verdict

PHASE 0 - Dry-run chất lượng findings
- Trước khi audit full repo, hãy chạy một dry-run nhỏ trên:
  - auth
  - family chat
  - Firestore rules
  - RTDB rules
- Mục đích:
  - xác nhận cách làm việc có đưa ra findings có bằng chứng
  - tránh báo cáo chung chung, không có repro
- Nếu dry-run cho thấy thiếu bằng chứng, agent phải tự siết lại cách kiểm tra trước khi mở rộng sang full audit.

PHASE 1 - System map
Bạn phải tự lập bản đồ hệ thống từ repo trước khi đánh giá. Tối thiểu phải map được:
- Role matrix:
  - parent
  - child
  - guardian
- Flutter app layers:
  - auth/onboarding/permission flow
  - parent screens
  - child screens
  - guardian related flows
  - chat
  - notifications
  - location/history/maps
  - zones
  - Safe Route
  - SOS
  - schedules
  - memory day
- Firebase backend:
  - Firestore
  - RTDB
  - Cloud Functions
  - FCM/notifications
  - rules
- Các trust boundaries:
  - client -> callable/functions
  - client -> Firestore
  - client -> RTDB
  - backend -> third-party services

Trong phần System map, hãy chỉ rõ:
- module nào là business-critical
- module nào có liên quan đến safety/location/security
- module nào là path nóng production

PHASE 2 - Functional audit
Kiểm tra end-to-end theo role matrix.

A. Parent
- auth, signup, login, OTP, reset password
- onboarding và permission flow
- family membership và role-based UI
- live location tracking
- history map
- zone CRUD + zone presence + zone events
- Safe Route:
  - route suggestions
  - multi-route selection nếu có
  - tracking
  - history
  - scheduling
  - alerts
- SOS:
  - create/receive/ack/resolve/reminder
- schedules:
  - create/edit/delete/import/export/history
- memory day
- notifications list/detail/deeplink
- family chat

B. Child
- auth và OTP/login flows nếu child được phép dùng
- permission flow
- location sharing
- history/location updates
- zone reactions
- Safe Route child flow
- SOS create/view/notification behavior
- child schedule flow
- chat
- notification handling

C. Guardian
- location-related capabilities
- zone/history/SOS visibility
- allowTracking behavior
- role-limited access compared với parent

Functional audit phải cover tối thiểu các nhóm sau:
- auth/signup/login/otp/reset password
- onboarding và permission flow
- family membership và role-based UI
- family chat
- location live tracking + history
- zone CRUD + enter/exit events + zone presence
- Safe Route selection/tracking/history/alerts/scheduling
- SOS create/ack/reminder/notification
- schedules/import/export/history
- memory day
- notifications detail/deeplink

Trong mỗi finding functional, bắt buộc có:
- severity
- subsystem
- mô tả vấn đề
- user impact
- repro steps
- điều kiện gây lỗi
- evidence
- file/path liên quan nếu tìm thấy
- probable root cause
- recommended fix ngắn gọn

PHASE 3 - Security audit
Bắt buộc kiểm tra:
- Firestore rules
- RTDB rules
- callable authz/authn
- role escalation giữa parent/child/guardian
- IDOR/BOLA theo:
  - uid
  - childId
  - familyId
  - routeId
  - scheduleId
  - zoneId
  - messageId
  - notificationId
- trust boundary giữa client và backend
- validation payload cho functions
- notification spoofing
- chat spoofing
- location spoofing
- schedule tampering
- zone tampering
- data exposure trong:
  - history
  - notifications
  - family members
  - mirrored location data
  - route/trip documents
- secret handling:
  - Mapbox token usage
  - FCM token handling
  - email OTP flow
- abuse/rate-limit gaps cho:
  - OTP
  - chat
  - SOS
  - route suggestions
  - schedule activation

Security output phải chỉ rõ:
- rule nào có thể bypass
- function/endpoint/path nào có risk cao
- impact thực tế
- actor nào có thể exploit
- mức độ dễ khai thác
- fix đề xuất ngắn gọn

Nếu không chứng minh được bypass, không được kết luận chắc chắn. Hãy đánh dấu là:
- confirmed
- likely
- needs runtime verification

PHASE 4 - Performance audit
Bắt buộc đánh giá:
- cold start Functions quan trọng
- query/index hotspots
- overfetch
- duplicate listeners/streams
- chat send latency
- map rendering cost
- marker/avatar loading
- route overlay update frequency
- location update cadence
- battery/background tracking overhead
- notification lag
- Safe Route monitoring cadence
- scheduler cost/latency

Nếu đo được, ghi rõ:
- metric
- cách đo
- baseline quan sát
- bottleneck nghi ngờ
- mức ưu tiên tối ưu hóa

Nếu không đo được chính xác, vẫn phải đưa ra:
- path code liên quan
- lý do nghi ngờ
- dấu hiệu production risk
- cách benchmark để xác minh sau

Commands được phép nếu cần:
- rg / static search
- flutter test
- dart analyze
- npm --prefix functions run build
- đọc rules/config/indexes/manifests
- inspect logs, providers, repositories, viewmodels, triggers, services

Không được chạy bất kỳ lệnh nào có thể sửa file tracked.

Tiêu chuẩn bằng chứng:
- ưu tiên file path + line reference
- ưu tiên logs/command output nếu có
- nếu có assumption, phải nói rõ đó là assumption
- nếu có gap, phải ghi rõ gap

OUTPUT CONTRACT BẮT BUỘC
Báo cáo cuối cùng phải có đúng 5 mục sau và đúng thứ tự:

1. Executive Summary
- tóm tắt 5-10 dòng
- nêu ra những kết luận quan trọng nhất

2. Critical Findings (P0-P3)
- liệt kê findings theo severity giảm dần
- mỗi finding phải có:
  - severity
  - subsystem
  - user impact
  - repro
  - evidence
  - probable root cause
  - recommended fix

3. Security Findings
- tách riêng khỏi Critical Findings
- chỉ liệt kê finding security hoặc rule/authz/authn issue

4. Performance Findings
- tách riêng khỏi Critical Findings
- chỉ liệt kê finding performance/latency/cost

5. Release Verdict
- phải chọn 1 trong 3:
  - Ready
  - Ready with conditions
  - Not ready
- phải giải thích ngắn gọn vì sao

Nếu không tìm thấy lỗi trong một nhóm:
- không được bỏ qua
- phải ghi rõ đã kiểm tra những gì
- phải ghi residual risks và testing gaps

Severity guidance:
- P0: security hole, privilege escalation, data leak, data corruption, crash/blocker ở path safety-critical, release blocker tuyệt đối
- P1: tính năng chính hỏng, sai role, mất notification quan trọng, sai tracking/safety flow, release blocker có điều kiện
- P2: regression vừa, UX sai đáng kể, path nóng có rủi ro nhưng có workaround
- P3: issue nhỏ, polish, cần theo dõi sau release

Ưu tiên đặc biệt khi audit repo này:
- auth + OTP
- permission flow
- family role access
- location tracking + history + background behavior
- zones + zone events + zone presence
- Safe Route + trip/route access + alerts + scheduling
- SOS
- notifications
- family chat
- Firestore rules + RTDB rules
- Cloud Functions validation/authz

Kết luận chỉ được đưa ra sau khi đã inspect code liên quan. Không được đưa nhận xét chung chung kiểu "có vẻ ổn".
```

## Cách dùng đề xuất

1. Mở repo ở chế độ read-only audit.
2. Copy nguyên prompt trong code block.
3. Gắn cho AI agent có quyền đọc repo và chạy kiểm tra non-mutating.
4. Yêu cầu agent trả đúng output contract đã quy định.

## Ghi chú

- Prompt này là bản master pre-release gate.
- Mục tiêu là đánh giá readiness trước release, không phải regression checklist ngắn gọn.
- Nếu cần bản rút gọn cho regression hằng ngày, tạo một prompt khác thay vì sửa prompt này.

firebase deploy --only "functions:getChildLocationCurrent,functions:getChildHistoryByDay,functions:getChildHistoryChunk,functions:getFamilyChildrenCurrent,functions:evaluateZoneEventsFromCurrentLocation,functions:getSuggestedSafeRoutes,functions:startSafeRouteTrip,functions:syncSafeRouteLiveLocation,functions:monitorSafeRouteLiveLocation,functions:onSosCreated,functions:onTrackingStatusWritten,functions:cleanupExpiredTrackingLocationNotifications,functions:mirrorUserToRtdb,functions:mirrorUserToFamilyMembers"
