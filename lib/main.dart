import 'package:flutter/material.dart';
import 'core/theme/app_style.dart';
import 'core/loading/loading_overlay.dart';
import 'Screens/homeScreen.dart';
import 'Screens/splash_screen.dart';
import 'Screens/login_screen.dart';
import 'Screens/sign_up.dart';
import 'Screens/creatNewPass.dart';
import 'Screens/otp_verification_screen.dart';
import 'Screens/verification_screen.dart';
import 'Screens/forgot_password_screen.dart';
import 'Screens/password_success_screen.dart';
import 'Screens/details_screen.dart';
import 'Screens/add_ad_screen.dart';
import 'Screens/admin_dashboard_screen.dart';
import 'Screens/my_ads_screen.dart';
import 'Screens/profile_screen_new.dart';
import 'Screens/EditAdScreen.dart';
import 'Screens/chat_list_screen.dart';
import 'Screens/notifications_screen.dart';
import 'Screens/favorites_screen.dart';
import 'Screens/my_pets_screen.dart';

void main() {
  runApp(const LoginSignupUI());
}

class LoginSignupUI extends StatelessWidget {
  const LoginSignupUI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      theme: ThemeData(
        scaffoldBackgroundColor: AppStyle.scaffold,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppStyle.primary,
          primary: AppStyle.primary,
          secondary: AppStyle.accent,
          surface: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppStyle.primary,
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: const TextStyle(
            color: AppStyle.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          contentTextStyle: const TextStyle(
            color: AppStyle.textMuted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppStyle.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      builder: (context, child) {
        return GlobalLoadingOverlay(
          child: child!,
        );
      },
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUp(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/verify': (context) => const VerificationScreen(),
        '/otp': (context) => const OtpVerificationScreen(),
        '/newpass': (context) => const Creatnewpass(),
        '/home': (context) => const HomeScreen(),
        '/pass-success': (context) => const PasswordSuccessScreen(),
        '/details': (context) => const DetailsScreen(),
        '/add': (context) => const AddAdScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/myAds': (context) => const MyAdsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-ad': (context) => const EditAdScreen(),
        '/chats': (context) => const ChatListScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/pets': (context) => const MyPetsScreen(),
      },
    );
  }
}
