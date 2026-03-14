import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/app/app_icon.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ===== HEADER =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: AppIcon(
                        path: 'assets/icons/back.svg',
                        type: AppIconType.svg,
                        size: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.aboutAppTitle,
                        style: const TextStyle(
                          color: Color(0xFF222B45),
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  /// giữ title ở center thật
                  const SizedBox(width: 44),
                ],
              ),
            ),
            const SizedBox(height: 12),

            /// ===== CONTENT =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      l10n.aboutAppName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.aboutAppVersionLabel('1.0.0'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4C4C4C),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.aboutAppDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Text(
                        l10n.aboutAppCopyright,
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
