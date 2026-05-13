import 'package:flutter/material.dart';

class CustomFormFeildWidget extends StatelessWidget {
  final String FeildName;
  final String? Function(String?) validator;
  final bool isObscure;
  final Widget? suffixIcon;
  final TextEditingController? controller;

  const CustomFormFeildWidget({
    super.key,
    required this.validator,
    required this.FeildName,
    this.suffixIcon,
    this.isObscure = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: isObscure,
      cursorColor: const Color(0xff24394a),
      validator: validator,
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,

        hintText: 'Enter your $FeildName',

        suffixIcon: suffixIcon,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Colors.white, 
            width: 2,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Colors.white, 
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),

        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
