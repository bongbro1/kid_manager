import 'package:flutter/material.dart';

class AppLabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final double? width;
  final TextEditingController controller;
  final double minFieldHeight;
  final double labelBottomSpacing;
  final EdgeInsetsGeometry? contentPadding;

  final bool obscureText;
  final bool readOnly;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final VoidCallback? onTap;
  final TextInputType? keyboardType;

  const AppLabeledTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.width,
    this.minFieldHeight = 55,
    this.labelBottomSpacing = 8,
    this.contentPadding,
    this.obscureText = false,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: width ?? double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: labelBottomSpacing),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),

          SizedBox(height: labelBottomSpacing),

          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minFieldHeight),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              readOnly: readOnly,
              onTap: onTap,
              keyboardType: keyboardType,
              minLines: 1,
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),

                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,

                filled: true,
                fillColor: scheme.surface,

                contentPadding:
                    contentPadding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: scheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppLabeledDropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final double? width;
  final double? fieldHeight;
  final double minFieldHeight;
  final double labelBottomSpacing;
  final EdgeInsetsGeometry? contentPadding;

  final T? value;
  final List<DropdownMenuEntry<T>> items;
  final ValueChanged<T?>? onChanged;

  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;

  const AppLabeledDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    this.width,
    this.fieldHeight,
    this.minFieldHeight = 65,
    this.labelBottomSpacing = 8,
    this.contentPadding,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dropdownTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w400,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = width ?? constraints.maxWidth;

        return SizedBox(
          width: effectiveWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: labelBottomSpacing),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: labelBottomSpacing),
              Builder(
                builder: (context) {
                  final dropdown = DropdownMenu<T>(
                    width: effectiveWidth,
                    menuHeight: 260,
                    alignmentOffset: const Offset(0, 4),
                    requestFocusOnTap: false,
                    enableSearch: false,
                    initialSelection: value,
                    enabled: enabled,
                    onSelected: onChanged,
                    dropdownMenuEntries: items,
                    hintText: hint,
                    leadingIcon: prefixIcon,
                    trailingIcon:
                        suffixIcon ??
                        Icon(
                          Icons.expand_more_rounded,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                    selectedTrailingIcon:
                        suffixIcon ??
                        Icon(
                          Icons.expand_less_rounded,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                    textStyle: dropdownTextStyle,
                    inputDecorationTheme: InputDecorationTheme(
                      isDense: true,
                      constraints: fieldHeight != null
                          ? BoxConstraints.tightFor(height: fieldHeight)
                          : null,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: scheme.surface,
                      contentPadding:
                          contentPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: scheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: scheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: scheme.primary,
                          width: 1.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(scheme.surface),
                      elevation: const WidgetStatePropertyAll(3),
                      side: WidgetStatePropertyAll(
                        BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 6),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );

                  if (fieldHeight != null) {
                    return SizedBox(height: fieldHeight, child: dropdown);
                  }

                  return ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minFieldHeight),
                    child: dropdown,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class AppLabeledCheckbox extends StatelessWidget {
  final String label;
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double? width;
  final double labelBottomSpacing;

  const AppLabeledCheckbox({
    super.key,
    required this.label,
    required this.text,
    required this.value,
    required this.onChanged,
    this.width,
    this.labelBottomSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: labelBottomSpacing),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: labelBottomSpacing),

          InkWell(
            onTap: () => onChanged(!value),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Row(
              children: [
                Checkbox(
                  value: value,
                  onChanged: (_) => onChanged(!value),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: scheme.outline),
                  activeColor: scheme.primary,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
