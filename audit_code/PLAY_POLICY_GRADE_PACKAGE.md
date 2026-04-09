# Play Policy Grade Package

## Muc tieu
- Giu full feature cua ung dung `family tracking + parental monitoring`.
- Dong bo 4 mat tran de tang kha nang duoc Google Play chap thuan:
  - Manifest
  - In-app disclosure
  - Play Console declaration answers
  - Video review checklist

## 1. Manifest shipment

### Da cap nhat trong code
- Them `isMonitoringTool=child_monitoring` vao manifest:
  - [AndroidManifest.xml](/E:/ProjectAndriod/kid_manager/android/app/src/main/AndroidManifest.xml:33)
- Thu hep scope AccessibilityService xuong muc can thiet cho foreground app monitoring:
  - [accessibility_config.xml](/E:/ProjectAndriod/kid_manager/android/app/src/main/res/xml/accessibility_config.xml:4)

### Quyen hien tai va cach bien ho

1. `ACCESS_FINE_LOCATION`
- Giu.
- Dung cho live location, safe zone, safe route.

2. `ACCESS_BACKGROUND_LOCATION`
- Giu.
- Chi khai bao 1 core feature trong declaration:
  - `Child safety geofencing and live family safety tracking`
- Khong khai bao nhieu feature cung luc.

3. `PACKAGE_USAGE_STATS`
- Giu.
- Dung cho screen-time va app usage monitoring tren thiet bi cua tre.
- Chi xin trong context parent control / app management.

4. `BIND_ACCESSIBILITY_SERVICE`
- Giu.
- Dung cho app blocking / foreground app detection theo quy tac do phu huynh dat.
- Khong duoc mo ta nhu mot accessibility tool cho nguoi khuyet tat.

