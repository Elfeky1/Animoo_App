import 'package:flutter/material.dart';

class CustomLabelWidget extends StatelessWidget {
  final String Label;
  const CustomLabelWidget({
    super.key,
    required this.Label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        Label,
        style: TextStyle(
          height: 0,
          fontSize: 16,
          color: Color(0xff24394a),
          fontWeight: FontWeight.bold,
          fontFamily: 'CustomFontFamily',
        ),
      ),
    );
  }
}
