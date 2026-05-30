import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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
            const BackgroundShape(),
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

                              const Center(
                                child: Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.inkEspresso,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Center(
                                child: Text(
                                  'Join the community of writers',
                                  style: TextStyle(
                                    fontSize: 13,
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
                                hint: 'Enter your first name  ',
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

                              // Terms checkbox — uses inkTerracotta for active state
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
                                      text: const TextSpan(
                                        text: 'Agree To ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.inkUmber,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Terms & Privacy',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.inkTerracotta,
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
                                    backgroundColor: AppTheme.inkTerracotta,
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
                                      : const Text(
                                          'Sign Up',
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
                                        horizontal: 8.0),
                                    child: Text(
                                      'or continue with',
                                      style: TextStyle(
                                        fontSize: 11,
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

                              // Login link
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context)
                                      .pushNamed('/login'),
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Already have an account? ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.inkUmber
                                            .withValues(alpha: 0.8),
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'Log in',
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

                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Container(color: AppTheme.inkBgMain),
                      ),
                    ],
                  ),

                  // Back button — light on dark header
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.inkUmber, size: 20),
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

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        hintText: 'Enter your password again',
        prefixIcon: const Icon(Icons.lock_outline,
            color: AppTheme.inkUmber, size: 20),
        suffixIcon: GestureDetector(
          onTap: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
          child: Icon(
            _obscureConfirmPassword
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

  Future<void> _handleSignUp() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms & Privacy'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          duration: Duration(seconds: 2),
        ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Verification email sent! Please check your inbox.'),
                duration: Duration(seconds: 3),
              ),
            );
          }

          if (mounted) {
            _showEmailVerificationDialog(user.email ?? '');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Account created for ${user.email}!')),
            );
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Sign up failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: $e')),
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
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.inkBgMain,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Verify Your Email',
            style: TextStyle(
              color: AppTheme.inkEspresso,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We sent a verification link to:',
                style: TextStyle(fontSize: 14, color: AppTheme.inkUmber),
              ),
              const SizedBox(height: 8),
              Text(
                userEmail,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.inkTerracotta,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Click the link in the email to verify your account. Once verified, you can log in.',
                style: TextStyle(fontSize: 13, color: AppTheme.inkUmber),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/login');
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.inkUmber,
              ),
              child: const Text('Go to Login'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await _authService.sendEmailVerification();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Verification email sent again!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
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
              child: const Text('Resend Email'),
            ),
          ],
        );
      },
    );
  }
}