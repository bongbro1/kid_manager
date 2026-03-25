## Phase 3 - Data Access, Database Models vÃ  Repository Layer

### 1. `watchFamilyMembers` tái hiện N+1 query trên mỗi lần snapshot thay đổi

- File: `lib/repositories/user/family_repository.dart:120-157`
- Loại lỗi: `Performance`, `Scalability`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Mỗi khi `families/{familyId}/members` thay đổi, code lại `get()` từng `users/{uid}` riêng lẻ.
- Với 10-20 thành viên, mỗi snapshot sẽ tạo 10-20 read bổ sung, tăng ch? phí Firestore và làm UI gia tăng latency không cần thiết.
- Đây là pattern N+1 điển hình ở tầng repository.

Đoạn code lỗi:

```dart
final users = await Future.wait(
 memberDocs.map((memberDoc) async {
  final uid = (memberDoc.data()['uid'] ?? memberDoc.id).toString();
  final userSnap = await userRef(uid).get();
  if (userSnap.exists) {
   return AppUser.fromDoc(userSnap);
  }
  return _fallbackFamilyMember(memberDoc, familyId: familyId);
 }),
);
```

Đề xuất:

- Batch read user docs theo `documentId in [...]` theo từng chunk.
- Nếu `families/*/members` đã là source-of-truth cho listing UI thì chỉ hydrate đầy đủ khi thật sự cần profile ch? tiết.

Đoạn code đề xuất sửa lỗi:

```dart
Future<List<AppUser>> _loadUsersByIds(List<String> ids) async {
 final users = <AppUser>[];

 for (var i = 0; i < ids.length; i += 10) {
  final chunk = ids.sublist(i, (i + 10 > ids.length) ? ids.length : i + 10);
  final snap = await _users
    .where(FieldPath.documentId, whereIn: chunk)
    .get();

  users.addAll(snap.docs.map(AppUser.fromDoc));
 }

 return users;
}
```

---

### 2. `watchTrackableLocationMembers` vừa N+1 query vừa "tự chữa" dữ liệu thiếu, có thể làm sai danh sách được phép theo dõi

- File: `lib/repositories/user/membership_repository.dart:34-101`
- File: `lib/repositories/user/membership_repository.dart:120-181`
- File: `lib/models/app_user.dart:180-194`
- Loại lỗi: `Security`, `Logic`, `Performance`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Repository này cũng lặp lại N+1 pattern bằng cách `get()` từng `users/{uid}`.
- Nguy hiểm hơn, code đang tự suy diễn `familyId`, `parentUid`, và mặc định `allowTracking=true` cho child nếu field thiếu.
- Khi user doc bị thiếu, stale, hoặc provision chưa hoàn tất, app vẫn có thể đưa member đó vào danh sách trackable.
- Điều này làm lệch semantics authorization giữa dữ liệu canonical và dữ liệu được hiển thị/thực thi ở client.

Đoạn code lỗi:

```dart
static bool _readAllowTracking(
 Map<String, dynamic> data, {
 required UserRole role,
}) {
 final raw = data['allowTracking'];
 if (raw is bool) {
  return raw;
 }
 if (role == UserRole.child) {
  return true;
 }
 return false;
}
```

```dart
return AppUser(
 uid: uid,
 role: role,
 familyId: familyId,
 displayName: data['displayName']?.toString(),
 avatarUrl: data['avatarUrl']?.toString(),
 allowTracking: role == UserRole.child,
 parentUid: fallbackParentUid,
);
```

Đề xuất:

- Không tự bật `allowTracking` nếu field thiếu.
- Không synthesize `familyId`/`parentUid` cho các luồng nhạy cảm tới authorization.
- Nếu user doc không tồn tại hoặc thiếu field bắt buộc thì loại member khỏi danh sách trackable và log inconsistency để migration xử lý.

Đoạn code đề xuất sửa lỗi:

```dart
static bool _readAllowTracking(
 Map<String, dynamic> data, {
 required UserRole role,
}) {
 final raw = data['allowTracking'];
 return raw is bool ? raw : false;
}

Future<AppUser?> _loadCanonicalTrackableUser(
 String uid, {
 required String familyId,
}) async {
 final snap = await userRef(uid).get();
 if (!snap.exists) return null;

 final user = AppUser.fromDoc(snap);
 final sameFamily = (user.familyId ?? '').trim() == familyId;
 final hasParentLink = user.role == UserRole.parent ||
   (user.parentUid ?? '').trim().isNotEmpty;

 if (!sameFamily || !hasParentLink) {
  return null;
 }

 return user;
}
```

