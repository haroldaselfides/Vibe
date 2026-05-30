import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/background_shape.dart';
import '../widgets/social_login_buttons.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Replace with your actual Google Client ID from Google Cloud Console
  static const String _googleClientId =
      'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _authService = AuthService(googleClientId: _googleClientId);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLoginSuccess() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Dark header uses inkEspresso — the deep editorial dark, not wabi charcoal
        decoration: const BoxDecoration(
          color: AppTheme.inkEspresso,
        ),
        child: Stack(
          children: [
            // Background shape (lotus illustration)
            const BackgroundShape(),

            SafeArea(
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      // Space for the illustrated header area
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                        ),
                      ),

                      // White-canvas panel
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.inkBgMain, // aged ivory
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(36),
                              topRight: Radius.circular(36),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Drag handle
                              Center(
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.inkUmber
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),

                              // Header
                              const Center(
                                child: Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.inkEspresso,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Center(
                                child: Text(
                                  'Login to your account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.inkUmber,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Email
                              _buildLabel('Email'),
                              const SizedBox(height: 8),
                              _buildEmailField(),
                              const SizedBox(height: 16),

                              // Password
                              _buildLabel('Password'),
                              const SizedBox(height: 8),
                              _buildPasswordField(),
                              const SizedBox(height: 10),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    // Navigator.of(context).pushNamed('/forgot-password');
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.inkTerracotta,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Login button — terracotta CTA
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.inkTerracotta,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Log In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: AppTheme.inkUmber
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: Text(
                                      'or continue with',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.inkUmber
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: AppTheme.inkUmber
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Social buttons
                              SocialLoginButtons(
                                googleClientId: _googleClientId,
                                onSuccess: _handleLoginSuccess,
                              ),
                              const SizedBox(height: 24),

                              // Sign Up link
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context)
                                      .pushNamed('/signup'),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Don't have an account? ",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.inkUmber
                                            .withValues(alpha: 0.8),
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'Sign Up',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.inkTerracotta,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Extend background to bottom
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Container(color: AppTheme.inkBgMain),
                      ),
                    ],
                  ),

                  // Back button
                  Positioned(
                    top: 8,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.inkEspresso,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'Enter your email',
        prefixIcon: const Icon(Icons.email_outlined,
            color: AppTheme.inkUmber, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppTheme.inkUmber.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppTheme.inkUmber.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.inkTerracotta, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.inkCanvas, // warm canvas fill
        hintStyle: const TextStyle(color: AppTheme.inkUmber, fontSize: 14),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock_outline,
            color: AppTheme.inkUmber, size: 20),
        suffixIcon: GestureDetector(
          onTap: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppTheme.inkUmber,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppTheme.inkUmber.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppTheme.inkUmber.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.inkTerracotta, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.inkCanvas,
        hintStyle: const TextStyle(color: AppTheme.inkUmber, fontSize: 14),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome back ${user.email}!')),
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid email or password'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}