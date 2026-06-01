import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.inkBgMain, // aged ivory — same as home
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top area: VibeWrite logo + decorative elements ──
              Expanded(
                flex: 5,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Logo image with fallback
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Image.asset(
                            'assets/images/vibewrite.png',
                            fit: BoxFit.contain,
                            height: 300,
                            errorBuilder: (_, __, ___) => Column(
                              children: [
                                // Fallback text logo with app theme colors
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'VIBEWRITE',
                                      style: TextStyle(
                                        fontFamily: 'Paytone One',
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.inkTerracotta,
                                      ),
                                    ),
                                    const Text(
                                      'WRITE',
                                      style: TextStyle(
                                        fontFamily: 'Paytone One',
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.inkEspresso,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Tagline
                                Text(
                                  'EVERY VIBE HAS A STORY',
                                  style: TextStyle(
                                    fontSize: 14,
                                    letterSpacing: 2.5,
                                    color: AppTheme.inkUmber.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom canvas panel ──
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.inkCanvas, // warm canvas — matches home card surfaces
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                      border: Border.all(
                        color: AppTheme.inkCanvas,
                        width: 0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: AppTheme.inkUmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const Text(
                          'Welcome!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.inkEspresso,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Ready to share your vibe?',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.inkEspresso,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Meet new readers, share your stories.'
                          '\nJoin the community — it\'s free.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.inkUmber.withValues(alpha: 0.7),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Create Account — terracotta solid button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/signup');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.inkTerracotta,
                              foregroundColor: Colors.white,
                              shadowColor: AppTheme.inkTerracotta.withValues(alpha: 0.3),
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Log In — espresso outlined button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/login');
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppTheme.inkEspresso.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.inkEspresso,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}