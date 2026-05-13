import 'package:flutter/material.dart';

class CustomButtonWidget extends StatelessWidget {
  CustomButtonWidget({
    super.key,
    required this.w,
    required this.h,
    this.onPress,
    required this.text,
  });
  Function? onPress;
  final double w;
  final double h;
  String text;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xff24394a),
        padding: EdgeInsets.symmetric(horizontal: w * 0.37, vertical: h * 0.01),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: w * 0.04,
          color: Colors.white,
        ),
      ),
      onPressed: onPress as void Function()?,
    );
  }
}