---

### 3. Safe-route live stream đang phụ thuộc vào path mirror `live_locations/*` thay vì canonical source `locations/*/current`

- File: `lib/features/safe_route/data/datasources/safe_route_remote_data_source.dart:79-155`
- File: `lib/repositories/location/location_repository_impl.dart:158-208`
- File: `lib/repositories/location/location_repository_impl.dart:379-380`
- File: `functions/src/triggers/safeRoute.ts:856-877`
- File: `functions/src/functions/locations.ts:45-53`
- Loại lỗi: `Logic`, `Performance`, `Reliability`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Tracking chính ghi vào `locations/{uid}/current`.
- Màn safe-route lại subscribe `live_locations/{childId}`.
- Backend phải mirror qua trigger `syncSafeRouteLiveLocation`, rồi trigger khác mới monitor trip từ path mirror.
- Đây là một lớp eventual-consistency không cần thiết cho dữ liệu an toàn hành trình: nếu mirror bị delay, lỗi, hoặc backlog trigger tăng thì safe-route sẽ stale dù location chính vẫn còn chuẩn.

Đoạn code lỗi:

```dart
rtdbSub = _database.ref('live_locations/$childId').onValue.listen(
```

```ts
export const syncSafeRouteLiveLocation = onValueWritten(
 {
  ref: "locations/{childId}/current",
  region: RTDB_TRIGGER_REGION,
 },
 async (event) => {
  const targetRef = admin.database().ref(`live_locations/${childId}`);
  ...
  await targetRef.set(liveLocation);
 }
);
```

Đề xuất:

- Dùng `locations/{childId}/current` làm nguồn duy nhất cho cả UI lẫn monitoring.
- Chỉ giữ `live_locations` nếu thực sự cần cache/compat layer và có cơ chế health monitoring rõ ràng.

Đoạn code đề xuất sửa lỗi:

```dart
rtdbSub = _database.ref('locations/$childId/current').onValue.listen(
 (event) {
  final location = parseValue(event.snapshot.value);
  if (location != null && !controller.isClosed) {
   controller.add(location);
   return;
  }

  if (event.snapshot.value == null) {
   startFallbackPolling();
  }
 },
 onError: (Object error, StackTrace stackTrace) {
  unawaited(rtdbSub?.cancel());
  rtdbSub = null;
  startFallbackPolling();
 },
);
```

```ts
export const monitorSafeRouteLiveLocation = onValueWritten(
 {
  ref: "locations/{childId}/current",
  region: RTDB_TRIGGER_REGION,
 },
 async (event) => {
  if (!event.data.after.exists()) return;

  const childId = String(event.params.childId ?? "");
  const liveLocation = parseLiveLocationRecord(childId, event.data.after.val());
  ...
 }
);
```

---

### 4. Safe-route models đang fabricate timestamp bằng `DateTime.now()`, làm sai lịch sử và ordering khi dữ liệu thiếu hoặc malformed

- File: `lib/features/safe_route/data/models/safe_route_model.dart:53-54`
- File: `lib/features/safe_route/data/models/trip_model.dart:42-49`
- Loại lỗi: `Bug`, `Logic`, `Data Integrity`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- `createdAt`, `updatedAt`, `startedAt` và đặc biệt `scheduledStartAt` đang fallback sang `DateTime.now()` khi field thiếu hoặc parse lỗi.
- Điều này che giấu dữ liệu hỏng thay vì fail fast.
- Hậu quả là trip có thể bị hiểu nhầm là vừa bắt đầu hoặc có lịch chạy "ngay lúc parse", gây sai UI, history và logic scheduler.

Đoạn code lỗi:

```dart
createdAt: DateTime.fromMillisecondsSinceEpoch(
 (map['createdAt'] as num?)?.toInt() ??
   DateTime.now().millisecondsSinceEpoch,
),
updatedAt: DateTime.fromMillisecondsSinceEpoch(
 (map['updatedAt'] as num?)?.toInt() ??
   DateTime.now().millisecondsSinceEpoch,
),
```

```dart
scheduledStartAt: map['scheduledStartAt'] == null
  ? null
  : DateTime.fromMillisecondsSinceEpoch(
    int.tryParse(map['scheduledStartAt'].toString()) ??
      DateTime.now().millisecondsSinceEpoch,
   ),
```

Đề xuất:

