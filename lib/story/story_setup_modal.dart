import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StorySetupModal extends StatefulWidget {
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

  const StorySetupModal({
    super.key,
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
  State<StorySetupModal> createState() => _StorySetupModalState();
}

class _StorySetupModalState extends State<StorySetupModal> {
  late String _localSelectedGenre;
  late String _localStoryType;
  late String _localContentType;

  @override
  void initState() {
    super.initState();
    // Initialize local state from props
    _localSelectedGenre = widget.selectedGenre;
    _localStoryType = widget.storyType;
    _localContentType = widget.contentType;
  }

  void _handleGenreChanged(String genre) {
    setState(() {
      _localSelectedGenre = genre;
    });
    widget.onGenreChanged(genre);
  }

  void _handleStoryTypeChanged(String type) {
    setState(() {
      _localStoryType = type;
    });
    widget.onStoryTypeChanged(type);
  }

  void _handleContentTypeChanged(String type) {
    setState(() {
      _localContentType = type;
    });
    widget.onContentTypeChanged(type);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.inkCanvas,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Story Setup',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.inkEspresso,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Story Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.storyTypes.map((type) {
                  final isSelected = _localStoryType == type;

                  return GestureDetector(
                    onTap: () => _handleStoryTypeChanged(type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.storyTypeColor(type).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.storyTypeColor(type),
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: widget.storyTypeColor(type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              const Text(
                'Genre',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.genres.map((genre) {
                  final isSelected = _localSelectedGenre == genre;

                  return GestureDetector(
                    onTap: () => _handleGenreChanged(genre),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.genreColor(genre).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.genreColor(genre),
                        ),
                      ),
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: widget.genreColor(genre),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_localStoryType == 'Novel') ...[
                const SizedBox(height: 24),

                const Text(
                  'Content Type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.contentTypes.map((type) {
                    final isSelected = _localContentType == type;

                    return GestureDetector(
                      onTap: () => _handleContentTypeChanged(type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.contentTypeColor(type)
                                  .withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.contentTypeColor(type),
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: widget.contentTypeColor(type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.inkTerracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}