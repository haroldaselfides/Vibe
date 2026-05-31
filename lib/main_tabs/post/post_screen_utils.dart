import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Utility class for post screen helpers
class PostScreenUtils {
  /// Get genre tag color
  static Color getGenreTagColor(String genre) {
    switch (genre) {
      case 'Romance':
        return AppTheme.inkBlush;
      case 'Mystery':
        return AppTheme.inkIndigo;
      case 'Fantasy':
        return AppTheme.inkSage;
      case 'Sci-Fi':
        return AppTheme.inkTeal;
      default:
        return AppTheme.inkUmber;
    }
  }

  /// Get story type tag color
  static Color getStoryTypeTagColor(String storyType) {
    switch (storyType) {
      case 'Novel':
        return AppTheme.inkIndigo;
      case 'Poetry':
        return AppTheme.inkBlush;
      case 'Short Story':
        return AppTheme.inkSage;
      case 'Flash Fiction':
        return AppTheme.inkTeal;
      default:
        return AppTheme.inkUmber;
    }
  }

  /// Get content type color
  static Color getContentTypeColor(String contentType) {
    switch (contentType) {
      case 'Prologue':
        return AppTheme.inkTeal;
      case 'Epilogue':
        return AppTheme.inkTerracotta;
      case 'Chapter':
        return AppTheme.inkIndigo;
      default:
        return AppTheme.inkUmber;
    }
  }

  /// Get novel hint text based on content type
  static String getNovelHintText(String contentType) {
    switch (contentType) {
      case 'Prologue':
        return 'Set the stage for your story…';
      case 'Epilogue':
        return 'Wrap up your story…';
      default:
        return 'Start writing your chapter here…';
    }
  }

  /// Calculate word count from text
  static int getWordCount(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return 0;
    return trimmedText.split(RegExp(r'\s+')).length;
  }

  /// Get icon for story type (for potential future use)
  static IconData getStoryTypeIcon(String storyType) {
    switch (storyType) {
      case 'Novel':
        return Icons.menu_book;
      case 'Poetry':
        return Icons.edit;
      case 'Short Story':
        return Icons.description;
      case 'Flash Fiction':
        return Icons.flash_on;
      default:
        return Icons.description;
    }
  }

  /// Get icon for genre (for potential future use)
  static IconData getGenreIcon(String genre) {
    switch (genre) {
      case 'Romance':
        return Icons.favorite;
      case 'Mystery':
        return Icons.search;
      case 'Fantasy':
        return Icons.auto_awesome;
      case 'Sci-Fi':
        return Icons.rocket_launch;
      case 'Drama':
        return Icons.theater_comedy;
      case 'Horror':
        return Icons.dark_mode;
      case 'Thriller':
        return Icons.local_police;
      default:
        return Icons.category;
    }
  }

  /// Get icon for content type (for potential future use)
  static IconData getContentTypeIcon(String contentType) {
    switch (contentType) {
      case 'Prologue':
        return Icons.menu_book;
      case 'Epilogue':
        return Icons.flag;
      case 'Chapter':
        return Icons.description;
      default:
        return Icons.description;
    }
  }
}