import 'package:flutter/material.dart';
import '../../theme/new_app_theme.dart';
import '../../theme/app_typography.dart';
import 'package:flutter_quill/flutter_quill.dart';

// ─────────────────────────────────────────────
//  Shared floating-card input field
// ─────────────────────────────────────────────
class _CardTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextStyle style;
  final TextStyle hintStyle;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final VoidCallback? onChanged;
  final VoidCallback? onSubmitted;
  final TextAlign textAlign;

  const _CardTextField({
    required this.controller,
    required this.hintText,
    required this.style,
    required this.hintStyle,
    this.maxLines = 1,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.textAlign = TextAlign.start,
  });

  @override
  State<_CardTextField> createState() => _CardTextFieldState();
}

class _CardTextFieldState extends State<_CardTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.inkBgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused 
              ? AppTheme.inkTerracotta.withValues(alpha: 0.5)
              : AppTheme.inkMaroon.withValues(alpha: 0.1),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkMaroon.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (_isFocused)
            BoxShadow(
              color: AppTheme.inkTerracotta.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged != null ? (_) => widget.onChanged!() : null,
        onSubmitted: widget.onSubmitted != null ? (_) => widget.onSubmitted!() : null,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: widget.hintStyle,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Shared Quill editor container
// ─────────────────────────────────────────────
class _QuillEditorCard extends StatelessWidget {
  final QuillController controller;
  final FocusNode focusNode;
  final String placeholder;

  const _QuillEditorCard({
    required this.controller,
    required this.focusNode,
    this.placeholder = 'Start writing...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.inkBgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.inkMaroon.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkMaroon.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: QuillEditor(
        controller: controller,
        focusNode: focusNode,
        scrollController: ScrollController(),
        config: QuillEditorConfig(
          placeholder: placeholder,
          expands: false,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Standard (Short Story / General) Editor
// ─────────────────────────────────────────────
class StandardEditorContent extends StatelessWidget {
  final TextEditingController titleController;
  final QuillController bodyController;
  final FocusNode bodyFocusNode;
  final VoidCallback onTitleChanged;
  final Widget metadataBar;

  const StandardEditorContent({
    super.key,
    required this.titleController,
    required this.bodyController,
    required this.bodyFocusNode,
    required this.onTitleChanged,
    required this.metadataBar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardTextField(
          controller: titleController,
          hintText: 'Story title...',
          style: AppTypography.storyTitle.copyWith(
            color: AppTheme.inkEspresso,
          ),
          hintStyle: AppTypography.storyTitle.copyWith(
            color: AppTheme.inkUmber.withValues(alpha: 0.35),
          ),
          maxLines: null,
          textInputAction: TextInputAction.next,
          onChanged: onTitleChanged,
          onSubmitted: bodyFocusNode.requestFocus,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: metadataBar,
        ),
        Expanded(
          child: _QuillEditorCard(
            controller: bodyController,
            focusNode: bodyFocusNode,
            placeholder: 'Begin your story...',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Novel Editor
// ─────────────────────────────────────────────
class NovelEditorContent extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController chapterTitleController;
  final QuillController bodyController;
  final FocusNode bodyFocusNode;
  final VoidCallback onTitleChanged;
  final VoidCallback onChapterTitleChanged;
  final Widget metadataBar;
  final String hintText;

  const NovelEditorContent({
    super.key,
    required this.titleController,
    required this.chapterTitleController,
    required this.bodyController,
    required this.bodyFocusNode,
    required this.onTitleChanged,
    required this.onChapterTitleChanged,
    required this.metadataBar,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardTextField(
          controller: titleController,
          hintText: 'Novel title...',
          style: AppTypography.storyTitle.copyWith(
            color: AppTheme.inkEspresso,
          ),
          hintStyle: AppTypography.storyTitle.copyWith(
            color: AppTheme.inkUmber.withValues(alpha: 0.35),
          ),
          maxLines: null,
          textInputAction: TextInputAction.next,
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: 10),
        _CardTextField(
          controller: chapterTitleController,
          hintText: 'Chapter title...',
          style: AppTypography.headingSm.copyWith(
            color: AppTheme.inkMaroon,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: AppTypography.headingSm.copyWith(
            color: AppTheme.inkUmber.withValues(alpha: 0.35),
            fontWeight: FontWeight.w500,
          ),
          textInputAction: TextInputAction.next,
          onChanged: onChapterTitleChanged,
          onSubmitted: bodyFocusNode.requestFocus,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: metadataBar,
        ),
        Expanded(
          child: _QuillEditorCard(
            controller: bodyController,
            focusNode: bodyFocusNode,
            placeholder: hintText,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Poetry Editor
// ─────────────────────────────────────────────
class PoetryEditorContent extends StatelessWidget {
  final TextEditingController titleController;
  final QuillController bodyController;
  final FocusNode bodyFocusNode;
  final VoidCallback onTitleChanged;
  final Widget metadataBar;

  const PoetryEditorContent({
    super.key,
    required this.titleController,
    required this.bodyController,
    required this.bodyFocusNode,
    required this.onTitleChanged,
    required this.metadataBar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CardTextField(
          controller: titleController,
          hintText: 'Poem title...',
          textAlign: TextAlign.center,
          style: AppTypography.storyTitle.copyWith(
            color: AppTheme.inkMaroon,
            fontStyle: FontStyle.italic,
          ),
          hintStyle: AppTypography.storyTitle.copyWith(
            color: AppTheme.inkGold.withValues(alpha: 0.4),
            fontStyle: FontStyle.italic,
          ),
          maxLines: null,
          textInputAction: TextInputAction.next,
          onChanged: onTitleChanged,
          onSubmitted: bodyFocusNode.requestFocus,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: metadataBar,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _QuillEditorCard(
            controller: bodyController,
            focusNode: bodyFocusNode,
            placeholder: 'Write your poem...',
          ),
        ),
      ],
    );
  }
}