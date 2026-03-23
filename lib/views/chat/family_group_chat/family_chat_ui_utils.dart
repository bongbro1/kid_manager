import 'package:kid_manager/l10n/app_localizations.dart';

bool looksLikeOpaqueIdentifier(String raw) {
  final text = raw.trim();
  if (text.isEmpty || text.contains('@') || text.contains(' ')) {
    return false;
  }

  final normalized = text.replaceAll(RegExp(r'[-_]'), '');
  if (normalized.length < 16) {
    return false;
  }

  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(normalized);
  final hasDigit = RegExp(r'\d').hasMatch(normalized);
  final onlyKeyChars = RegExp(r'^[A-Za-z0-9]+$').hasMatch(normalized);
  return hasLetter && hasDigit && onlyKeyChars;
}

String sanitizeMemberLabel(String raw, AppLocalizations l10n) {
  final text = raw.trim();
  if (text.isEmpty || looksLikeOpaqueIdentifier(text)) {
    return l10n.familyChatMemberFallback;
  }
  return text;
}
