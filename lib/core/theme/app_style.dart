import 'package:flutter/material.dart';

class AppStyle {
  static const Color primary = Color(0xff173b67);
  static const Color accent = Color(0xff8ea8cb);
  static const Color surfaceTint = Color(0xffedf3fa);
  static const Color scaffold = Color(0xfff4f7fb);
  static const Color textPrimary = Color(0xff173b67);
  static const Color textMuted = Color(0xff6b7280);

  static PreferredSizeWidget primaryAppBar(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
  }) {
    return AppBar(
      backgroundColor: primary,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 74,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: actions,
    );
  }

  static BoxDecoration cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: primary.withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
