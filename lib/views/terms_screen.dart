import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/viewmodels/terms_vm.dart';
import 'package:provider/provider.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenScreenState();
}

class _TermsScreenScreenState extends State<TermsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<TermsVM>().loadTerms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<TermsVM>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: vm.isLoading
            ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
            : vm.terms == null
            ? Center(
                child: Text(
                  l10n.termsNoData,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              )
            : Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            padding: const EdgeInsets.all(8),
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),

                        Text(
                          l10n.termsTitle,
                          style: textTheme.titleLarge?.copyWith(
                            fontSize: Theme.of(
                              context,
                            ).appTypography.screenTitle.fontSize!,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vm.terms!.title,
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: colorScheme.onSurface.withOpacity(0.65),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.termsLastUpdated(vm.terms!.lastUpdated),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(
                                    0.65,
                                  ),
                                  fontSize: Theme.of(
                                    context,
                                  ).appTypography.sectionLabel.fontSize!,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Container(
                            height: 1,
                            color: colorScheme.outline.withOpacity(0.35),
                          ),

                          const SizedBox(height: 16),

                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                vm.terms!.content.trim(),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: Theme.of(
                                    context,
                                  ).appTypography.itemTitle.fontSize!,
                                  height: 1.7,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
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
