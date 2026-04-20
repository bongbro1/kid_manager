import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/user/user_subscription.dart';
import 'package:kid_manager/viewmodels/subscription_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/setting_pages/widgets/subscription_widgets.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_scroll_effects.dart';
import 'package:provider/provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = _resolveCurrentUid(context);
      if (uid.isEmpty) return;
      context.read<SubscriptionVM>().initialize(uid);
    });
  }

  String _resolveCurrentUid(BuildContext context) {
    final profileUid = context.read<UserVm>().profile?.id.trim();
    if (profileUid != null && profileUid.isNotEmpty) {
      return profileUid;
    }
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  Future<void> _submitSelection(BuildContext context, SubscriptionVM vm) async {
    final l10n = AppLocalizations.of(context);
    final uid = _resolveCurrentUid(context);
    if (uid.isEmpty) {
      _showSnackBar(context, l10n.subscriptionUserIdNotFound);
      return;
    }

    if (vm.selectedPlan == null) {
      _showSnackBar(context, l10n.subscriptionSelectPlanPrompt);
      return;
    }

    final success = await vm.submitSelectedPlan();
    if (!context.mounted) return;

    if (!success) {
      final error = vm.error;
      if (error != null && error.isNotEmpty) {
        _showSnackBar(context, error);
      }
      return;
    }

    final message = switch (vm.registrationStatus) {
      SubscriptionRegistrationStatus.registered =>
        l10n.subscriptionRegisteredSuccess,
      SubscriptionRegistrationStatus.contactRequested =>
        l10n.subscriptionContactRequestSuccess,
      _ => null,
    };

    if (message != null) {
      _showSnackBar(context, message);
    }
    vm.clearRegistrationStatus();
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SubscriptionVM>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typography = theme.appTypography;
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 16,
      regular: 20,
    );
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final localizedPlans = vm.plans
        .map((plan) => LocalizedPlanViewData.fromPlan(plan, l10n))
        .toList(growable: false);

    final selectedPlanData = vm.selectedPlan == null
        ? null
        : LocalizedPlanViewData.fromPlan(vm.selectedPlan!, l10n);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: scheme.onSurface,
          ),
        ),
        title: Text(
          l10n.subscriptionTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.screenTitle.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          14,
          horizontalPadding,
          bottomInset + 16,
        ),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(color: scheme.outline.withValues(alpha: 0.10)),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: AppButton(
          height: 50,
          text: selectedPlanData?.isContactOnly == true
              ? l10n.subscriptionContactNow
              : l10n.subscriptionRegisterNow,
          loading: vm.isSubmitting,
          onPressed: vm.selectedPlan == null || vm.isLoading
              ? null
              : () => _submitSelection(context, vm),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          fontSize: typography.body.fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.32, 1],
            colors: [
              scheme.primary.withValues(alpha: 0.07),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: AppScrollEffects.physics,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            bottomInset + 110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppScrollReveal(
                index: 0,
                child: SubscriptionHeroCard(
                  eyebrow: l10n.subscriptionHeroEyebrow,
                  title: l10n.subscriptionHeroTitle,
                  description: l10n.subscriptionHeroDescription,
                  currentPlanLabel: _resolveCurrentPlanLabel(
                    l10n,
                    localizedPlans,
                    vm.subscription,
                  ),
                  currentStatusLabel: _resolveSubscriptionStatusLabel(
                    l10n,
                    vm.subscription,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AppScrollReveal(
                index: 1,
                child: SubscriptionSectionHeader(
                  eyebrow: l10n.subscriptionSectionEyebrow,
                  title: l10n.subscriptionSectionTitle,
                  description: l10n.subscriptionSectionDescription,
                ),
              ),
              if (vm.error != null && vm.error!.isNotEmpty) ...[
                const SizedBox(height: 14),
                AppScrollReveal(
                  index: 2,
                  child: InlineErrorCard(message: vm.error!),
                ),
              ],
              const SizedBox(height: 14),
              if (vm.isLoading && localizedPlans.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (localizedPlans.isEmpty)
                AppScrollReveal(
                  index: 3,
                  child: EmptyPlansCard(
                    message: l10n.subscriptionLoadPlansEmpty,
                    retryLabel: l10n.subscriptionRetryButton,
                    onRetry: () => context.read<SubscriptionVM>().loadPlans(),
                  ),
                )
              else
                ...localizedPlans.indexed.map((entry) {
                  final index = entry.$1;
                  final plan = entry.$2;
                  final isSelected = vm.selectedPlan?.id == plan.id;
                  final isCurrentPlan =
                      _resolveCurrentPlanId(vm.subscription) == plan.id;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == localizedPlans.length - 1 ? 0 : 14,
                    ),
                    child: AppScrollReveal(
                      index: index + 2,
                      child: SelectablePlanCard(
                        plan: plan,
                        isSelected: isSelected,
                        isCurrentPlan: isCurrentPlan,
                        onTap: () =>
                            context.read<SubscriptionVM>().selectPlan(plan.id),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 28),
              AppScrollReveal(
                index: localizedPlans.length + 3,
                child: SubscriptionSectionHeader(
                  eyebrow: l10n.subscriptionSupportEyebrow,
                  title: l10n.subscriptionSupportTitle,
                  description: l10n.subscriptionSupportDescription,
                ),
              ),
              const SizedBox(height: 14),
              AppScrollReveal(
                index: localizedPlans.length + 4,
                child: SupportCard(
                  emailLabel: l10n.subscriptionSupportEmailLabel,
                  phoneLabel: l10n.subscriptionSupportPhoneLabel,
                  hoursLabel: l10n.subscriptionSupportHoursLabel,
                  hoursValue: l10n.subscriptionSupportHoursValue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveCurrentPlanId(SubscriptionInfo? subscription) {
    final productId = subscription?.productId?.trim().toLowerCase() ?? '';
    if (productId.isNotEmpty) {
      return productId;
    }

    return switch (subscription?.effectivePlan) {
      SubscriptionPlan.pro => 'premium',
      SubscriptionPlan.free => 'basic',
      null => '',
    };
  }

  String _resolveCurrentPlanLabel(
    AppLocalizations l10n,
    List<LocalizedPlanViewData> plans,
    SubscriptionInfo? subscription,
  ) {
    final planId = _resolveCurrentPlanId(subscription);
    if (planId.isEmpty) {
      return l10n.subscriptionCurrentPlanNone;
    }

    for (final plan in plans) {
      if (plan.id == planId) {
        return plan.title;
      }
    }

    return l10n.subscriptionCurrentPlanNone;
  }

  String _resolveCurrentStatusLabel(
    AppLocalizations l10n,
    SubscriptionInfo? subscription,
  ) {
    return switch (subscription?.status) {
      SubscriptionStatus.active => l10n.subscriptionStatusActive,
      SubscriptionStatus.trial => l10n.subscriptionStatusTrial,
      SubscriptionStatus.expired => l10n.subscriptionStatusExpired,
      SubscriptionStatus.canceled => l10n.subscriptionStatusCanceled,
      SubscriptionStatus.paymentFailed => l10n.subscriptionStatusPaymentFailed,
      null => '—',
    };
  }

  String _resolveSubscriptionStatusLabel(
    AppLocalizations l10n,
    SubscriptionInfo? subscription,
  ) {
    if (subscription != null) {
      return _resolveCurrentStatusLabel(l10n, subscription);
    }

    return switch (subscription?.status) {
      SubscriptionStatus.active => l10n.subscriptionStatusActive,
      SubscriptionStatus.trial => l10n.subscriptionStatusTrial,
      SubscriptionStatus.expired => l10n.subscriptionStatusExpired,
      SubscriptionStatus.canceled => l10n.subscriptionStatusCanceled,
      SubscriptionStatus.paymentFailed => l10n.subscriptionStatusPaymentFailed,
      null => l10n.subscriptionStatusUnknown,
    };
  }
}
