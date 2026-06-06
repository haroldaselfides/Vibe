import 'package:flutter/material.dart';
import '../theme/new_app_theme.dart';
import '../theme/app_typography.dart';
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
        decoration: const BoxDecoration(
          color: AppTheme.inkEspresso,
        ),
        child: Stack(
          children: [
            // Background shape (lotus illustration)
            const BookBackgroundShape(),

            SafeArea(
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      // Space for the illustrated header area
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.33,
                        ),
                      ),

                      // White-canvas panel
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor, // aged ivory
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          // ↑ Fixed: closing ) was misplaced in the original,
                          //   leaving `child:` outside the Container.
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Drag handle
                                Center(
                                  child: Container(
                                    width: 36,
                                    height: 4,
                                    margin:
                                        const EdgeInsets.only(bottom: 24),
                                    decoration: BoxDecoration(
                                      color: AppTheme.inkUmber
                                          .withValues(alpha: 0.2),
                                      borderRadius:
                                          BorderRadius.circular(2),
                                    ),
                                  ),
                                ),

                                // Header — uses new headingLg (DM Serif Display 30)
                                Center(
                                  child: Text(
                                    'Welcome Back',
                                    style: AppTypography.headingLg.copyWith(
                                      color: AppTheme.inkEspresso,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Sub-header — uses new bodyMd (Manrope 14)
                                Center(
                                  child: Text(
                                    'Login to your account',
                                    style: AppTypography.bodyMd.copyWith(
                                      color: AppTheme.inkUmber
                                          .withValues(alpha: 0.8),
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

                                // Forgot Password — uses new labelSm (Manrope 10 semi-bold)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Navigator.of(context).pushNamed('/forgot-password');
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppTheme.inkTerracotta,
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
                                    onPressed:
                                        _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.inkMaroon,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Log In',
                                            // Uses bodyLg weight as base; overrides
                                            // to white for contrast on dark button
                                            style: AppTypography.bodyLg
                                                .copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Divider — uses bodySm for label
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
                                        style: AppTypography.bodySm.copyWith(
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

                                // Sign Up link — uses bodyMd + inkTerracotta accent
                                Center(
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context)
                                        .pushNamed('/signup'),
                                    child: RichText(
                                      text: TextSpan(
                                        text: "Don't have an account? ",
                                        style: AppTypography.bodyMd.copyWith(
                                          color: AppTheme.inkUmber
                                              .withValues(alpha: 0.8),
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Sign Up',
                                            style:
                                                AppTypography.bodyMd.copyWith(
                                              color:
                                                  AppTheme.inkTerracotta,
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

  // Label uses new labelMd (Manrope 12 bold)
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.labelMd.copyWith(
        color: AppTheme.inkEspresso,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      // Input text uses bodyMd so it matches the overall reading style
      style: AppTypography.bodyMd.copyWith(color: AppTheme.inkEspresso),
      decoration: InputDecoration(
        hintText: 'Enter your email',
        hintStyle: AppTypography.bodyMd.copyWith(
          color: AppTheme.inkUmber.withValues(alpha: 0.5),
        ),
        prefixIcon: const Icon(Icons.email_outlined,
            color: AppTheme.inkUmber, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: AppTheme.inkUmber.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: AppTheme.inkUmber.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: AppTheme.inkTerracotta, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.inkCanvas,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: AppTypography.bodyMd.copyWith(color: AppTheme.inkEspresso),
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: AppTypography.bodyMd.copyWith(
          color: AppTheme.inkUmber.withValues(alpha: 0.5),
        ),
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
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: AppTheme.inkUmber.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: AppTheme.inkUmber.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: AppTheme.inkTerracotta, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.inkCanvas,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: Icon(
              Icons.info_outline,
              color: AppTheme.inkMaroon,
              size: 48,
            ),
            title: Text(
              'Missing Fields',
              style: AppTypography.headingSm.copyWith(
                color: AppTheme.inkEspresso,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'Please fill in all fields',
              style: AppTypography.bodyMd.copyWith(
                color: AppTheme.inkUmber,
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: AppTypography.labelMd.copyWith(
                    color: AppTheme.inkMaroon,
                  ),
                ),
              ),
            ],
          );
        },
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
        // Success dialog - show briefly then navigate
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              icon: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              title: Text(
                'Welcome Back!',
                style: AppTypography.headingSm.copyWith(
                  color: AppTheme.inkEspresso,
                ),
                textAlign: TextAlign.center,
              ),
              content: Text(
                'You\'re logged in as ${user.email}',
                style: AppTypography.bodyMd.copyWith(
                  color: AppTheme.inkUmber,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        );

        // Navigate after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                icon: Icon(
                  Icons.error_outline,
                  color: AppTheme.maroon,
                  size: 48,
                ),
                title: Text(
                  'Login Failed',
                  style: AppTypography.headingSm.copyWith(
                    color: AppTheme.inkEspresso,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  'Invalid email or password',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppTheme.inkUmber,
                  ),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Try Again',
                      style: AppTypography.labelMd.copyWith(
                        color: AppTheme.inkMaroon,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                icon: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 48,
                ),
                title: Text(
                  'Error',
                  style: AppTypography.headingSm.copyWith(
                    color: AppTheme.inkEspresso,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  'Login failed: $e',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppTheme.inkUmber,
                  ),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'OK',
                      style: AppTypography.labelMd.copyWith(
                        color: AppTheme.inkMaroon,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
  }
}