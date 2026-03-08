import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';

// Your SVG Content Definition
const String kandyGoLogoSvg = '''
<svg width="500" height="500" viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg">

<!-- Outer Rounded Square -->
<rect x="130" y="65" width="240" height="240" rx="55" fill="url(#paint0_linear_1_2)"/>

<!-- K SHADOW OUTLINE (thin + subtle) -->
<path d="M176 148V276H219.5V224.5L285.5 276H340L253 206L340 116H283L176 214.5V148H176Z"
      stroke="rgba(0,0,0,0.25)"
      stroke-width="0"
      stroke-linejoin="round"
      fill="none"/>

<!-- K MAIN (gradient-filled) -->
<path d="M176 148V276H219.5V224.5L285.5 276H340L253 206L340 116H283L176 214.5V148H176Z"
      fill="url(#paint1_linear_1_2)"/>

<!-- GLOSSY HIGHLIGHT -->
<path d="M176 148V276H219.5V224.5L285.5 276H340L253 206L340 116H283L176 214.5V148H176Z"
      fill="none"
      stroke="url(#kHighlight)"
      stroke-width="0"
      stroke-linejoin="round"
      stroke-opacity="0.65"/>

<!-- Circle Background -->
<path d="M320 166C320 188.091 302.091 206 280 206C257.909 206 240 188.091 240 166C240 143.909 257.909 126 280 126C302.091 126 320 143.909 320 166Z" fill="white"/>

<!-- Inner Circle -->
<path d="M280 186C291.046 186 300 177.046 300 166C300 154.954 291.046 146 280 146C268.954 146 260 154.954 260 166C260 177.046 268.954 186 280 186Z"
      fill="url(#paint2_linear_1_2)"/>

<!-- Text -->
<text x="250" y="400" text-anchor="middle" font-family="Arial, sans-serif" font-weight="bold" font-size="64" fill="#003399">
    Kandy Go
</text>

<defs>

<!-- Gloss Highlight Gradient -->
<linearGradient id="kHighlight" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="white" stop-opacity="0.85"/>
    <stop offset="40%" stop-color="white" stop-opacity="0"/>
</linearGradient>

<!-- THREE-COLOR GRADIENTS -->
<linearGradient id="paint0_linear_1_2" x1="130" y1="65" x2="370" y2="305" gradientUnits="userSpaceOnUse">
    <stop offset="0%" stop-color="#001F6B"/>
    <stop offset="50%" stop-color="#0099FF"/>
    <stop offset="100%" stop-color="#66FFE3"/>
</linearGradient>

<linearGradient id="paint1_linear_1_2" x1="176" y1="116" x2="340" y2="276">
    <stop offset="0%" stop-color="#001F6B"/>
    <stop offset="50%" stop-color="#0099FF"/>
    <stop offset="100%" stop-color="#66FFE3"/>
</linearGradient>

<linearGradient id="paint2_linear_1_2" x1="260" y1="146" x2="300" y2="186">
    <stop offset="0%" stop-color="#001F6B"/>
    <stop offset="50%" stop-color="#0099FF"/>
    <stop offset="100%" stop-color="#66FFE3"/>
</linearGradient>

</defs>
</svg>

''';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Use a StreamSubscription to listen for the initial auth state change
  late StreamSubscription<User?> _authSubscription;
  final Color customBlue = const Color.fromARGB(255, 6, 180, 233);

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to ensure navigation happens after the build phase finishes
    // and we introduce a small delay for the user to see the splash screen.
    Future.delayed(const Duration(milliseconds: 2000), () {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
      ) {
        _navigateToNextScreen(user);
        // Important: Stop listening immediately after the initial state is received
        // This prevents the splash screen from navigating again if the auth state changes later.
        _authSubscription.cancel();
      });
    });
  }

  @override
  void dispose() {
    // Crucial: Cancel the subscription when the widget is disposed
    _authSubscription.cancel();
    super.dispose();
  }

  void _navigateToNextScreen(User? user) {
    // Ensure we don't navigate if the widget is already disposed
    if (!mounted) return;

    Widget nextScreen;

    if (user != null && user.emailVerified) {
      // User is logged in and verified: Check if admin or regular user
      if (user.email == 'sanoadksano@gmail.com') {
        nextScreen = const AdminDashboardScreen();
      } else {
        nextScreen = const HomeScreen();
      }
    } else {
      // User is either logged out, or logged in but not verified: Go to Login
      nextScreen = const LoginScreen();
    }

    // Use pushReplacement to clear the stack and navigate
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    // Show the splash screen UI indefinitely until the stream resolves the state
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(kandyGoLogoSvg, width: 200, height: 200),
            const SizedBox(height: 50),
            CircularProgressIndicator(color: customBlue),
            const SizedBox(height: 10),
            const Text(
              "Checking session...",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
