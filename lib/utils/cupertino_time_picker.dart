import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppWheelTimePicker {
  static Future<TimeOfDay?> show(
    BuildContext context, {
    required String title,
    TimeOfDay? initial,
    Color primaryColor = const Color(0xFF3F7CFF),
    int minuteInterval = 1,
  }) async {
    TimeOfDay init = initial ?? TimeOfDay.now();
    DateTime temp = DateTime(2000, 1, 1, init.hour, init.minute);
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
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
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                const SizedBox(height: 10),

                // header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                        ),
                        child: const Text('Hủy'),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            decoration: TextDecoration.none, // ✅ chặn gạch chân
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          result = TimeOfDay(hour: temp.hour, minute: temp.minute);
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                        ),
                        child: const Text(
                          'Xong',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.black.withOpacity(0.08)),

                // picker
                SizedBox(
                  height: 220,
                  child: MediaQuery(
                    // giữ text không bị scale lạ trên Android
                    data: MediaQuery.of(ctx).copyWith(textScaler: const TextScaler.linear(1.0)),
                    child: CupertinoTheme(
                      data: CupertinoThemeData(primaryColor: primaryColor),
                      child: CupertinoDatePicker(
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