import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StorySetupModal {
  static void show({
    required BuildContext context,
    required String selectedGenre,
    required String storyType,
    required String contentType,
    required List<String> storyTypes,
    required List<String> genres,
    required List<String> contentTypes,
    required Function(String) onGenreChanged,
    required Function(String) onStoryTypeChanged,
    required Function(String) onContentTypeChanged,
    required Color Function(String) genreColor,
    required Color Function(String) storyTypeColor,
    required Color Function(String) contentTypeColor,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'story-setup-sidebar',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, _, __) {
        final slide = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ));

        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.3),
          ),
        );

        return FadeTransition(
          opacity: fade,
          child: Stack(
            children: [
              // Tap outside to dismiss
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
              // Sidebar panel
              Align(
                alignment: Alignment.centerRight,
                child: SlideTransition(
                  position: slide,
                  child: _StorySetupModalContent(
                    selectedGenre: selectedGenre,
                    storyType: storyType,
                    contentType: contentType,
                    storyTypes: storyTypes,
                    genres: genres,
                    contentTypes: contentTypes,
                    onGenreChanged: onGenreChanged,
                    onStoryTypeChanged: onStoryTypeChanged,
                    onContentTypeChanged: onContentTypeChanged,
                    genreColor: genreColor,
                    storyTypeColor: storyTypeColor,
                    contentTypeColor: contentTypeColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Internal widget ─────────────────────────────────────────────────────────

class _StorySetupModalContent extends StatefulWidget {
  final String selectedGenre;
  final String storyType;
  final String contentType;
  final List<String> storyTypes;
  final List<String> genres;
  final List<String> contentTypes;
  final Function(String) onGenreChanged;
  final Function(String) onStoryTypeChanged;
  final Function(String) onContentTypeChanged;
  final Color Function(String) genreColor;
  final Color Function(String) storyTypeColor;
  final Color Function(String) contentTypeColor;

  const _StorySetupModalContent({
    required this.selectedGenre,
    required this.storyType,
    required this.contentType,
    required this.storyTypes,
    required this.genres,
    required this.contentTypes,
    required this.onGenreChanged,
    required this.onStoryTypeChanged,
    required this.onContentTypeChanged,
    required this.genreColor,
    required this.storyTypeColor,
    required this.contentTypeColor,
  });

  @override
  State<_StorySetupModalContent> createState() =>
      _StorySetupModalContentState();
}

class _StorySetupModalContentState
    extends State<_StorySetupModalContent> {
  late String _selectedGenre;
  late String _selectedStoryType;
  late String _selectedContentType;

  final Map<String, IconData> _storyTypeIcons = {
    'Short Story': Icons.description_outlined,
    'Flash Fiction': Icons.flash_on_outlined,
    'Novel': Icons.menu_book_outlined,
    'Poetry': Icons.edit_outlined,
  };

  // Regular Genres (for non-poetry)
  final Map<String, IconData> _genreIcons = {
    'Romance': Icons.favorite_outline,
    'Mystery': Icons.search,
    'Fantasy': Icons.auto_awesome_outlined,
    'Sci-Fi': Icons.rocket_launch_outlined,
    'Drama': Icons.theater_comedy_outlined,
    'Horror': Icons.dark_mode_outlined,
    'Thriller': Icons.local_police_outlined,
  };

  // Poetry Types
  final Map<String, IconData> _poetryTypeIcons = {
    'Lyric Poetry': Icons.favorite_outline,
    'Narrative Poetry': Icons.book_outlined,
    'Dramatic Poetry': Icons.theater_comedy_outlined,
    'Epic Poetry': Icons.auto_awesome_outlined,
    'Ballad': Icons.music_note_outlined,
    'Ode': Icons.sentiment_satisfied_outlined,
    'Elegy': Icons.cloud_outlined,
    'Sonnet': Icons.edit_outlined,
    'Haiku': Icons.nature_outlined,
    'Free Verse': Icons.water_outlined,
  };

  // Regular Content Types
  final Map<String, IconData> _contentTypeIcons = {
    'Prologue': Icons.first_page_rounded,
    'Chapter': Icons.description_outlined,
    'Epilogue': Icons.last_page_rounded,
  };

  // Poetry Themes
  final Map<String, IconData> _poetryThemeIcons = {
    'Love': Icons.favorite_rounded,
    'Friendship': Icons.people_outline,
    'Nature': Icons.nature_rounded,
    'Graduation': Icons.school_rounded,
    'Family': Icons.family_restroom_rounded,
    'Loss': Icons.sentiment_very_dissatisfied_outlined,
    'War': Icons.security_rounded,
    'Adventure': Icons.hiking_rounded,
    'Fantasy': Icons.auto_awesome_rounded,
    'Hope': Icons.wb_sunny_rounded,
    'Success': Icons.emoji_events_rounded,
    'Spirituality': Icons.self_improvement_rounded,
    'Patriotism': Icons.flag_rounded,
  };

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.selectedGenre;
    _selectedStoryType = widget.storyType;
    _selectedContentType = widget.contentType;
  }

  /// Get color for poetry types
  Color _getPoetryTypeColor(String poetryType) {
    switch (poetryType.toLowerCase()) {
      case 'lyric poetry':
        return const Color(0xFFD4557E);
      case 'narrative poetry':
        return const Color(0xFF7B68A6);
      case 'dramatic poetry':
        return const Color(0xFFB8860B);
      case 'epic poetry':
        return const Color(0xFF2E7D9F);
      case 'ballad':
        return const Color(0xFF5FA35C);
      case 'ode':
        return const Color(0xFFC85A54);
      case 'elegy':
        return const Color(0xFF4A4A4A);
      case 'sonnet':
        return const Color(0xFFD4557E);
      case 'haiku':
        return const Color(0xFF5FA35C);
      case 'free verse':
        return const Color(0xFF7B68A6);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  /// Get color for poetry themes
  Color _getPoetryThemeColor(String theme) {
    switch (theme.toLowerCase()) {
      case 'love':
        return const Color(0xFFD4557E);
      case 'friendship':
        return const Color(0xFF5FA35C);
      case 'nature':
        return const Color(0xFF2E7D9F);
      case 'graduation':
        return const Color(0xFFB8860B);
      case 'family':
        return const Color(0xFF7B68A6);
      case 'loss':
        return const Color(0xFF4A4A4A);
      case 'war':
        return const Color(0xFFC85A54);
      case 'adventure':
        return const Color(0xFF5FA35C);
      case 'fantasy':
        return const Color(0xFF7B68A6);
      case 'hope':
        return const Color(0xFFB8860B);
      case 'success':
        return const Color(0xFFB8860B);
      case 'spirituality':
        return const Color(0xFF2E7D9F);
      case 'patriotism':
        return const Color(0xFFC85A54);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final isPoetry = _selectedStoryType == 'Poetry';

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          width: 300,
          height: screenH,
          decoration: const BoxDecoration(
            color: AppTheme.inkIvory,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 32,
                offset: Offset(-6, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Story Type Section (Always shown)
                      _buildSection(
                        label: 'STORY TYPE',
                        options: widget.storyTypes,
                        selected: _selectedStoryType.isNotEmpty
                            ? _selectedStoryType
                            : widget.storyType,
                        colorFn: widget.storyTypeColor,
                        iconMap: _storyTypeIcons,
                        onChanged: (v) {
                          setState(() {
                            _selectedStoryType = v;
                            // Reset genre and content type when changing story type
                            if (v == 'Poetry') {
                              _selectedGenre = 'Lyric Poetry';
                              _selectedContentType = 'Love';
                            } else {
                              _selectedGenre = widget.selectedGenre;
                              _selectedContentType = widget.contentType;
                            }
                          });
                          widget.onStoryTypeChanged(v);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Genre Section (Different based on story type)
                      if (isPoetry)
                        _buildSection(
                          label: 'POETRY TYPE',
                          options: _poetryTypeIcons.keys.toList(),
                          selected: _selectedGenre.isNotEmpty
                              ? _selectedGenre
                              : 'Lyric Poetry',
                          colorFn: _getPoetryTypeColor,
                          iconMap: _poetryTypeIcons,
                          onChanged: (v) {
                            setState(() => _selectedGenre = v);
                            widget.onGenreChanged(v);
                          },
                        )
                      else
                        _buildSection(
                          label: 'GENRE',
                          options: widget.genres,
                          selected: _selectedGenre.isNotEmpty
                              ? _selectedGenre
                              : widget.selectedGenre,
                          colorFn: widget.genreColor,
                          iconMap: _genreIcons,
                          onChanged: (v) {
                            setState(() => _selectedGenre = v);
                            widget.onGenreChanged(v);
                          },
                        ),
                      const SizedBox(height: 20),

                      // Content Type Section (Different based on story type)
                      if (isPoetry)
                        _buildSection(
                          label: 'THEME',
                          options: _poetryThemeIcons.keys.toList(),
                          selected: _selectedContentType.isNotEmpty
                              ? _selectedContentType
                              : 'Love',
                          colorFn: _getPoetryThemeColor,
                          iconMap: _poetryThemeIcons,
                          onChanged: (v) {
                            setState(() => _selectedContentType = v);
                            widget.onContentTypeChanged(v);
                          },
                        )
                      else
                        _buildSection(
                          label: 'CONTENT TYPE',
                          options: widget.contentTypes,
                          selected: _selectedContentType.isNotEmpty
                              ? _selectedContentType
                              : widget.contentType,
                          colorFn: widget.contentTypeColor,
                          iconMap: _contentTypeIcons,
                          onChanged: (v) {
                            setState(() => _selectedContentType = v);
                            widget.onContentTypeChanged(v);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              _buildDoneButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.inkTerracotta.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.tune_rounded,
                    size: 17, color: AppTheme.inkTerracotta),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Story Setup',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.inkEspresso,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Genre, type & structure',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.inkUmber,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.inkCanvas,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 15, color: AppTheme.inkUmber),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section ───────────────────────────────────────────────────────────────

  Widget _buildSection({
    required String label,
    required List<String> options,
    required String selected,
    required Color Function(String) colorFn,
    required Map<String, IconData> iconMap,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label with divider line
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppTheme.inkUmber.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.inkUmber.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Chips
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: options.map((option) {
            final isSelected = selected == option;
            final color = colorFn(option);
            // Safely get icon with null coalescing
            final icon = iconMap[option] ?? Icons.category_outlined;
            
            return GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.14)
                      : color.withValues(alpha: 0.06),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.7)
                        : color.withValues(alpha: 0.18),
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: isSelected
                          ? color
                          : color.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? color
                            : AppTheme.inkEspresso.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Done button ───────────────────────────────────────────────────────────

  Widget _buildDoneButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.inkTerracotta,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Done',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}