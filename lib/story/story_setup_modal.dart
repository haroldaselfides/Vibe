import 'package:flutter/material.dart';
import '../theme/new_app_theme.dart';
import '../theme/app_typography.dart';

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
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
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

// ─── Internal widget ──────────────────────────────────────────────────────────

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
    required this.storyTypeColor,
    required this.contentTypeColor,
  });

  @override
  State<_StorySetupModalContent> createState() =>
      _StorySetupModalContentState();
}

class _StorySetupModalContentState extends State<_StorySetupModalContent> {
  late String _selectedGenre;
  late String _selectedStoryType;
  late String _selectedContentType;

  bool _storyTypeExpanded   = false;
  bool _genreExpanded       = false;
  bool _contentTypeExpanded = false;
  bool _moreGenresExpanded  = false;

  // ── Genre lists ────────────────────────────────────────────────────────────

  static const List<String> _primaryGenres = [
    'Romance',
    'Fantasy',
    'Mystery',
    'Sci-Fi',
    'Horror',
    'Thriller',
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
  ];

  static const List<String> _moreGenres = [
    'Historical Fiction',
    'Crime',
    'Dystopian',
    'Young Adult',
    'Slice of Life',
    'Supernatural',
    'Superhero',
    'Paranormal',
    'Coming of Age',
    'Biography',
    'Memoir',
    'Self-Help',
    'Educational',
  ];

  // ── Icon maps ──────────────────────────────────────────────────────────────

  static const Map<String, IconData> _storyTypeIcons = {
    'Short Story':   Icons.description_outlined,
    'Flash Fiction': Icons.flash_on_outlined,
    'Novel':         Icons.menu_book_outlined,
    'Poetry':        Icons.edit_outlined,
  };

  static const Map<String, IconData> _genreIcons = {
    'Romance':            Icons.favorite_outline,
    'Fantasy':            Icons.auto_awesome_outlined,
    'Mystery':            Icons.search,
    'Sci-Fi':             Icons.rocket_launch_outlined,
    'Horror':             Icons.dark_mode_outlined,
    'Thriller':           Icons.local_police_outlined,
    'Action':             Icons.sports_martial_arts_outlined,
    'Adventure':          Icons.explore_outlined,
    'Comedy':             Icons.sentiment_very_satisfied_outlined,
    'Drama':              Icons.theater_comedy_outlined,
    'Historical Fiction': Icons.account_balance_outlined,
    'Crime':              Icons.gavel_outlined,
    'Dystopian':          Icons.public_off_outlined,
    'Young Adult':        Icons.school_outlined,
    'Slice of Life':      Icons.wb_sunny_outlined,
    'Supernatural':       Icons.nights_stay_outlined,
    'Superhero':          Icons.bolt_outlined,
    'Paranormal':         Icons.blur_on_outlined,
    'Coming of Age':      Icons.child_care_outlined,
    'Biography':          Icons.person_outline,
    'Memoir':             Icons.history_edu_outlined,
    'Self-Help':          Icons.self_improvement_outlined,
    'Educational':        Icons.menu_book_outlined,
  };

  static const Map<String, IconData> _poetryTypeIcons = {
    'Lyric Poetry':     Icons.favorite_outline,
    'Narrative Poetry': Icons.book_outlined,
    'Dramatic Poetry':  Icons.theater_comedy_outlined,
    'Epic Poetry':      Icons.auto_awesome_outlined,
    'Ballad':           Icons.music_note_outlined,
    'Ode':              Icons.sentiment_satisfied_outlined,
    'Elegy':            Icons.cloud_outlined,
    'Sonnet':           Icons.edit_outlined,
    'Haiku':            Icons.nature_outlined,
    'Free Verse':       Icons.water_outlined,
  };

  static const Map<String, IconData> _contentTypeIcons = {
    'Prologue': Icons.first_page_rounded,
    'Chapter':  Icons.description_outlined,
    'Epilogue': Icons.last_page_rounded,
  };

  static const Map<String, IconData> _poetryThemeIcons = {
    'Love':         Icons.favorite_rounded,
    'Friendship':   Icons.people_outline,
    'Nature':       Icons.nature_rounded,
    'Graduation':   Icons.school_rounded,
    'Family':       Icons.family_restroom_rounded,
    'Loss':         Icons.sentiment_very_dissatisfied_outlined,
    'War':          Icons.security_rounded,
    'Adventure':    Icons.hiking_rounded,
    'Fantasy':      Icons.auto_awesome_rounded,
    'Hope':         Icons.wb_sunny_rounded,
    'Success':      Icons.emoji_events_rounded,
    'Spirituality': Icons.self_improvement_rounded,
    'Patriotism':   Icons.flag_rounded,
  };

