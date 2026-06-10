import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;
import 'package:vibewrite_app/theme/new_app_theme.dart';
import 'package:vibewrite_app/main_tabs/post/post.dart';
import 'package:vibewrite_app/main_tabs/profile.dart';
import 'package:vibewrite_app/main_tabs/library.dart';
import 'package:vibewrite_app/main_tabs/home.dart';
import 'package:vibewrite_app/main_tabs/notifications_screen.dart';


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  
  int _selectedIndex = 0;
  bool _hideBottomBar = false;

  // Animation controllers
  late AnimationController _pageTransitionController;
  late Animation<double> _pageOpacity;
  late Animation<Offset> _pageSlide;

  List<Widget>? _screens;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_outlined,    'activeIcon': Icons.home_rounded,      'label': 'Home'},
    {'icon': Icons.notifications_outlined, 'activeIcon': Icons.notifications_rounded,   'label': 'Search'},
    {'icon': Icons.edit_outlined,    'activeIcon': Icons.edit_rounded,      'label': 'Write'},
    {'icon': Icons.bookmark_border, 'activeIcon': Icons.bookmark_rounded,  'label': 'Library'},
    {'icon': Icons.person_outline,  'activeIcon': Icons.person_rounded,    'label': 'Profile'},
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize page transition animation
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Fade in effect
    _pageOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageTransitionController, curve: Curves.easeIn),
    );

    // Slide from right effect
    _pageSlide = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _pageTransitionController, curve: Curves.easeOutCubic),
    );

    // Initialize screens
    _screens = [
      const HomeScreen(),
      const NotificationsScreen(),
      PostScreen(
        onEditorModeChanged: (isEditor) {
          setState(() => _hideBottomBar = isEditor);
        },
      ),
      const LibraryScreen(),
      const ProfileScreen(),
    ];

    // Start animation immediately
    _pageTransitionController.forward();
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index != _selectedIndex) {
      _pageTransitionController.forward(from: 0.0);
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_screens == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: FadeTransition(
        opacity: _pageOpacity,
        child: SlideTransition(
          position: _pageSlide,
          child: _screens![_selectedIndex],
        ),
      ),
      bottomNavigationBar: _hideBottomBar
          ? null
          : _ElevatedCenterNavBar(
              selectedIndex: _selectedIndex,
              items: _navItems,
              onTap: _onNavTap,
            ),
    );
  }
}

// ─── Nav Bar ──────────────────────────────────────────────────────────────────

class _ElevatedCenterNavBar extends StatefulWidget {
  final int selectedIndex;
  final List<Map<String, dynamic>> items;
  final ValueChanged<int> onTap;

  const _ElevatedCenterNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  State<_ElevatedCenterNavBar> createState() => _ElevatedCenterNavBarState();
}

