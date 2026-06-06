import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/new_app_theme.dart';
import '../../theme/app_typography.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _photoUrlController;
  bool _isLoading = false;
  late bool _isPublic;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    String initialName = widget.userData['displayName'] ?? '';
    if (initialName.isEmpty) {
      final first = widget.userData['firstname'] ?? '';
      final last  = widget.userData['lastname']  ?? '';
      initialName = (first.isEmpty && last.isEmpty)
          ? (user?.displayName ?? '')
          : '$first $last'.trim();
    }

    _displayNameController = TextEditingController(text: initialName);
    _usernameController    = TextEditingController(text: widget.userData['username'] ?? '');
    _bioController         = TextEditingController(text: widget.userData['bio'] ?? '');
    _photoUrlController    = TextEditingController(
        text: widget.userData['photoUrl'] ?? user?.photoURL ?? '');
    _isPublic = widget.userData['isPublic'] ?? true;

    _photoUrlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'displayName': _displayNameController.text.trim(),
        'username':    _usernameController.text.trim(),
        'bio':         _bioController.text.trim(),
        'photoUrl':    _photoUrlController.text.trim(),
        'isPublic':    _isPublic,
        'updatedAt':   FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Header (matches Settings style) ────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.inkMaroon,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edit Profile',
                      style: AppTypography.headingLg.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Update your information and how others see you',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
                // Decorative shapes
              const SizedBox(width: 8),
              _DecorativeShapes(),
              const SizedBox(width: 10),

              // Save button
              GestureDetector(
                onTap: _isLoading ? null : _saveProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.inkMaroon,
                          ),
                        )
                      : Text(
                          'Save',
                          style: AppTypography.labelMd.copyWith(
                            color: AppTheme.inkMaroon,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ────────────────────────────────────────────────
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: AppTheme.inkBgCard,
                          backgroundImage: _photoUrlController.text.isNotEmpty
                              ? NetworkImage(_photoUrlController.text)
                              : null,
                          child: _photoUrlController.text.isEmpty
                              ? const Icon(Icons.person,
                                  size: 52, color: AppTheme.inkUmber)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.inkMaroon,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Display Name ──────────────────────────────────────────
                  _buildFieldLabel('Display Name'),
                  _buildTextField(
                    controller: _displayNameController,
                    hint: 'How people will see your name',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),

                  // ── Username ──────────────────────────────────────────────
                  _buildFieldLabel('Username'),
                  _buildTextField(
                    controller: _usernameController,
                    hint: 'e.g. amelia_writes',
                    prefixIcon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: 16),

                  // ── Bio ───────────────────────────────────────────────────
                  _buildFieldLabel('Bio'),
                  _buildTextField(
                    controller: _bioController,
                    hint: 'Tell the world about yourself...',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // ── Profile Image URL ─────────────────────────────────────
                  _buildFieldLabel('Profile Image URL'),
                  _buildTextField(
                    controller: _photoUrlController,
                    hint: 'Link to your profile picture',
                    prefixIcon: Icons.link_rounded,
                  ),
                  const SizedBox(height: 16),

                  // ── Profile Visibility ────────────────────────────────────
                  _buildVisibilityCard(),
                  const SizedBox(height: 10),

                  // ── Info card ─────────────────────────────────────────────
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Field label ─────────────────────────────────────────────────────────────

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        label,
        style: AppTypography.labelMd.copyWith(
          color: AppTheme.inkEspresso,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // ── Text field with icon prefix ─────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.inkUmber.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          // Icon badge
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              top: maxLines > 1 ? 14 : 0,
              right: 0,
            ),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.inkMaroon.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                prefixIcon,
                size: 16,
                color: AppTheme.inkMaroon.withValues(alpha: 0.75),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Text input
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: AppTypography.bodyMd.copyWith(
                color: AppTheme.inkEspresso,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.bodyMd.copyWith(
                  color: AppTheme.inkUmber.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: maxLines > 1 ? 14 : 0,
                  horizontal: 4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ── Profile visibility card ─────────────────────────────────────────────────

  Widget _buildVisibilityCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.inkUmber.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.inkMaroon.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 16,
              color: AppTheme.inkMaroon.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Visibility',
                  style: AppTypography.labelMd.copyWith(
                    color: AppTheme.inkEspresso,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPublic
                      ? 'Public - Anyone can view your profile'
                      : 'Private - Only you can see your profile',
                  style: AppTypography.caption.copyWith(
                    color: AppTheme.inkUmber.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.inkMaroon,
            inactiveThumbColor: AppTheme.inkGold,
            inactiveTrackColor: AppTheme.inkGold.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  // ── Info card ───────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.inkUmber.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.inkMaroon.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppTheme.inkMaroon.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your profile, your choice',
                  style: AppTypography.labelMd.copyWith(
                    color: AppTheme.inkEspresso,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your details and control who can see your profile.',
                  style: AppTypography.caption.copyWith(
                    color: AppTheme.inkUmber.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Decorative geometric shapes (reused from Settings) ──────────────────────

class _DecorativeShapes extends StatelessWidget {
  const _DecorativeShapes();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 60,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 18,
            child: Icon(Icons.auto_awesome_rounded,
                size: 16, color: Colors.white.withValues(alpha: 0.55)),
          ),
          Positioned(
            left: 20,
            top: 4,
            child: Icon(Icons.auto_awesome_rounded,
                size: 11, color: Colors.white.withValues(alpha: 0.4)),
          ),
          Positioned(
            left: 8,
            top: 38,
            child: Icon(Icons.auto_awesome_rounded,
                size: 9, color: Colors.white.withValues(alpha: 0.3)),
          ),
          Positioned(
            right: 0,
            top: 2,
            child: CustomPaint(
              size: const Size(26, 26),
              painter: _TrianglePainter(
                  color: Colors.white.withValues(alpha: 0.30)),
            ),
          ),
          Positioned(
            right: 30,
            top: 32,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 32,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0x33FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}