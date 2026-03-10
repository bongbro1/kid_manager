import 'package:flutter/material.dart';
import 'package:kid_manager/widgets/app/app_icon.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
                        path: "assets/icons/back.svg",
                        type: AppIconType.svg,
                        size: 16,
                      ),
                    ),
                  ),

                  const Expanded(
                    child: Center(
                      child: Text(
                        "Về ứng dụng",
                        style: TextStyle(
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
                  children: const [

                    SizedBox(height: 16),

                    Text(
                      'My Application',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Phiên bản: 1.0.0',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4C4C4C),
                      ),
                    ),

                    SizedBox(height: 20),

                    Text(
                      'Ứng dụng giúp quản lý tài khoản, theo dõi hoạt động '
                      'và cá nhân hóa trải nghiệm người dùng.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),

                    Spacer(),

                    Center(
                      child: Text(
                        '© 2026 My Company',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 14,
                        ),
                      ),
                    ),

                    SizedBox(height: 24),
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