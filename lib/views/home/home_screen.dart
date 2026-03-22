import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/alert_service.dart';
import '../../viewmodels/auth_vm.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final authVm = context.read<AuthVM>();
    final confirm = await AlertService.confirm(
      title: l10n.logoutTitle,
      message: l10n.confirmLogoutQuestion,
    );

    if (!confirm) return;

    await authVm.logout();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authVM = context.watch<AuthVM>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_care, size: 64),
            const SizedBox(height: 16),
            Text(
              '${l10n.homeGreeting} 👋',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (authVM.user?.email != null) Text(authVM.user!.email!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: navigate to child list screen
              },
              child: Text(l10n.homeManageChildButton),
            ),
          ],
        ),
      ),
    );
  }
}