class _ElevatedCenterNavBarState extends State<_ElevatedCenterNavBar>
    with SingleTickerProviderStateMixin {

  static const _barColor      = Colors.white;
  static const _notchColor    = AppTheme.inkMaroon;
  static const _barHeight     = 60.0;
  static const _notchRadius   = 28.0;

  AnimationController? _slideController;
  Animation<double>?   _slideAnim;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.selectedIndex;

    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _slideController = ctrl;
    _slideAnim = CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(_ElevatedCenterNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _prevIndex = old.selectedIndex;
      _slideController?.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slideAnim;
    if (slide == null) return const SizedBox.shrink();

    final count     = widget.items.length;
    final screenW   = MediaQuery.of(context).size.width;
    final barWidth  = screenW - 32;
    final itemWidth = barWidth / count;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: SizedBox(
          height: 64,
          child: AnimatedBuilder(
            animation: slide,
            builder: (context, _) {
              final prevCx = itemWidth * _prevIndex + itemWidth / 2;
              final currCx = itemWidth * widget.selectedIndex + itemWidth / 2;
              final cx = lerpDouble(prevCx, currCx, slide.value) ?? currCx;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Background Canvas & Notch Shape ──────────────────────────
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _NotchNavBarPainter(
                        activeX: cx,
                        barHeight: _barHeight,
                        barColor: _barColor,
                        notchColor: _notchColor,
                        notchRadius: _notchRadius,
                      ),
                    ),
                  ),

                  // ── Interactive Icon Layer ───────────────────────────────────
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: _barHeight,
                    child: Row(
                      children: List.generate(count, (index) {
                        final isSelected = index == widget.selectedIndex;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => widget.onTap(index),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: isSelected
                                  ? Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Maroon outline effect
                                          Icon(
                                            widget.items[index]['activeIcon'] as IconData,
                                            size: 28,
                                            color: AppTheme.inkMaroon,
                                          ),
                                          // White icon on top
                                          Icon(
                                            widget.items[index]['activeIcon'] as IconData,
                                            size: 24,
                                            color: AppTheme.inkMaroon,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Icon(
                                      widget.items[index]['icon'] as IconData,
                                      size: 24,
                                      color: AppTheme.surfaceColor
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painter ───────────────────────────────────────────────────────────

class _NotchNavBarPainter extends CustomPainter {
  final double activeX;
  final double barHeight;
  final Color barColor;
  final Color notchColor;
  final double notchRadius;

  _NotchNavBarPainter({
    required this.activeX,
    required this.barHeight,
    required this.barColor,
    required this.notchColor,
    required this.notchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final topY = size.height - barHeight;

    // Main white bar background
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    const borderRadius = 16.0;

    // ── Main bar path (white background) ──────────────────────────────────
    final barPath = Path();
    barPath.moveTo(borderRadius, topY);
    barPath.lineTo(size.width - borderRadius, topY);
    barPath.arcToPoint(
      Offset(size.width, topY + borderRadius),
      radius: const Radius.circular(borderRadius),
    );
    barPath.lineTo(size.width, size.height - borderRadius);
    barPath.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: const Radius.circular(borderRadius),
    );
    barPath.lineTo(borderRadius, size.height);
    barPath.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: const Radius.circular(borderRadius),
    );
    barPath.lineTo(0, topY + borderRadius);
    barPath.arcToPoint(
      Offset(borderRadius, topY),
      radius: const Radius.circular(borderRadius),
    );

    // Draw white bar
    canvas.drawPath(barPath, barPaint);

    // ── Maroon notch overlay ──────────────────────────────────────────────
    final notchPaint = Paint()
      ..color = notchColor
      ..style = PaintingStyle.fill;

    final notchPath = Path();
    
    // Start from left side of notch
    notchPath.moveTo(activeX - notchRadius - 12, topY);
    
    // Left curve into notch
    notchPath.quadraticBezierTo(
      activeX - notchRadius - 4,
      topY,
      activeX - notchRadius,
      topY + notchRadius,
    );

    // Bottom of notch (U shape)
    notchPath.arcToPoint(
      Offset(activeX + notchRadius, topY + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Right curve out of notch
    notchPath.quadraticBezierTo(
      activeX + notchRadius + 4,
      topY,
      activeX + notchRadius + 12,
      topY,
    );

    // Line to right edge
    notchPath.lineTo(size.width, topY);
    notchPath.lineTo(size.width, size.height - borderRadius);
    notchPath.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: const Radius.circular(borderRadius),
    );
    notchPath.lineTo(borderRadius, size.height);
    notchPath.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: const Radius.circular(borderRadius),
    );
    notchPath.lineTo(0, topY);
    notchPath.lineTo(activeX - notchRadius - 12, topY);

    // Draw notch overlay
    canvas.drawPath(notchPath, notchPaint);
  }

  @override
  bool shouldRepaint(covariant _NotchNavBarPainter oldDelegate) {
    return oldDelegate.activeX != activeX;
  }
}