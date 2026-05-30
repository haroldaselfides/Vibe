
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_quill/flutter_quill.dart';

// ─────────────────────────────────────────────
//  Shared floating-card input field
// ─────────────────────────────────────────────
class _CardTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: controller,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        textInputAction: textInputAction,
        onChanged: onChanged != null ? (_) => onChanged!() : null,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: hintStyle,
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
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.inkEspresso,
            height: 1.2,
          ),
          hintStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.inkUmber.withAlpha(76),
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
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: QuillEditor(
              focusNode: bodyFocusNode,
              scrollController: ScrollController(),
              configurations: QuillEditorConfigurations(
                controller: bodyController,
                readOnly: false,
                autoFocus: false,
                scrollable: true,
                expands: true,
                padding: EdgeInsets.zero,
                placeholder: 'Start writing your story...',
              ),
            ),
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
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.inkEspresso,
            height: 1.2,
          ),
          hintStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.inkUmber.withAlpha(76),
          ),
          maxLines: null,
          textInputAction: TextInputAction.next,
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: 10),
        _CardTextField(
          controller: chapterTitleController,
          hintText: 'Chapter title...',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.inkEspresso,
          ),
          hintStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.inkUmber.withAlpha(100),
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
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: QuillEditor(
              focusNode: bodyFocusNode,
              scrollController: ScrollController(),
              configurations: QuillEditorConfigurations(
                controller: bodyController,
                readOnly: false,
                autoFocus: false,
                scrollable: true,
                expands: true,
                padding: EdgeInsets.zero,
                placeholder: 'Start writing your story...',
              ),
            ),
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
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.inkEspresso,
            height: 1.2,
          ),
          hintStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.inkUmber.withAlpha(76),
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
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: QuillEditor(
              focusNode: bodyFocusNode,
              scrollController: ScrollController(),
              configurations: QuillEditorConfigurations(
                controller: bodyController,
                readOnly: false,
                autoFocus: false,
                scrollable: true,
                expands: true,
                padding: EdgeInsets.zero,
                placeholder: 'Start writing your story...',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