- Dùng parser riêng trả về `DateTime?`.
- Với field bắt buộc, throw `FormatException` thay vì bịa timestamp.
- Với field optional như `scheduledStartAt`, parse lỗi phải trả `null`, không được dùng `now`.

Đoạn code đề xuất sửa lỗi:

```dart
DateTime? _readMillisDate(dynamic raw) {
 final ms = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
 return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}

factory TripModel.fromMap(Map<String, dynamic> map) {
 final startedAt = _readMillisDate(map['startedAt']);
 final updatedAt = _readMillisDate(map['updatedAt']);
 if (startedAt == null || updatedAt == null) {
  throw const FormatException('Trip is missing required timestamps');
 }

 return TripModel(
  ...
  startedAt: startedAt,
  updatedAt: updatedAt,
  scheduledStartAt: _readMillisDate(map['scheduledStartAt']),
  ...
 );
}
```

---

### 5. Family chat image message chỉ kiểm tra `imageUrl` không rỗng, không verify path/object thuộc đúng family và sender

- File: `lib/repositories/chat/family_chat_repository.dart:56-73`
- File: `lib/services/chat/chat_media_service.dart:104-120`
- File: `functions/src/functions/family_chat.ts:169-181`
- File: `functions/src/functions/family_chat.ts:217-259`
- File: `firestore.rules:232-242`
- Loại lỗi: `Security`, `Data Integrity`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Client có thể tạo pending image message với bất kỳ `imageUrl` hợp lệ về mặt chuỗi.
- Backend `isValidImagePayload()` chỉ check URL length và kích thước ảnh, không kiểm tra:
- object có thật trong Firebase Storage hay không
- path có đúng `families/{familyId}/chat/{senderUid}/{messageId}.jpg` hay không
- metadata `familyId/senderUid/messageId` có khớp hay không
- Điều này cho phép message trỏ tới URL ngoài hệ thống hoặc object không thuộc message hiện tại, gây rủi ro integrity/phishing/tracking pixel.

Đoạn code lỗi:

```ts
function isValidImagePayload(data: FirebaseFirestore.DocumentData): boolean {
 const imageUrl = (data.imageUrl ?? "").toString().trim();
 const imageWidth = Number(data.imageWidth ?? 0);
 const imageHeight = Number(data.imageHeight ?? 0);

 return (
  imageUrl.length > 0 &&
  imageUrl.length <= 2048 &&
  Number.isFinite(imageWidth) &&
  Number.isFinite(imageHeight) &&
  imageWidth > 0 &&
  imageHeight > 0
 );
}
```

Đề xuất:

- Bắt buộc `imagePath`.
- Verify `imagePath` đúng pattern theo `familyId`, `senderUid`, `messageId`.
- Ở backend, đọc metadata object để đối chiếu `familyId/senderUid/messageId`.
- Nếu cần public URL, chỉ generate sau khi verify thành công.

Đoạn code đề xuất sửa lỗi:

```ts
function expectedFamilyChatImagePath(
 familyId: string,
 senderUid: string,
 messageId: string
) {
 return `families/${familyId}/chat/${senderUid}/${messageId}.jpg`;
}

async function verifyImagePayload(params: {
 familyId: string;
 senderUid: string;
 messageId: string;
 data: FirebaseFirestore.DocumentData;
}) {
 const imagePath = (params.data.imagePath ?? "").toString().trim();
 if (imagePath !== expectedFamilyChatImagePath(params.familyId, params.senderUid, params.messageId)) {
  return false;
 }

 const file = admin.storage().bucket().file(imagePath);
 const [exists] = await file.exists();
 if (!exists) return false;

 const [metadata] = await file.getMetadata();
 return metadata.metadata?.familyId === params.familyId &&
   metadata.metadata?.senderUid === params.senderUid &&
   metadata.metadata?.messageId === params.messageId;
}
```

---

### 6. Zone events đang được client ghi trực tiếp lên RTDB, backend tin tưởng payload để bắn thông báo và cập nhật thống kê

- File: `lib/core/zones/zone_monitor.dart:97-105`
- File: `lib/core/zones/zone_monitor.dart:116-124`
- File: `lib/repositories/zones/zone_repository.dart:154-163`
- File: `database.rules.json:27-31`
- File: `functions/src/functions/zoneEvents.ts:51-89`
- Loại lỗi: `Security`, `Logic`, `Data Integrity`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Child client hiện tự quyết định khi nào `enter/exit` zone và push thẳng event lên RTDB.
- Backend trigger sau đó dùng event này để:
- ghi `zonePresenceByChild`
- tính `zoneStatsByChild`
- tạo inbox notification
- bắn push cho parent và child
- RTDB rules chỉ kiểm tra `auth.uid === childUid`, không validate schema, timestamp, zone ownership, hay chống replay.
- Một child client bị compromise có thể forge event giả, spam enter/exit, hoặc backdate timestamp để làm sai thống kê/thông báo.