  // ── Color helpers — fully self-contained, no null risk ────────────────────

  Color _genreColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'romance':            return AppTheme.inkTerracotta;
      case 'fantasy':            return AppTheme.inkSage;
      case 'mystery':            return AppTheme.inkEspresso;
      case 'sci-fi':             return AppTheme.inkMaroon;
      case 'horror':             return AppTheme.inkEspresso;
      case 'thriller':           return AppTheme.inkMaroon;
      case 'action':             return AppTheme.inkTerracotta;
      case 'adventure':          return AppTheme.inkUmber;
      case 'comedy':             return AppTheme.inkGold;
      case 'drama':              return AppTheme.inkGold;
      case 'historical fiction': return AppTheme.inkUmber;
      case 'crime':              return AppTheme.inkEspresso;
      case 'dystopian':          return AppTheme.inkMaroon;
      case 'young adult':        return AppTheme.inkSage;
      case 'slice of life':      return AppTheme.inkGold;
      case 'supernatural':       return AppTheme.inkMaroon;
      case 'superhero':          return AppTheme.inkTerracotta;
      case 'paranormal':         return AppTheme.inkEspresso;
      case 'coming of age':      return AppTheme.inkSage;
      case 'biography':          return AppTheme.inkUmber;
      case 'memoir':             return AppTheme.inkUmber;
      case 'self-help':          return AppTheme.inkGold;
      case 'educational':        return AppTheme.inkSage;
      default:                   return AppTheme.inkSage;
    }
  }

  Color _poetryTypeColor(String poetryType) {
    switch (poetryType.toLowerCase()) {
      case 'lyric poetry':     return AppTheme.inkTerracotta;
      case 'narrative poetry': return AppTheme.inkMaroon;
      case 'dramatic poetry':  return AppTheme.inkGold;
      case 'epic poetry':      return AppTheme.inkUmber;
      case 'ballad':           return AppTheme.inkSage;
      case 'ode':              return AppTheme.inkTerracotta;
      case 'elegy':            return AppTheme.inkEspresso;
      case 'sonnet':           return AppTheme.inkMaroon;
      case 'haiku':            return AppTheme.inkUmber;
      case 'free verse':       return AppTheme.inkSage;
      default:                 return AppTheme.inkSage;
    }
  }

  Color _poetryThemeColor(String theme) {
    switch (theme.toLowerCase()) {
      case 'love':         return AppTheme.inkTerracotta;
      case 'friendship':   return AppTheme.inkUmber;
      case 'nature':       return AppTheme.inkSage;
      case 'graduation':   return AppTheme.inkGold;
      case 'family':       return AppTheme.inkMaroon;
      case 'loss':         return AppTheme.inkEspresso;
      case 'war':          return AppTheme.inkMaroon;
      case 'adventure':    return AppTheme.inkUmber;
      case 'fantasy':      return AppTheme.inkSage;
      case 'hope':         return AppTheme.inkGold;
      case 'success':      return AppTheme.inkGold;
      case 'spirituality': return AppTheme.inkUmber;
      case 'patriotism':   return AppTheme.inkTerracotta;
      default:             return AppTheme.inkSage;
    }
  }

  // ── Convenience getters ────────────────────────────────────────────────────

  bool get _isPoetry => _selectedStoryType == 'Poetry';

  bool get _showContentType =>
      !_isPoetry &&
      _selectedStoryType != 'Short Story' &&
      _selectedStoryType != 'Flash Fiction';

  @override
  void initState() {
    super.initState();
    _selectedGenre       = widget.selectedGenre;
    _selectedStoryType   = widget.storyType;
    _selectedContentType = widget.contentType;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          width: 300,
          height: screenH,
          decoration: const BoxDecoration(
            color: AppTheme.inkCanvas,
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Story Type ──────────────────────────
                      _buildDropdownSection(
                        label: 'STORY TYPE',
                        selectedValue: _selectedStoryType,
                        selectedColor: widget.storyTypeColor(_selectedStoryType),
                        selectedIcon: _storyTypeIcons[_selectedStoryType] ??
                            Icons.description_outlined,
                        isExpanded: _storyTypeExpanded,
                        onHeaderTap: () => setState(
                            () => _storyTypeExpanded = !_storyTypeExpanded),
                        child: _buildOptionList(
                          options: widget.storyTypes,
                          selected: _selectedStoryType,
                          colorFn: widget.storyTypeColor,
                          iconMap: _storyTypeIcons,
                          onChanged: (v) {
                            setState(() {
                              _selectedStoryType   = v;
                              _storyTypeExpanded   = false;
                              _moreGenresExpanded  = false;
                              if (v == 'Poetry') {
                                _selectedGenre       = 'Lyric Poetry';
                                _selectedContentType = 'Love';
                              } else {
                                _selectedGenre       = widget.selectedGenre;
                                _selectedContentType = widget.contentType;
                              }
                            });
                            widget.onStoryTypeChanged(v);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Genre / Poetry Type ─────────────────
                      _buildDropdownSection(
                        label: _isPoetry ? 'POETRY TYPE' : 'GENRE',
                        selectedValue: _selectedGenre,
                        selectedColor: _isPoetry
                            ? _poetryTypeColor(_selectedGenre)
                            : _genreColor(_selectedGenre),
                        selectedIcon: _isPoetry
                            ? (_poetryTypeIcons[_selectedGenre] ??
                                Icons.edit_outlined)
                            : (_genreIcons[_selectedGenre] ??
                                Icons.category_outlined),
                        isExpanded: _genreExpanded,
                        onHeaderTap: () =>
                            setState(() => _genreExpanded = !_genreExpanded),
                        child: _isPoetry
                            ? _buildOptionList(
                                options: _poetryTypeIcons.keys.toList(),
                                selected: _selectedGenre,
                                colorFn: _poetryTypeColor,
                                iconMap: _poetryTypeIcons,
                                onChanged: (v) {
                                  setState(() {
                                    _selectedGenre = v;
                                    _genreExpanded = false;
                                  });
                                  widget.onGenreChanged(v);
                                },
                              )
                            : _buildGenreListWithMore(),
                      ),
                      const SizedBox(height: 12),

                      // ── Content Type / Poetry Theme ─────────
                      if (_isPoetry || _showContentType)
                        _buildDropdownSection(
                          label: _isPoetry ? 'THEME' : 'CONTENT TYPE',
                          selectedValue: _selectedContentType,
                          selectedColor: _isPoetry
                              ? _poetryThemeColor(_selectedContentType)
                              : widget.contentTypeColor(_selectedContentType),
                          selectedIcon: _isPoetry
                              ? (_poetryThemeIcons[_selectedContentType] ??
                                  Icons.favorite_rounded)
                              : (_contentTypeIcons[_selectedContentType] ??
                                  Icons.description_outlined),
                          isExpanded: _contentTypeExpanded,
                          onHeaderTap: () => setState(() =>
                              _contentTypeExpanded = !_contentTypeExpanded),
                          child: _buildOptionList(
                            options: _isPoetry
                                ? _poetryThemeIcons.keys.toList()
                                : widget.contentTypes,
                            selected: _selectedContentType,
                            colorFn: _isPoetry
                                ? _poetryThemeColor
                                : widget.contentTypeColor,
                            iconMap: _isPoetry
                                ? _poetryThemeIcons
                                : _contentTypeIcons,
                            onChanged: (v) {
                              setState(() {
                                _selectedContentType = v;
                                _contentTypeExpanded = false;
                              });
                              widget.onContentTypeChanged(v);
                            },
                          ),
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

  // ── Genre list with primary + "More Genres" expandable ───────────────────

  Widget _buildGenreListWithMore() {
    void onGenreSelected(String v) {
      setState(() {
        _selectedGenre      = v;
        _genreExpanded      = false;
        _moreGenresExpanded = false;
      });
      widget.onGenreChanged(v);
    }

    return Column(
      children: [
        // Primary genres
        ..._primaryGenres.asMap().entries.map((entry) {
          final index  = entry.key;
          final option = entry.value;
          final isLast = index == _primaryGenres.length - 1;

          return _buildOptionRow(
            option:      option,
            isSelected:  _selectedGenre == option,
            color:       _genreColor(option),
            icon:        _genreIcons[option] ?? Icons.category_outlined,
            showDivider: !isLast || _moreGenresExpanded,
            onTap:       () => onGenreSelected(option),
          );
        }),

        // "More Genres" toggle
        GestureDetector(
          onTap: () =>
              setState(() => _moreGenresExpanded = !_moreGenresExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _moreGenresExpanded
                  ? AppTheme.inkUmber.withValues(alpha: 0.06)
                  : Colors.transparent,
              border: Border(
                top: BorderSide(
                  color: AppTheme.inkUmber.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.inkUmber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: AnimatedRotation(
                    turns: _moreGenresExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 15,
                      color: AppTheme.inkUmber.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _moreGenresExpanded ? 'Show Less' : 'More Genres',
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkUmber.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                if (!_moreGenresExpanded)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.inkUmber.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${_moreGenres.length}',
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkUmber.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Expanded more genres list
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _moreGenresExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: _moreGenres.asMap().entries.map((entry) {
              final index  = entry.key;
              final option = entry.value;
              final isLast = index == _moreGenres.length - 1;

              return _buildOptionRow(
                option:      option,
                isSelected:  _selectedGenre == option,
                color:       _genreColor(option),
                icon:        _genreIcons[option] ?? Icons.category_outlined,
                showDivider: !isLast,
                onTap:       () => onGenreSelected(option),
              );
            }).toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Reusable option row ───────────────────────────────────────────────────

  Widget _buildOptionRow({
    required String   option,
    required bool     isSelected,
    required Color    color,
    required IconData icon,
    required bool     showDivider,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : Colors.transparent,
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: AppTheme.inkUmber.withValues(alpha: 0.08),
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.16)
                    : color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                icon,
                size: 13,
                color: isSelected ? color : color.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option,
                style: AppTypography.labelSm.copyWith(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? color
                      : AppTheme.inkEspresso.withValues(alpha: 0.75),
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    size: 11, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  // ── Generic option list (story type, content type, poetry) ───────────────

  Widget _buildOptionList({
    required List<String>           options,
    required String                 selected,
    required Color Function(String) colorFn,
    required Map<String, IconData>  iconMap,
    required Function(String)       onChanged,
  }) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final index  = entry.key;
        final option = entry.value;
        final isLast = index == options.length - 1;

        return _buildOptionRow(
          option:      option,
          isSelected:  selected == option,
          color:       colorFn(option),
          icon:        iconMap[option] ?? Icons.category_outlined,
          showDivider: !isLast,
          onTap:       () => onChanged(option),
        );
      }).toList(),
    );
  }

  // ── Dropdown section shell ────────────────────────────────────────────────

  Widget _buildDropdownSection({
    required String   label,
    required String   selectedValue,
    required Color    selectedColor,
    required IconData selectedIcon,
    required bool     isExpanded,
    required VoidCallback onHeaderTap,
    required Widget   child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            fontSize: 9,
            letterSpacing: 1.0,
            color: AppTheme.inkUmber.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),

        // Header — always visible
        GestureDetector(
          onTap: onHeaderTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isExpanded
                  ? selectedColor.withValues(alpha: 0.10)
                  : AppTheme.inkBgCard,
              borderRadius: BorderRadius.only(
                topLeft:     const Radius.circular(12),
                topRight:    const Radius.circular(12),
                bottomLeft:  Radius.circular(isExpanded ? 0 : 12),
                bottomRight: Radius.circular(isExpanded ? 0 : 12),
              ),
              border: Border.all(
                color: isExpanded
                    ? selectedColor.withValues(alpha: 0.4)
                    : AppTheme.inkUmber.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selectedColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(selectedIcon, size: 14, color: selectedColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedValue.isNotEmpty ? selectedValue : 'Select...',
                    style: AppTypography.labelMd.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkEspresso,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppTheme.inkUmber.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Collapsible body
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Container(
            decoration: BoxDecoration(
              color: AppTheme.inkCanvas,
              borderRadius: const BorderRadius.only(
                bottomLeft:  Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                left:   BorderSide(
                    color: AppTheme.inkUmber.withValues(alpha: 0.15),
                    width: 1.5),
                right:  BorderSide(
                    color: AppTheme.inkUmber.withValues(alpha: 0.15),
                    width: 1.5),
                bottom: BorderSide(
                    color: AppTheme.inkUmber.withValues(alpha: 0.15),
                    width: 1.5),
              ),
            ),
            child: child,
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Story Setup',
                  style: AppTypography.headingSm.copyWith(
                    fontSize: 17,
                    color: AppTheme.inkEspresso,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Genre, type & structure',
                  style: AppTypography.caption
                      .copyWith(color: AppTheme.inkUmber),
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
                color: AppTheme.inkBgCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  size: 15, color: AppTheme.inkUmber),
            ),
          ),
        ],
      ),
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
            color: AppTheme.inkMaroon,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text('Done', style: AppTypography.buttonMedium),
          ),
        ),
      ),
    );
  }
}