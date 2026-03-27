import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

class AppWheelTimePicker {
  static Future<TimeOfDay?> show(
    BuildContext context, {
    required String title,
    TimeOfDay? initial,
    int minuteInterval = 1,
  }) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final actionColor = scheme.primary;
    final sheetColor = theme.bottomSheetTheme.backgroundColor ?? scheme.surface;
    final titleColor = scheme.onSurface;
    final dividerColor = scheme.outline.withOpacity(
      theme.brightness == Brightness.dark ? 0.55 : 0.2,
    );
    final handleColor = scheme.onSurface.withOpacity(
      theme.brightness == Brightness.dark ? 0.22 : 0.12,
    );
    final shadowColor = Colors.black.withOpacity(
      theme.brightness == Brightness.dark ? 0.28 : 0.12,
    );
    final init = initial ?? TimeOfDay.now();
    var temp = DateTime(2000, 1, 1, init.hour, init.minute);
    TimeOfDay? result;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 18,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                // handle
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 10),

                // header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          foregroundColor: actionColor,
                        ),
                        child: Text(l10n.cancelButton),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          result = TimeOfDay(
                            hour: temp.hour,
                            minute: temp.minute,
                          );
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: actionColor,
                        ),
                        child: Text(
                          l10n.cupertinoTimePickerDoneButton,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: dividerColor),

                // picker
                SizedBox(
                  height: 220,
                  child: MediaQuery(
                    // giữ text không bị scale lạ trên Android
                    data: MediaQuery.of(
                      ctx,
                    ).copyWith(textScaler: const TextScaler.linear(1.0)),
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: theme.brightness,
                        primaryColor: actionColor,
                        scaffoldBackgroundColor: sheetColor,
                        barBackgroundColor: sheetColor,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(color: titleColor),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        backgroundColor: sheetColor,
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: temp,
                        use24hFormat: true, // ✅ 00:00 - 23:59
                        minuteInterval: minuteInterval,
                        onDateTimeChanged: (dt) => temp = dt,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    return result;
  }
}
