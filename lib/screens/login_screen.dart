import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'admin_dashboard_screen.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart'; // REQUIRED for rendering SVG

// --- SVG Content Definition ---
// This constant holds the SVG markup for the Kandy Go logo.
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
// ------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  // Define the custom blue color once for clean and consistent use
  final Color customBlue = const Color.fromARGB(255, 6, 180, 233);

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Enter your email address';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Enter your password';
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final auth = FirebaseAuth.instance;

    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // --- CRITICAL CHECK: Email Verification ---
      if (!userCredential.user!.emailVerified) {
        Fluttertoast.showToast(
          msg:
              'Please verify your email first. A verification link was sent to your inbox during sign-up.',
        );
        await auth.signOut(); // Log the user out immediately
        return;
      }
      // ------------------------------------------

      // Ensure user document exists in Firestore
      final userService = UserService();
      final user = userCredential.user!;
      final existingUser = await userService.getUserById(user.uid);

      if (existingUser == null) {
        // Create user profile if missing
        await userService.saveUser(AppUser(
          id: user.uid,
          email: user.email!,
          displayName: user.displayName ?? user.email!.split('@').first,
          role: user.email == 'sanoadksano@gmail.com' ? 'admin' : 'user',
          createdAt: DateTime.now(),
        ));
      }

      // Navigate based on user role
      if (mounted) {
        if (userCredential.user!.email == 'sanoadksano@gmail.com') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed. Please check your credentials.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        msg = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        msg = 'The email address is not valid.';
      }
      Fluttertoast.showToast(msg: msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Function to handle password reset
  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter your email address above to reset your password.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      Fluttertoast.showToast(
        msg:
            'Password reset link sent to ${_emailController.text.trim()}. Please check your email.',
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Could not send reset link.';
      if (e.code == 'user-not-found') {
        msg = 'No user found for that email.';
      }
      Fluttertoast.showToast(msg: msg);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- Dynamic Gradient Background ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  customBlue,
                  customBlue.withValues(alpha: 0.8),
                  const Color(0xFF001F6B),
                ],
              ),
            ),
          ),

          // --- Decorative Circles ---
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          // --- Login Content ---
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // LOGO
                            SvgPicture.string(
                              kandyGoLogoSvg,
                              height: 100,
                              width: 100,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Plan your next Kandy adventure',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Email Field
                            _buildGlassTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            _buildGlassTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              validator: _validatePassword,
                              obscureText: true,
                            ),

                            // Forgot Password Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Login Button
                            _loading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: customBlue,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 25),

                            // Sign Up Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'New here? ',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7)),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (_) => const SignUpScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: TextStyle(color: Colors.red.shade200),
      ),
      validator: validator,
    );
  }
}
