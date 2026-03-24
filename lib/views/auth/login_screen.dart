import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/background/auth_runtime_manager.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/core/validators.dart';
import 'package:kid_manager/helpers/json_helper.dart';
import 'package:kid_manager/models/login_session.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/auth/dialog/phone_auth_dialog.dart';
import 'package:kid_manager/views/auth/forgot_pass_screen.dart';
import 'package:kid_manager/views/auth/signup_screen.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/auth/auth_text_field.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/core/storage_keys.dart';

import '../../core/alert_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool rememberPassword = false;

  String _resolveLoginErrorMessage(AppLocalizations l10n, String? errorKey) {
    switch (errorKey) {
      case 'accountNotFound':
        return l10n.accountNotFound;
      case 'accountNotActivated':
        return l10n.accountNotActivated;
      default:
        return l10n.authInvalidCredentials;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadRememberedLogin();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _onLoginPressed() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final storage = context.read<StorageService>();
    final l10n = AppLocalizations.of(context);

    if (email.isEmpty || password.isEmpty) {
      AlertService.showSnack(l10n.authEnterAllInfo, isError: true);
      return;
    }

    if (!Validators.isValidEmail(email)) {
      AlertService.showSnack(l10n.emailInvalid, isError: true);
      return;
    }

    final authVM = context.read<AuthVM>();
    final appVM = context.read<AppManagementVM>();
    final userVM = context.read<UserVm>();

    try {
      final cred = await authVM.login(email, password);
      if (!mounted) return;
      if (cred == null) {
        await NotificationDialog.show(
          context,
          type: DialogType.error,
          title: l10n.updateErrorTitle,
          message: _resolveLoginErrorMessage(l10n, authVM.error),
        );
        return;
      }

      final uid = cred.user!.uid;

      await storage.setString(StorageKeys.uid, uid);

      final profile = await userVM.loadProfile(uid: uid, caller: 'LoginScreen');
      if (profile == null) {
        await NotificationDialog.show(
          context,
          type: DialogType.error,
          title: l10n.updateErrorTitle,
          message: l10n.authUserProfileLoadFailed,
        );
        return;
      }

      await storage.setString(
        StorageKeys.role,
        profile.roleKey,
      );
      await storage.setString(StorageKeys.displayName, profile.name);

      final role = profile.role;
      final parentOwnerUid = role == UserRole.parent
          ? uid
          : (profile.parentUid ?? '').trim();

      if (parentOwnerUid.isNotEmpty) {
        await storage.setString(StorageKeys.parentId, parentOwnerUid);
      } else {
        await storage.remove(StorageKeys.parentId);
      }
      final managedChildIds = profile.managedChildIds
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (managedChildIds.isNotEmpty) {
        await storage.setStringList(
          StorageKeys.managedChildIds,
          managedChildIds,
        );
      } else {
        await storage.remove(StorageKeys.managedChildIds);
      }

      if (rememberPassword) {
        final session = LoginSession(email: email, uid: uid, remember: true);
        final raw = JsonHelper.encode(session.toJson());
        await storage.setString(StorageKeys.login_preference, raw);
      } else {
        await storage.remove(StorageKeys.login_preference);
      }

      debugPrint(
        'Running role: ${profile.roleKey}',
      );

      if (role == UserRole.child) {
        if (parentOwnerUid.isEmpty) {
          if (!mounted) return;
          await NotificationDialog.show(
            context,
            type: DialogType.error,
            title: l10n.updateErrorTitle,
            message: l10n.authUserProfileLoadFailed,
          );
          return;
        }
        AuthRuntimeManager.start(
          parentId: parentOwnerUid,
          displayName: profile.name,
        );
        await appVM.loadAndSeedApp();
        if (!mounted) return;
      } else {
        await AuthRuntimeManager.stop();
        if (!mounted) return;
      }

      FocusScope.of(context).unfocus();
    } catch (e, st) {
      debugPrint('Login error: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      NotificationDialog.show(
        context,
        type: DialogType.error,
        title: l10n.updateErrorTitle,
        message: l10n.authGenericError,
      );
    }
  }

  Future<void> _loadRememberedLogin() async {
    final storage = context.read<StorageService>();
    final raw = storage.getString(StorageKeys.login_preference);
    if (raw == null) return;

    try {
      final map = JsonHelper.decode(raw);
      final session = LoginSession.fromJson(map);

      if (!session.remember) return;
      if (!mounted) return; // ✅ check LẦN NỮA trước setState

      setState(() {
        _emailCtrl.text = session.email;
        rememberPassword = true;
      });
    } catch (e) {
      debugPrint('❌ Failed to load login session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthVM>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        SizedBox(
                          width: 216.85,
                          height: 203.40,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/Illustration.svg',
                              width: 203.40,
                              height: 203.40,
                            ),
                          ),
                        ),

                        const SizedBox(height: 21),

                        SizedBox(
                          width: 266,
                          child: Text(
                            l10n.authWelcomeBackTitle,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 24,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              height: 1.42,
                              letterSpacing: -0.19,
                            ),
                          ),
                        ),

                        SizedBox(
                          width: 266,
                          child: Text(
                            l10n.authLoginNowSubtitle,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 21),

                    AuthTextField(
                      controller: _emailCtrl,
                      hintText: l10n.authEnterEmailHint,
                      keyboardType: TextInputType.emailAddress,
                      prefixSvg: 'assets/icons/user.svg',
                    ),
                    const SizedBox(height: 1),
                    AuthTextField(
                      controller: _passwordCtrl,
                      hintText: l10n.authEnterPasswordHint,
                      keyboardType: TextInputType.text,
                      obscureText: true,
                      isPassword: true,
                      prefixSvg: 'assets/icons/lock.svg',
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 14, right: 14),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                rememberPassword = !rememberPassword;
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: rememberPassword
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      width: 2,
                                      color: rememberPassword
                                          ? colorScheme.primary
                                          : colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: rememberPassword
                                      ? Icon(
                                          Icons.check,
                                          size: 12,
                                          color: colorScheme.onPrimary,
                                        )
                                      : null,
                                ),

                                const SizedBox(width: 12),

                                Text(
                                  l10n.authRememberPassword,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                    letterSpacing: -0.12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              l10n.authForgotPassword,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                letterSpacing: -0.12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24.17),

                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppButton(
                            width: 360,
                            height: 60,
                            text: l10n.authLoginButton,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            onPressed: _onLoginPressed,
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 17),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: colorScheme.outline.withOpacity(0.4),
                            thickness: 0.83,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.authOr,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: colorScheme.outline.withOpacity(0.4),
                            thickness: 0.83,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 17),

                    Row(
                      children: [
                        Expanded(
                          child: _socialBtn(
                            'assets/icons/google.svg',
                            () => vm.loginWithGoogle(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _socialBtn(
                            'assets/icons/facebook.svg',
                            () => vm.loginWithFacebook(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _socialBtn(
                            'assets/icons/apple.svg',
                            () => vm.loginWithApple(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _socialBtn(
                            'assets/icons/mobile.svg',
                            () => PhoneAuthDialog.showPhoneDialog(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 61),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.authNoAccount,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 15,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.authSignUpInline,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.primary,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (vm.loading) const LoadingOverlay(),
      ],
    );
  }

  Widget _socialBtn(String iconPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEFF0F6)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: SvgPicture.asset(iconPath, width: 18, height: 18)),
      ),
    );
  }
}
