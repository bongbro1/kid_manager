import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_onboarding_flow.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:provider/provider.dart';

class FlashScreen extends StatefulWidget {
  const FlashScreen({super.key});

  @override
  State<FlashScreen> createState() => _FlashScreenState();
}

class _FlashScreenState extends State<FlashScreen> {
  bool _showPermissionFlow = false;
  bool _permissionsDone = false;

  void _onContinue() {
    context.read<SessionVM>().finishSplash();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    final appVM = context.read<AppManagementVM>();
    appVM.loadAndSeedApp();
    if (!mounted) return;
    setState(() => _showPermissionFlow = true);
  }

  @override
  Widget build(BuildContext context) {
    final appVM = context.watch<AppManagementVM>();
    final l10n = AppLocalizations.of(context);

    if (appVM.loading) return LoadingOverlay();

    if (_showPermissionFlow && !_permissionsDone) {
      return PermissionOnboardingFlow(
        onFinished: () {
          if (!mounted) return;
          setState(() {
            _permissionsDone = true;
          });
        },
      );
    }

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
                    SizedBox(
                      width: 241,
                      child: Text(
                        l10n.flashWelcomeTitle,
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
                    SizedBox(
                      width: 241,
                      child: Text(
                        l10n.flashWelcomeSubtitle,
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
            Padding(
              padding: const EdgeInsets.only(bottom: 40, right: 53, top: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _onContinue,
                  child: SizedBox(
                    width: 41,
                    child: Text(
                      l10n.flashNext,
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
