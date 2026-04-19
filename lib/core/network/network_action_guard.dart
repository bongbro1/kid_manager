import 'package:flutter/material.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/core/network/app_network_error_mapper.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/viewmodels/app_connectivity_vm.dart';
import 'package:provider/provider.dart';

Future<T?> runGuardedNetworkAction<T>(
  BuildContext context, {
  required Future<T> Function() action,
  String? fallbackMessage,
  bool showError = true,
}) async {
  final l10n = AppLocalizations.of(context);
  final message = fallbackMessage ?? l10n.appNetworkActionFailed;
  final connectivity = context.read<AppConnectivityVm>();

  if (connectivity.isOffline) {
    if (showError) {
      AlertService.showSnack(
        fallbackMessage ?? l10n.appRetryWhenOnline,
        isError: true,
      );
    }
    return null;
  }

  try {
    return await action();
  } catch (error) {
    final networkError = AppNetworkErrorMapper.normalize(
      error,
      fallbackMessage: message,
    );
    if (networkError == null) {
      rethrow;
    }

    if (showError) {
      AlertService.showSnack(networkError.message ?? message, isError: true);
    }
    return null;
  }
}

Future<bool> runGuardedNetworkVoidAction(
  BuildContext context, {
  required Future<void> Function() action,
  String? fallbackMessage,
  bool showError = true,
}) async {
  final l10n = AppLocalizations.of(context);
  final message = fallbackMessage ?? l10n.appNetworkActionFailed;
  final connectivity = context.read<AppConnectivityVm>();

  if (connectivity.isOffline) {
    if (showError) {
      AlertService.showSnack(
        fallbackMessage ?? l10n.appRetryWhenOnline,
        isError: true,
      );
    }
    return false;
  }

  try {
    await action();
    return true;
  } catch (error) {
    final networkError = AppNetworkErrorMapper.normalize(
      error,
      fallbackMessage: message,
    );
    if (networkError == null) {
      rethrow;
    }

    if (showError) {
      AlertService.showSnack(networkError.message ?? message, isError: true);
    }
    return false;
  }
}