Đoạn code lỗi:

```dart
final ref = _eventsRef(childUid).push();
await ref.set(event);
```

```json
"zoneEventsByChild": {
 "$childUid": {
  ".read": "auth != null && (auth.uid === $childUid || root.child('locations').child($childUid).child('meta').child('parentUid').val() === auth.uid)",
  ".write": "auth != null && auth.uid === $childUid"
 }
}
```

Đề xuất:

- Thay direct RTDB write bằng callable/server ingestion.
- Server phải tự verify:
- zone tồn tại và thuộc child đó
- timestamp hợp lý so với current location
- trạng thái enter/exit không bị duplicate/replay
- Nếu vẫn giữ RTDB ingress, bổ sung validation rule cực chặt và dedup server-side.

Đoạn code đề xuất sửa lỗi:

```ts
export const reportZoneEvent = onCall({ region: REGION }, async (req) => {
 if (!req.auth?.uid) {
  throw new HttpsError("unauthenticated", "Login required");
 }

 const childUid = req.auth.uid;
 const zoneId = mustString(req.data?.zoneId, "zoneId");
 const action = mustString(req.data?.action, "action");

 const currentSnap = await admin.database().ref(`locations/${childUid}/current`).get();
 if (!currentSnap.exists()) {
  throw new HttpsError("failed-precondition", "Missing current location");
 }

 // Verify child really is inside/outside the declared zone before persisting event.
 ...
});
```

---

### 7. `getFamilyChildrenCurrent` tiếp tục dùng backend N+1 RTDB reads cho mỗi lần refresh danh sách

- File: `functions/src/functions/locations.ts:145-165`
- File: `functions/src/services/locationAccess.ts:127-172`
- Loại lỗi: `Performance`, `Scalability`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Callable đầu tiên query toàn bộ members trackable trong Firestore.
- Sau đó lại `Promise.all` đọc `locations/{uid}/current` cho từng member.
- Với family đông thành viên hoặc màn hình refresh thường xuyên, đây là hotspot đọc chéo Firestore + RTDB khá tốn kém.

Đoạn code lỗi:

```ts
const reads = await Promise.all(
 members.map(async (member) => {
  const snap = await admin.database().ref(`locations/${member.uid}/current`).get();
  return {
   childUid: member.uid,
   role: member.role,
   allowTracking: member.allowTracking,
   current: snap.exists() ? snap.val() : null,
  };
 })
);
```

Đề xuất:

- Duy trì aggregate `families/{familyId}/trackingStatus/{uid}` hoặc collection/cache chuyên dụng cho dashboard.
- Tách luồng list trackable members khỏi luồng lấy current location.
- Chỉ fetch location cho member đang hiển thị trên viewport hoặc được chọn.

Đoạn code đề xuất sửa lỗi:

```ts
const trackingSnap = await db
 .collection(`families/${familyId}/trackingStatus`)
 .get();

const byUid = new Map(
 trackingSnap.docs.map((doc) => [doc.id, doc.data()])
);

const children = members
 .map((member) => ({
  childUid: member.uid,
  role: member.role,
  allowTracking: member.allowTracking,
  current: byUid.get(member.uid) ?? null,
 }))
 .filter((item) => item.current != null);
```

---

## Tóm tắt rủi ro Phase 3

CÃ¡c vấn đề ưu tiên xử lý ngay sau Phase 3:

1. Loại bỏ các fallback "tự chữa" dữ liệu ở `MembershipRepository` và `AppUser._readAllowTracking` cho các luồng authorization-sensitive.
2. Hợp nhất canonical path cho live location của safe-route, tránh phụ thuộc vào trigger mirror `live_locations/*`.
3. Bổ sung server-side verification cho family chat image payload và zone event ingestion.
4. Giảm N+1 read ở `watchFamilyMembers`, `watchTrackableLocationMembers` và `getFamilyChildrenCurrent`.
5. Ngừng fabricate timestamp bằng `DateTime.now()` khi parse model lỗi hoặc dữ liệu thiếu.
