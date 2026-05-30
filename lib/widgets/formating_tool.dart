import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ─── Formatting Toolbar ─────────────────────────────────────────────────────

class FormattingToolbar extends StatelessWidget {
  final VoidCallback? onBold;
  final VoidCallback? onItalic;
  final VoidCallback? onUnderline;
  final VoidCallback? onQuote;

  const FormattingToolbar({
    this.onBold,
    this.onItalic,
    this.onUnderline,
    this.onQuote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Bold',
            onPressed: onBold,
          ),
          _ToolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Italic',
            onPressed: onItalic,
          ),
          _ToolbarButton(
            icon: Icons.format_underline,
            tooltip: 'Underline',
            onPressed: onUnderline,
          ),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: Colors.grey.shade300,
          ),
          _ToolbarButton(
            icon: Icons.format_quote,
            tooltip: 'Quote',
            onPressed: onQuote,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: onPressed != null
                  ? AppTheme.inkEspresso
                  : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Text Formatting Helper ─────────────────────────────────────────────────

class TextFormatter {
  /// Wraps the current selection with the given prefix and suffix.
  /// If nothing is selected, inserts the prefix + suffix and places cursor between them.
  static void wrapSelection(
    TextEditingController controller, {
    required String prefix,
    required String suffix,
  }) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.isValid && !selection.isCollapsed) {
      // Wrap selected text
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.substring(0, selection.start) +
          prefix +
          selectedText +
          suffix +
          text.substring(selection.end);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: selection.end + prefix.length + suffix.length,
      );
    } else {
      // Insert at cursor position
      final cursorPos = selection.baseOffset;
      final newText = text.substring(0, cursorPos) +
          prefix +
          suffix +
          text.substring(cursorPos);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: cursorPos + prefix.length,
      );
    }
  }

  static void bold(TextEditingController controller) =>
      wrapSelection(controller, prefix: '**', suffix: '**');

  static void italic(TextEditingController controller) =>
      wrapSelection(controller, prefix: '_', suffix: '_');

  static void underline(TextEditingController controller) =>
      wrapSelection(controller, prefix: '__', suffix: '__');

  static void quote(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPos);
    final afterCursor = text.substring(cursorPos);

    // Insert blockquote marker at start of current line
    final lastNewline = beforeCursor.lastIndexOf('\n');
    final lineStart = lastNewline == -1 ? 0 : lastNewline + 1;
    final newText = beforeCursor.substring(0, lineStart) +
        '> ' +
        beforeCursor.substring(lineStart) +
        afterCursor;
    controller.text = newText;
    controller.selection = TextSelection.collapsed(
      offset: cursorPos + 2,
    );
  }
}

// ─── Standard Editor ────────────────────────────────────────────────────────

