import 'package:flutter/material.dart';
import '../theme/new_app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/background_shape.dart';
import '../widgets/social_login_buttons.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _lastNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _usernameController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  static const String _googleClientId =
      'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';
  final AuthService _authService =
      AuthService(googleClientId: _googleClientId);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _lastNameController = TextEditingController();
    _firstNameController = TextEditingController();
    _usernameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.inkEspresso, // deep espresso dark header
        ),
        child: Stack(
          children: [
            const BookBackgroundShape(),
            SafeArea(
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.28,
                        ),
                      ),

                      // Ivory panel
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceColor, // aged ivory
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(36),
                              topRight: Radius.circular(36),
                            ),
                          ),
                          padding:
                              const EdgeInsets.fromLTRB(28, 32, 28, 40),
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

                              // Header — DM Serif Display 30
                              Center(
                                child: Text(
                                  'Create Account',
                                  style: AppTypography.headingLg.copyWith(
                                    color: AppTheme.inkEspresso,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Sub-header — Manrope 14
                              Center(
                                child: Text(
                                  'Join the community of writers',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppTheme.inkUmber,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // First Name
                              _buildLabel('First Name'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _firstNameController,
                                hint: 'Enter your first name',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 16),

                              // Last Name
                              _buildLabel('Last Name'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _lastNameController,
                                hint: 'Enter your last name',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 16),

                              // Username
                              _buildLabel('Username'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _usernameController,
                                hint: '@username',
                                icon: Icons.alternate_email,
                                iconColor: AppTheme.inkMaroon, // accent color for username
                              ),
                              const SizedBox(height: 16),

                              // Email
                              _buildLabel('Email'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _emailController,
                                hint: 'Enter your email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),

                              // Password
                              _buildLabel('Password'),
                              const SizedBox(height: 8),
                              _buildPasswordField(),
                              const SizedBox(height: 16),

                              // Confirm Password
                              _buildLabel('Confirm Password'),
                              const SizedBox(height: 8),
                              _buildConfirmPasswordField(),
                              const SizedBox(height: 16),

                              // Terms checkbox
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _agreeToTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _agreeToTerms = value ?? false;
                                        });
                                      },
                                      activeColor: AppTheme.inkTerracotta,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Agree To ',
                                        // bodySm — Manrope 12
                                        style: AppTypography.bodySm
                                            .copyWith(
                                          color: AppTheme.inkUmber,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Terms & Privacy',
                                            style: AppTypography.bodySm
                                                .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  AppTheme.inkTerracotta,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Sign Up button — terracotta CTA
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _handleSignUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppTheme.inkMaroon, // or inkTerracotta for more pop
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
                                          'Sign Up',
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

                              // Divider — bodySm label
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
                                        horizontal: 8.0),
                                    child: Text(
                                      'or continue with',
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppTheme.inkUmber
                                            .withValues(alpha: 0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                onSuccess: () {
                                  if (mounted) {
                                    Navigator.of(context)
                                        .pushReplacementNamed('/home');
                                  }
                                },
                              ),
                              const SizedBox(height: 24),

                              // Login link — bodyMd + inkTerracotta accent
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context)
                                      .pushNamed('/login'),
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Already have an account? ',
                                      style: AppTypography.bodyMd.copyWith(
                                        color: AppTheme.inkUmber
                                            .withValues(alpha: 0.8),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Log in',
                                          style:
                                              AppTypography.bodyMd.copyWith(
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

                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Container(color: AppTheme.backgroundColor), // Fill remaining space with background color
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

  // labelMd — Manrope 12 bold
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.labelMd.copyWith(
        color: AppTheme.inkEspresso,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Color? iconColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      // Input text — bodyMd (Manrope 14)
      style: AppTypography.bodyMd.copyWith(color: AppTheme.inkEspresso),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMd.copyWith(
          color: AppTheme.inkUmber.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(icon, color: iconColor ?? AppTheme.inkMaroon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.inkMaroon.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.inkMaroon.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
            color: AppTheme.inkMaroon, size: 20),
        suffixIcon: GestureDetector(
          onTap: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppTheme.inkMaroon,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.inkMaroon.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.inkMaroon.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.inkTerracotta, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.inkCanvas,
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: AppTypography.bodyMd.copyWith(color: AppTheme.inkEspresso),
      decoration: InputDecoration(
        hintText: 'Enter your password again',
        hintStyle: AppTypography.bodyMd.copyWith(
          color: AppTheme.inkUmber.withValues(alpha: 0.5),
        ),
        prefixIcon: const Icon(Icons.lock_outline,
            color: AppTheme.inkMaroon, size: 20),
        suffixIcon: GestureDetector(
          onTap: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
          child: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppTheme.inkMaroon,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.inkMaroon.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.inkMaroon.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.inkMaroon, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.inkCanvas,
      ),
    );
  }

  Future<void> _handleSignUp() async {
    // Check if agreed to terms
    if (!_agreeToTerms) {
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
              'Terms Required',
              style: AppTypography.headingSm.copyWith(
                color: AppTheme.inkEspresso,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'Please agree to Terms & Privacy to continue',
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

    // Check if all fields filled
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
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

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
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
              color: Colors.red,
              size: 48,
            ),
            title: Text(
              'Password Mismatch',
              style: AppTypography.headingSm.copyWith(
                color: AppTheme.inkEspresso,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'Passwords do not match',
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
      final user = await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        firstname: _firstNameController.text.trim(),
        lastname: _lastNameController.text.trim(),
        username: _usernameController.text.trim().toLowerCase(),
      );

      if (user != null && mounted) {
        if (!user.emailVerified) {
          await _authService.sendEmailVerification();

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
                    Icons.mail_outline,
                    color: AppTheme.inkMaroon,
                    size: 48,
                  ),
                  title: Text(
                    'Verification Email Sent',
                    style: AppTypography.headingSm.copyWith(
                      color: AppTheme.inkEspresso,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  content: Text(
                    'Please check your inbox for the verification link',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppTheme.inkUmber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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

          if (mounted) {
            _showEmailVerificationDialog(user.email ?? '');
          }
        } else {
          if (mounted) {
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
                    'Account Created!',
                    style: AppTypography.headingSm.copyWith(
                      color: AppTheme.inkEspresso,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  content: Text(
                    'Your account has been created successfully',
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
          }
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
                  color: Colors.red,
                  size: 48,
                ),
                title: Text(
                  'Sign Up Failed',
                  style: AppTypography.headingSm.copyWith(
                    color: AppTheme.inkEspresso,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  'Please try again',
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
                'Sign up failed: $e',
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

  void _showEmailVerificationDialog(String userEmail) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          // Dialog title — headingSm (DM Serif Display 20)
          title: Text(
            'Verify Your Email',
            style: AppTypography.headingSm.copyWith(
              color: AppTheme.inkEspresso,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // bodyMd — Manrope 14
              Text(
                'We sent a verification link to:',
                style: AppTypography.bodyMd.copyWith(
                  color: AppTheme.inkUmber,
                ),
              ),
              const SizedBox(height: 8),
              // authorName style fits this perfectly — Manrope 13 semi-bold
              Text(
                userEmail,
                style: AppTypography.authorName.copyWith(
                  color: AppTheme.inkTerracotta,
                ),
              ),
              const SizedBox(height: 16),
              // bodySm — Manrope 12 for supporting copy
              Text(
                'Click the link in the email to verify your account. Once verified, you can log in.',
                style: AppTypography.bodySm.copyWith(
                  color: AppTheme.inkUmber,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final navigator = Navigator.of(dialogContext);
                navigator.pop();
                navigator.pushNamed('/login');
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.inkUmber,
              ),
              // labelMd — Manrope 12 bold
              child: Text(
                'Go to Login',
                style: AppTypography.labelMd.copyWith(
                  color: AppTheme.inkUmber,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _authService.sendEmailVerification();
                  if (dialogContext.mounted) {
                    showDialog(
                      context: dialogContext,
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
                            'Email Resent',
                            style: AppTypography.headingSm.copyWith(
                              color: AppTheme.inkEspresso,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          content: Text(
                            'Verification email sent again!',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppTheme.inkUmber,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(),
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
                } catch (e) {
                  if (dialogContext.mounted) {
                    showDialog(
                      context: dialogContext,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: AppTheme.surfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          icon: Icon(
                            Icons.error_outline,
                            color: Colors.red,
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
                            'Error: $e',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppTheme.inkUmber,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(),
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
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.inkTerracotta,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Resend Email',
                style: AppTypography.labelMd.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}