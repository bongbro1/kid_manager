import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/viewmodels/app_init_vm.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';
import 'package:provider/provider.dart';

class FlashScreen extends StatefulWidget {
  const FlashScreen({super.key});

  @override
  State<FlashScreen> createState() => _FlashScreenState();
}

class _FlashScreenState extends State<FlashScreen> {
  bool _initCalled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initCalled) {
      _initCalled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AppInitVM>().init();
      });
    }
  }

  void _onContinue() {
    context.read<SessionVM>().finishSplash();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    debugPrint("🚀 Flash init start");

    final appVM = context.read<AppManagementVM>();

    try {
      await appVM.loadAndSeedApp();
    } catch (e, s) {
      debugPrint("❌ loadAndSeedApp ERROR: $e");
      debugPrint("$s");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LogoStack(),
                    const SizedBox(height: 24),

                    const SizedBox(
                      width: 241,
                      child: Text(
                        'Chào mừng đến với ứng dụng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF2D2B2E),
                          fontSize: 24,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          height: 1.42,
                          letterSpacing: -0.80,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const SizedBox(
                      width: 241,
                      child: Text(
                        'Ứng dụng theo dõi con cái',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF2D2B2E),
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          height: 1.71,
                          letterSpacing: -0.30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// ===== CONTINUE BUTTON =====
            Padding(
              padding: const EdgeInsets.only(bottom: 40, right: 53, top: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _onContinue,
                  child: const SizedBox(
                    width: 41,
                    child: Text(
                      'Tiếp',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color(0xFF2D2B2E),
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        height: 1.56,
                        letterSpacing: -0.40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoStack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 294.43,
      height: 267.16,
      child: Stack(
        alignment: Alignment.center,
        children: [Image.asset('assets/images/Illustration.png')],
      ),
    );
  }
}