5. `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- Giu.
- Dung de tranh Android dung runtime theo doi an toan o che do nen.
- Khong nen trinh bay nhu quyen du lieu; day la system-exemption phuc vu tinh on dinh.

6. `ACTIVITY_RECOGNITION`
- Giu neu pipeline tracking can motion classification.
- Neu sau nay khong con dung trong route/tracking pipeline, nen bo.

7. `READ_CONTACTS`
- Giu neu ban muon giu tinh nang chon so dien thoai tu danh ba.
- Khong dua vao core declaration. Day la tinh nang phu.
- Chi xin khi nguoi dung bam nut mo danh ba.

8. `READ_MEDIA_IMAGES`
- Hien dang co trong manifest.
- Ve mat policy, day la diem rui ro vi use case avatar/profile thuong nen dung picker.
- Neu giu full feature hien tai, can uu tien thay bang system photo picker trong dot phat hanh sau.

9. `QUERY_ALL_PACKAGES`
- Rui ro cao nhat.
- Chi giu neu ban quyet dinh bao ve lap luan sau:
  - app parental control can awareness ve bat ky app nao duoc cai va duoc mo tren thiet bi cua tre de ap dung app blocking va usage monitoring tren app bat ky
  - targeted package visibility khong du cho use case app blocking tong quat
- Neu reviewer challenge diem nay, day la quyen nen loai bo dau tien bang cach tach `play` flavor.

## 2. In-app disclosure copy

### 2.1 Background location

#### English
```text
This app collects location data to show live child location, trigger Safe Zone alerts, and support Safe Route even when the app is closed or not in use. Location is shared with the parent or assigned guardian in the same family for safety features. This app does not use location data for ads.
```

#### Vietnamese
```text
Ung dung nay thu thap du lieu vi tri de hien thi vi tri truc tiep cua tre, tao canh bao Vung an toan va ho tro Safe Route ngay ca khi ung dung da dong hoac khong su dung. Vi tri duoc chia se voi phu huynh hoac nguoi giam ho duoc chi dinh trong cung gia dinh cho cac tinh nang an toan. Ung dung khong su dung du lieu vi tri cho quang cao.
```

### 2.2 Accessibility service

#### English
```text
This app uses Android Accessibility to detect which app is open on the child device and apply parent-defined blocking rules. The app does not use Accessibility to read messages, passwords, or typed content. App open events are shown to the parent or assigned guardian for parental control and digital safety.
```

#### Vietnamese
```text
Ung dung nay su dung Accessibility tren Android de nhan biet ung dung nao dang mo tren thiet bi cua tre va ap dung quy tac chan do phu huynh dat. Ung dung khong dung Accessibility de doc tin nhan, mat khau hoac noi dung nhap vao. Su kien mo ung dung duoc hien thi cho phu huynh hoac nguoi giam ho duoc chi dinh de phuc vu kiem soat cua phu huynh va an toan so.
```

### 2.3 Usage access

#### English
```text
This app uses Usage Access to measure which apps the child uses and for how long on Android, then show that usage to the parent or assigned guardian for screen-time management and parental control.
```

#### Vietnamese
```text
Ung dung nay su dung Usage Access de do ung dung nao tre su dung va thoi gian su dung tren Android, sau do hien thi du lieu nay cho phu huynh hoac nguoi giam ho duoc chi dinh de quan ly thoi gian man hinh va kiem soat cua phu huynh.
```

### 2.4 Battery optimization

#### English
```text
Allow this app to ignore battery restrictions so child tracking, Safe Zone alerts, and SOS safety features can continue working reliably in the background.
```

#### Vietnamese
```text
Cho phep ung dung bo qua gioi han pin de theo doi tre, canh bao Vung an toan va cac tinh nang SOS tiep tuc hoat dong on dinh o che do nen.
```

## 3. App listing wording

### One core feature to promote
- Use one background-location core feature consistently everywhere:
  - `Child safety geofencing and live family safety tracking`

### Suggested short listing phrases

#### English
- `Live child location, Safe Zone alerts, SOS, Safe Route, and parental app controls for family safety.`
- `Parents can view child location, get geofence alerts, review app usage, and apply app blocking rules on the child device.`

#### Vietnamese
- `Theo doi vi tri truc tiep cua tre, canh bao Vung an toan, SOS, Safe Route va kiem soat ung dung de phuc vu an toan gia dinh.`
- `Phu huynh co the xem vi tri cua tre, nhan canh bao ra vao vung, xem thoi gian dung app va ap dung quy tac chan ung dung tren thiet bi cua tre.`

## 4. Play Console declaration answers

### 4.1 Monitoring tool flag
- `isMonitoringTool`:
  - `child_monitoring`

### 4.2 Background location declaration

#### Feature to declare
- `Child safety geofencing and live family safety tracking`

#### Suggested answer: Why does the app need background location?
```text
The app needs background location so that a parent can receive child safety alerts and live tracking updates even when the app is not open. The declared core feature is child safety geofencing and live family safety tracking. Without background location, Safe Zone enter/exit alerts, live child tracking, and Safe Route safety monitoring would stop when the child app is closed or in the background, which would break the app's main safety purpose.
```

#### Suggested answer: Why is foreground location not enough?
```text
Foreground location is not sufficient because the main safety use case happens while the child device is moving normally throughout the day, including when the child app is closed or minimized. The app must keep location updates active in the background to detect geofence transitions, maintain live child safety tracking, and support Safe Route monitoring for the parent.
```

#### Suggested answer: What data is collected and who sees it?
```text
The app collects precise device location from the child device. This data is used only for live location, Safe Zone alerts, SOS, and Safe Route safety features. Location is shown only to the parent or assigned guardian in the same family group. The app does not use location for advertising.
```

### 4.3 Accessibility declaration

#### Accessibility tool?
- `No`

#### Why does the app need Accessibility Services API?
```text
The app uses Accessibility Services for parental control functionality on the child device. It detects which app is currently opened so it can apply parent-defined blocking rules and generate related parental control notifications.
```

#### Does the app collect or share personal or sensitive data using Accessibility?
```text
No, the app does not use Accessibility to read typed text, passwords, messages, or form content. It only uses app-open events and package identity needed for parental control and app blocking.
```

#### Narrow and clearly understood purpose
```text
All actions are deterministic and based on static rules created by the parent, such as blocking selected apps or enforcing app-usage rules. The app does not autonomously take actions outside those parent-defined rules.
```

### 4.4 Package visibility / QUERY_ALL_PACKAGES

#### Use this answer only if you keep the permission
```text
The app provides parental control and child safety monitoring on the child device. To apply app blocking and usage monitoring across any app installed or opened by the child, the app requires awareness of arbitrary installed and foreground apps on the device. This broad package visibility is used only for the app's core parental-control functionality and not for analytics, advertising, or market intelligence.
```

#### Reviewer note
- This is still a high-risk permission.
- If Google Play rejects this rationale, the fallback should be a `play` flavor that removes `QUERY_ALL_PACKAGES`.

### 4.5 Usage access rationale
```text
The app uses Usage Access on the child device to measure which apps are used and for how long. This supports the parental-control features shown to the parent, including screen-time review and rule-based app management.
```

## 5. Privacy policy alignment checklist

The privacy policy must explicitly say:
- what location data is collected
- that location can be collected in the background
- that location is shared only with the parent or assigned guardian in the same family
- that Accessibility is used to detect which app is open on the child device
- that Accessibility is not used to read passwords, messages, or typed content
- that Usage Access is used to measure app usage duration and app-open activity on the child device
- whether contacts are accessed only when the parent chooses to import a phone number from the device address book
- whether media access is only for profile or account images
- that data is not used for ads if that is your actual product behavior

## 6. Video review checklist

### Target duration
- 30 seconds or less per declared feature where possible

### Background location review video
1. Open app on child device.
2. Show the in-app disclosure screen for location/background location.
3. Tap continue and show the Android runtime permission prompt.
4. Enable child tracking / Safe Zone / Safe Route.
5. Close or background the app.
6. Demonstrate that the parent device receives:
   - live child location update
   - Safe Zone alert or tracking update
7. End with the parent view showing the safety feature actually working.

### Accessibility review video
1. Open app on child device.
2. Show the in-app disclosure screen for Accessibility.
3. Open Accessibility settings and enable the service.
4. Open one app that should be allowed.
5. Open one app that should be blocked by a parent-defined rule.
6. Show the result in-app:
   - block event
   - related parent notification or control outcome
7. Make sure the video does not imply the app reads passwords, messages, or arbitrary text content.

### Usage access review video
1. Open app on child device.
2. Show the in-app disclosure for Usage Access.
3. Open Usage Access settings and enable the permission.
4. Open several apps on the child device.
5. Return to the parent view and show screen-time or usage results.

## 7. Submission checklist

Before uploading to production:
1. Make sure manifest, store listing, privacy policy, and declaration form all describe the same core features.
2. Use the same feature names everywhere:
   - live child location
   - Safe Zone alerts
   - Safe Route
   - SOS
   - app usage monitoring
   - app blocking
3. Do not mention ads anywhere if location is not actually used for ads.
4. Verify that the review video exactly matches the current production build.
5. Verify that testing credentials are valid and non-expired.
6. If Google asks about package visibility, be prepared to justify `QUERY_ALL_PACKAGES` separately or remove it in a Play-specific flavor.
