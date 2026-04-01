import 'package:flutter/material.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/setting_pages/add_account_screen.dart';
import 'package:provider/provider.dart';

class NoChildScreen extends StatelessWidget {
  const NoChildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 16,
      regular: 24,
    );
    final actor = context.select<UserVm, AppUser?>((vm) => vm.actorSnapshot);
    final canAddAccount =
        actor != null &&
        context.read<AccessControlService>().canAddManagedAccounts(
          actor: actor,
        );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),

              /// TITLE
                      Text(
                        l10n.parentDashboardNoDeviceTitle,
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 12),

              /// SUBTITLE
                      Text(
                        l10n.parentDashboardNoDeviceSubtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 32),

                      if (canAddAccount) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddAccountScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              l10n.parentDashboardAddDeviceButton,
                              style: textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

              /// TEXT BUTTON
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/how-it-works');
                        },
                        child: Text(
                          l10n.parentDashboardHowItWorksButton,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