class StandardEditorContent extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final FocusNode bodyFocusNode;
  final VoidCallback onTitleChanged;
  final VoidCallback onBodyChanged;
  final Widget metadataBar;

  const StandardEditorContent({
    required this.titleController,
    required this.bodyController,
    required this.bodyFocusNode,
    required this.onTitleChanged,
    required this.onBodyChanged,
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
            color: Colors.black.withAlpha(20),
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
                TextField(
                  controller: titleController,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.inkEspresso,
                      height: 1.2),
                  decoration: InputDecoration(
                    hintText: 'Story title…',
                    hintStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.inkUmber.withValues(alpha: 0.3)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => bodyFocusNode.requestFocus(),
                  onChanged: (_) => onTitleChanged(),
                ),
                const SizedBox(height: 20),
                metadataBar,
                const SizedBox(height: 12),
                FormattingToolbar(
                  onBold: () => TextFormatter.bold(bodyController),
                  onItalic: () => TextFormatter.italic(bodyController),
                  onUnderline: () => TextFormatter.underline(bodyController),
                  onQuote: () => TextFormatter.quote(bodyController),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: bodyController,
                  focusNode: bodyFocusNode,
                  style: const TextStyle(
                      fontSize: 16, color: AppTheme.inkEspresso, height: 1.8),
                  decoration: InputDecoration(
                    hintText: 'Once upon a time…',
                    hintStyle: TextStyle(
                        fontSize: 16,
                        color: AppTheme.inkUmber.withValues(alpha: 0.35),
                        height: 1.8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  onChanged: (_) => onBodyChanged(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Novel Editor ─────────────────────────────────────────────────────────────

class NovelEditorContent extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController chapterTitleController;
  final TextEditingController bodyController;
  final FocusNode bodyFocusNode;
  final VoidCallback onTitleChanged;
  final VoidCallback onChapterTitleChanged;
  final VoidCallback onBodyChanged;
  final Widget metadataBar;
  final String hintText;

  const NovelEditorContent({
    required this.titleController,
    required this.chapterTitleController,
    required this.bodyController,
    required this.bodyFocusNode,
    required this.onTitleChanged,
    required this.onChapterTitleChanged,
    required this.onBodyChanged,
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
            color: Colors.black.withAlpha(20),
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
                color: AppTheme.inkTerracotta.withAlpha(51),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),

          // Page lines
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  children: List.generate(
                    40,
                    (index) => Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0x11000000),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      color: AppTheme.inkUmber.withAlpha(89),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onChanged: (_) => onTitleChanged(),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: chapterTitleController,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.inkEspresso,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Chapter Title',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: AppTheme.inkUmber.withAlpha(102),
                    ),
                  ),
                  onChanged: (_) => onChapterTitleChanged(),
                ),

                const SizedBox(height: 10),

                metadataBar,

                const SizedBox(height: 12),

                FormattingToolbar(
                  onBold: () => TextFormatter.bold(bodyController),
                  onItalic: () => TextFormatter.italic(bodyController),
                  onUnderline: () => TextFormatter.underline(bodyController),
                  onQuote: () => TextFormatter.quote(bodyController),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: bodyController,
                  focusNode: bodyFocusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 2,
                    color: AppTheme.inkEspresso,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 18,
                      height: 2,
                      color: AppTheme.inkUmber.withAlpha(89),
                    ),
                  ),
                  onChanged: (_) => onBodyChanged(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Poetry Editor ──────────────────────────────────────────────────────────

class PoetryEditorContent extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final FocusNode bodyFocusNode;
  final VoidCallback onTitleChanged;
  final VoidCallback onBodyChanged;
  final Widget metadataBar;

  const PoetryEditorContent({
    required this.titleController,
    required this.bodyController,
    required this.bodyFocusNode,
    required this.onTitleChanged,
    required this.onBodyChanged,
    required this.metadataBar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextField(
          controller: titleController,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.inkEspresso,
              height: 1.2),
          decoration: InputDecoration(
            hintText: 'Poem title…',
            hintStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.inkUmber.withValues(alpha: 0.3)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            filled: false,
          ),
          maxLines: null,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => bodyFocusNode.requestFocus(),
          onChanged: (_) => onTitleChanged(),
        ),
        const SizedBox(height: 20),
        metadataBar,
        const SizedBox(height: 12),
        FormattingToolbar(
          onBold: () => TextFormatter.bold(bodyController),
          onItalic: () => TextFormatter.italic(bodyController),
          onUnderline: () => TextFormatter.underline(bodyController),
          onQuote: () => TextFormatter.quote(bodyController),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: bodyController,
          focusNode: bodyFocusNode,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 16,
              color: AppTheme.inkEspresso,
              height: 2.0,
              fontStyle: FontStyle.italic),
          decoration: InputDecoration(
            hintText: 'Roses are red, Violets are blue…',
            hintStyle: TextStyle(
                fontSize: 16,
                color: AppTheme.inkUmber.withValues(alpha: 0.35),
                height: 2.0,
                fontStyle: FontStyle.italic),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            filled: false,
          ),
          maxLines: null,
          keyboardType: TextInputType.multiline,
          onChanged: (_) => onBodyChanged(),
        ),
      ],
    );
  }
}