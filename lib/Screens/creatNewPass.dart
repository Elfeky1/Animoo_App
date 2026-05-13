import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:password_rule_check/password_rule_check.dart';

import '../core/theme/app_style.dart';
import '../services/api_service.dart';
import '../widgets/loading_overlay.dart';

class Creatnewpass extends StatefulWidget {
  const Creatnewpass({super.key});

  @override
  State<Creatnewpass> createState() => _CreatnewpassState();
}

class _CreatnewpassState extends State<Creatnewpass> {
  bool isObsecure = true;
  bool isObsecureConfirmPass = true;
  bool isLoading = false;

  String? password;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<PasswordRuleCheckState> _ruleCheckKey = GlobalKey();

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String email = args['email'];

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: AppStyle.scaffold,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              22,
              18,
              22,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppStyle.textPrimary,
                        ),
                      ),
                      Text(
                        'Back',
                        style: GoogleFonts.poppins(
                          color: AppStyle.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppStyle.primary, Color(0xff224f86)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppStyle.primary.withOpacity(0.16),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.password_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create new password',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Choose a strong password for $email.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: Colors.white.withOpacity(0.84),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppStyle.primary.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reset password',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppStyle.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your new password should be secure and easy for you to remember.',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: AppStyle.textMuted,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _label('New Password'),
                        const SizedBox(height: 8),
                        _passwordField(
                          controller: passwordController,
                          obscure: isObsecure,
                          toggle: () {
                            setState(() => isObsecure = !isObsecure);
                          },
                          validator: (value) {
                            if (_ruleCheckKey.currentState?.validate() == false) {
                              return 'Please add all required characters';
                            }
                            password = value;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        PasswordRuleCheck(
                          key: _ruleCheckKey,
                          controller: passwordController,
                          showIcon: true,
                          rowHeight: 28,
                          successColor: const Color(0xff30905b),
                          ruleSet: PasswordRuleSet(
                            minLength: 12,
                            uppercase: 1,
                            lowercase: 1,
                            digits: 1,
                            specialCharacters: 1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _label('Confirm Password'),
                        const SizedBox(height: 8),
                        _passwordField(
                          controller: confirmPasswordController,
                          obscure: isObsecureConfirmPass,
                          toggle: () {
                            setState(
                              () => isObsecureConfirmPass =
                                  !isObsecureConfirmPass,
                            );
                          },
                          validator: (value) {
                            if (value != password) {
                              return 'Password not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyle.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }

                                    setState(() => isLoading = true);

                                    final success =
                                        await ApiService.resetPassword(
                                      email,
                                      passwordController.text.trim(),
                                    );

                                    if (!mounted) return;

                                    setState(() => isLoading = false);

                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Password updated successfully',
                                          ),
                                        ),
                                      );

                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/pass-success',
                                        (route) => false,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Failed to reset password'),
                                        ),
                                      );
                                    }
                                  },
                            child: Text(
                              'Submit',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppStyle.textPrimary,
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      cursorColor: AppStyle.primary,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xfff7f9fc),
        hintText: '************',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppStyle.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.red),
        ),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: AppStyle.textPrimary,
          ),
        ),
      ),
    );
  }
}
