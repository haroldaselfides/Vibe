import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              color: Colors.black12,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Story Title
                TextField(
                  controller: titleController,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.inkEspresso,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Story title...',
                    hintStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.inkUmber.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => bodyFocusNode.requestFocus(),
                  onChanged: (_) => onTitleChanged(),
                ),

                const SizedBox(height: 20),

                metadataBar,

                const SizedBox(height: 16),

                // Formatting Toolbar
                QuillSimpleToolbar(
                  configurations: QuillSimpleToolbarConfigurations(
                    controller: bodyController,
                  ),
                ),

                const SizedBox(height: 16),

                // Editor
                SizedBox(
                  height: 500,
                  child: QuillEditor.basic(
                    focusNode: bodyFocusNode,
                    scrollController: ScrollController(),
                    configurations: QuillEditorConfigurations(
                      controller: bodyController,
                      scrollable: true,
                      autoFocus: false,
                      expands: false,
                      padding: EdgeInsets.zero,
                    ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Book spine
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 6,
              decoration: BoxDecoration(
                color: AppTheme.inkTerracotta.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(30, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Novel Title
                TextField(
                  controller: titleController,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.inkEspresso,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Novel title...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: AppTheme.inkUmber.withValues(alpha: 0.35),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  maxLines: null,
                  onChanged: (_) => onTitleChanged(),
                ),

                const SizedBox(height: 12),

                // Chapter Title
                TextField(
                  controller: chapterTitleController,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.inkEspresso,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Chapter Title',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: AppTheme.inkUmber,
                    ),
                  ),
                  onChanged: (_) => onChapterTitleChanged(),
                ),

                const SizedBox(height: 10),

                metadataBar,

                const SizedBox(height: 16),

                // Formatting Toolbar
                QuillSimpleToolbar(
                  configurations: QuillSimpleToolbarConfigurations(
                    controller: bodyController,
                  ),
                ),

                const SizedBox(height: 16),

                // Editor
                SizedBox(
                  height: 500,
                  child: QuillEditor.basic(
                    focusNode: bodyFocusNode,
                    scrollController: ScrollController(),
                    configurations: QuillEditorConfigurations(
                      controller: bodyController,
                      scrollable: true,
                      autoFocus: false,
                      expands: false,
                      padding: EdgeInsets.zero,
                    ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Poem Title
          TextField(
            controller: titleController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.inkEspresso,
              height: 1.2,
            ),
            decoration: InputDecoration(
              hintText: 'Poem title...',
              hintStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.inkUmber.withValues(alpha: 0.3),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: null,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => bodyFocusNode.requestFocus(),
            onChanged: (_) => onTitleChanged(),
          ),

          const SizedBox(height: 20),

          metadataBar,

          const SizedBox(height: 16),

          // Formatting Toolbar
          QuillSimpleToolbar(
            configurations: QuillSimpleToolbarConfigurations(
              controller: bodyController,
            ),
          ),

          const SizedBox(height: 16),

          // Poetry Editor
          SizedBox(
            height: 500,
            child: QuillEditor.basic(
              focusNode: bodyFocusNode,
              scrollController: ScrollController(),
              configurations: QuillEditorConfigurations(
                controller: bodyController,
                scrollable: true,
                autoFocus: false,
                expands: false,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}