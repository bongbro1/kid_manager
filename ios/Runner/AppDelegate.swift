import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private struct LocalDayParts {
    let year: Int
    let month: Int
    let day: Int
  }

  private let fallbackTimeZone = "Asia/Ho_Chi_Minh"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let deviceTimeZoneChannel = FlutterMethodChannel(
        name: "device_timezone",
        binaryMessenger: controller.binaryMessenger
      )

      deviceTimeZoneChannel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result("Asia/Ho_Chi_Minh")
          return
        }

        switch call.method {
        case "getDeviceTimeZone":
          result(self.normalizeTimeZone(TimeZone.current.identifier, fallback: nil))

        case "normalizeTimeZone":
          let args = call.arguments as? [String: Any]
          let timeZone = args?["timeZone"] as? String
          let fallback = args?["fallbackTimeZone"] as? String
          result(self.normalizeTimeZone(timeZone, fallback: fallback))

        case "resolveDayKeyForTimestamp":
          let args = call.arguments as? [String: Any]
          let timestampMs = (args?["timestampMs"] as? NSNumber)?.int64Value ?? 0
          let timeZoneId = self.normalizeTimeZone(args?["timeZone"] as? String, fallback: nil)
          result(self.dayKeyForTimestamp(timestampMs: timestampMs, timeZoneId: timeZoneId))

        case "resolveLocalPartsForTimestamp":
          let args = call.arguments as? [String: Any]
          let timestampMs = (args?["timestampMs"] as? NSNumber)?.int64Value ?? 0
          let timeZoneId = self.normalizeTimeZone(args?["timeZone"] as? String, fallback: nil)
          let date = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000)
          let calendar = self.calendar(for: timeZoneId)
          let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
          )
          result([
            "dayKey": self.dayKeyForTimestamp(timestampMs: timestampMs, timeZoneId: timeZoneId),
            "minuteOfDay": ((components.hour ?? 0) * 60) + (components.minute ?? 0),
            "year": components.year ?? 0,
            "month": components.month ?? 0,
            "day": components.day ?? 0,
            "hour": components.hour ?? 0,
            "minute": components.minute ?? 0,
            "second": components.second ?? 0,
          ])

        case "resolveUtcRangeForLocalDay":
          let args = call.arguments as? [String: Any]
          guard
            let dayKey = args?["dayKey"] as? String,
            let parsedDay = self.parseDayKey(dayKey)
          else {
            result(
              FlutterError(
                code: "invalid-argument",
                message: "dayKey must be YYYY-MM-DD",
                details: nil
              )
            )
            return
          }

          let timeZoneId = self.normalizeTimeZone(args?["timeZone"] as? String, fallback: nil)
          let startMinute = (args?["startMinuteOfDay"] as? NSNumber)?.intValue ?? 0
          let endMinute = (args?["endMinuteOfDay"] as? NSNumber)?.intValue ?? 0
          let fromTs = self.utcTimestampForLocalMinute(
            day: parsedDay,
            minuteOfDay: startMinute,
            timeZoneId: timeZoneId,
            addTrailingMillis: false
          )
          let toTs = self.utcTimestampForLocalMinute(
            day: parsedDay,
            minuteOfDay: endMinute,
            timeZoneId: timeZoneId,
            addTrailingMillis: true
          )

          result([
            "fromTs": fromTs,
            "toTs": toTs,
          ])

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func calendar(for timeZoneId: String) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(identifier: timeZoneId) ?? TimeZone(identifier: fallbackTimeZone) ?? .current
    return calendar
  }

  private func normalizeTimeZone(_ raw: String?, fallback: String?) -> String {
    let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !trimmed.isEmpty && Self.isKnownTimeZone(trimmed) {
      return trimmed
    }

    let fallbackValue = fallback?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !fallbackValue.isEmpty && Self.isKnownTimeZone(fallbackValue) {
      return fallbackValue
    }

    return fallbackTimeZone
  }

  private static func isKnownTimeZone(_ value: String) -> Bool {
    if value == "UTC" {
      return true
    }
    return TimeZone.knownTimeZoneIdentifiers.contains(value)
  }

  private func dayKeyForTimestamp(timestampMs: Int64, timeZoneId: String) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000)
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = calendar(for: timeZoneId)
    formatter.timeZone = formatter.calendar.timeZone
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }

  private func parseDayKey(_ dayKey: String) -> LocalDayParts? {
    let parts = dayKey.split(separator: "-")
    guard parts.count == 3 else {
      return nil
    }
    guard
      let year = Int(parts[0]),
      let month = Int(parts[1]),
      let day = Int(parts[2])
    else {
      return nil
    }

    return LocalDayParts(year: year, month: month, day: day)
  }

  private func utcTimestampForLocalMinute(
    day: LocalDayParts,
    minuteOfDay: Int,
    timeZoneId: String,
    addTrailingMillis: Bool
  ) -> Int64 {
    let normalizedMinute = max(0, min((24 * 60) - 1, minuteOfDay))
    var components = DateComponents()
    components.year = day.year
    components.month = day.month
    components.day = day.day
    components.hour = normalizedMinute / 60
    components.minute = normalizedMinute % 60
    components.second = addTrailingMillis ? 59 : 0
    components.nanosecond = addTrailingMillis ? 999_000_000 : 0
    components.timeZone = TimeZone(identifier: timeZoneId) ?? TimeZone(identifier: fallbackTimeZone) ?? .current

    let calendar = self.calendar(for: timeZoneId)
    let date = calendar.date(from: components) ?? Date()
    return Int64(date.timeIntervalSince1970 * 1000)
  }
}
