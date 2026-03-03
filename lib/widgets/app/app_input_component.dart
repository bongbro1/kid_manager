
import 'package:flutter/material.dart';

class AppLabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final double? width;
  final TextEditingController controller;

  const AppLabeledTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 55,
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF8F9BB3),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFEEEFF1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFEEEFF1)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppLabeledCheckbox extends StatelessWidget {
  final String label; // tiêu đề giống input (ở trên)
  final String text; // nội dung cạnh checkbox
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
    return SizedBox(
      width: width ?? 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // "box" đồng bộ với input
          InkWell(
            onTap: () => onChanged(!value),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: Row(
              children: [
                Transform.translate(
                  offset: const Offset(-4, 0), // 👈 chỉnh -2, -4, -6 tùy ý
                  child: Checkbox(
                    value: value,
                    onChanged: (v) => onChanged(v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: Color(0xFFEEEFF1)),
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
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
