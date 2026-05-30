// lib/main_tabs/post/text_formatter.dart

class TextFormatting {
  String text;
  int startPosition;
  int endPosition;

  TextFormatting({
    required this.text,
    required this.startPosition,
    required this.endPosition,
  });

  // Make selected text bold
  String makeBold() {
    if (startPosition == endPosition) return text;
    
    final selectedText = text.substring(startPosition, endPosition);
    final beforeText = text.substring(0, startPosition);
    final afterText = text.substring(endPosition);
    
    return '$beforeText**$selectedText**$afterText';
  }

  // Make selected text italic
  String makeItalic() {
    if (startPosition == endPosition) return text;
    
    final selectedText = text.substring(startPosition, endPosition);
    final beforeText = text.substring(0, startPosition);
    final afterText = text.substring(endPosition);
    
    return '$beforeText*$selectedText*$afterText';
  }

  // Add bullet point
  String addBulletList() {
    final lines = text.split('\n');
    final updatedLines = lines.map((line) => '• $line').toList();
    return updatedLines.join('\n');
  }

  // Add numbered list
  String addNumberedList() {
    final lines = text.split('\n');
    final updatedLines = lines.asMap().entries.map((entry) {
      return '${entry.key + 1}. ${entry.value}';
    }).toList();
    return updatedLines.join('\n');
  }
}