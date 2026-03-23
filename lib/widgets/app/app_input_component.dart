import 'package:flutter/material.dart';

class AppLabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final double? width;
  final TextEditingController controller;

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
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 55,
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              readOnly: readOnly,
              onTap: onTap,
              keyboardType: keyboardType,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withOpacity(0.4),
                ),

                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,

                filled: true,
                fillColor: scheme.surface,

                contentPadding: const EdgeInsets.symmetric(horizontal: 16),

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
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = width ?? constraints.maxWidth;

        return SizedBox(
          width: effectiveWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 65,
                child: DropdownMenu<T>(
                  width: effectiveWidth,
                  alignmentOffset: const Offset(0, 10),
                  initialSelection: value,
                  enabled: enabled,
                  onSelected: onChanged,
                  dropdownMenuEntries: items,
                  hintText: hint,
                  leadingIcon: prefixIcon,
                  trailingIcon: suffixIcon,
                  inputDecorationTheme: InputDecorationTheme(
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: scheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(scheme.surface),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
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

  const AppLabeledCheckbox({
    super.key,
    required this.label,
    required this.text,
    required this.value,
    required this.onChanged,
    this.width,
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
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

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
