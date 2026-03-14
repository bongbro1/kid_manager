# Loi crash avatar rong o ScheduleScreen

## Tom tat

Man `ScheduleScreen` bi crash khi tai khoan child chua co anh avatar. Tai khoan da upload avatar tu truoc thi khong gap loi nay.

## Nguyen nhan

Flutter `CircleAvatar` co rang buoc:

- Neu `foregroundImage == null` thi `onForegroundImageError` bat buoc cung phai la `null`.

Trong file [lib/views/parent/schedule/schedule_screen.dart](/c:/Users/ducth/kid_manager/lib/views/parent/schedule/schedule_screen.dart), code dang co 2 cho truyen:

```dart
foregroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
onForegroundImageError: (_, _) {},
```

Khi `avatarUrl` cua be la `null`, chuoi rong, hoac chi co khoang trang:

- `foregroundImage` se thanh `null`
- `onForegroundImageError` van khac `null`
- `CircleAvatar` nem assertion:

```text
'foregroundImage != null || onForegroundImageError == null'
```

Vi vay loi chi xuat hien voi tai khoan chua upload avatar.

## Hau qua

- App do man hinh do ngay khi vao `ScheduleScreen`.
- Phan chon child o AppBar khong render duoc.
- Nguoi dung co the hieu nham la loi du lieu Firebase, trong khi day la loi render widget o Flutter.
- Neu chua sua, bat ky child moi nao khong co avatar deu co nguy co gay crash.

## Cach sua

Can dam bao `onForegroundImageError` chi duoc gan khi thuc su co `foregroundImage`.

Sua thanh:

```dart
foregroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
onForegroundImageError: avatar.isNotEmpty ? (_, _) {} : null,
```

Da ap dung o 2 vi tri trong [lib/views/parent/schedule/schedule_screen.dart](/c:/Users/ducth/kid_manager/lib/views/parent/schedule/schedule_screen.dart):

- Ham `_buildSelectedChildAvatar`
- `CircleAvatar` ben trong `PopupMenuItem`

## Ket qua mong doi sau khi sua

- Child chua co avatar se hien chu cai dau ten thay vi crash.
- Child da co avatar van hien anh nhu cu.
- Neu anh URL loi trong luc tai, callback `onForegroundImageError` van co the xu ly ma khong vi pham assertion.

## Ghi chu

Day la loi UI logic, khong phai loi Firestore hay Firebase Auth. Cac dong `PERMISSION_DENIED` va `App Check token` trong log la van de khac, khong phai nguyen nhan truc tiep cua man hinh do trong truong hop nay.
