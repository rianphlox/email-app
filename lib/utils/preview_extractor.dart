import 'package:html/parser.dart' as html_parser;

/// Extracts preview text from email content similar to Thunderbird's PreviewTextExtractor
class PreviewExtractor {
  static const int _defaultMaxLength = 200;
  static const int _minWordLength = 3;

  /// Extracts preview text from HTML or plain text email content
  static String extractPreview({
    String? htmlContent,
    String? textContent,
    int maxLength = _defaultMaxLength,
  }) {
    String content;

    if (htmlContent != null && htmlContent.isNotEmpty) {
      content = _extractTextFromHtml(htmlContent);
    } else if (textContent != null && textContent.isNotEmpty) {
      content = textContent;
    } else {
      return '';
    }

    return _processPreviewText(content, maxLength);
  }

  /// Extracts plain text from HTML content
  static String _extractTextFromHtml(String htmlContent) {
    try {
      final document = html_parser.parse(htmlContent);

      // Remove script and style elements completely
      document.querySelectorAll('script, style').forEach((element) {
        element.remove();
      });

      // Get text content
      String text = document.body?.text ?? document.documentElement?.text ?? '';

      // Clean up whitespace
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      return text;
    } catch (e) {
      // If HTML parsing fails, treat as plain text
      return htmlContent.replaceAll(RegExp(r'<[^>]*>'), '');
    }
  }

  /// Processes text to create a meaningful preview
  static String _processPreviewText(String content, int maxLength) {
    if (content.isEmpty) return '';

    final lines = content.split('\n');
    final meaningfulLines = <String>[];

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Skip empty lines
      if (trimmedLine.isEmpty) continue;

      // Skip quoted content (lines starting with >)
      if (_isQuotedLine(trimmedLine)) continue;

      // Skip signature lines
      if (_isSignatureLine(trimmedLine)) break;

      // Skip headers and metadata
      if (_isHeaderLine(trimmedLine)) continue;

      // Skip URLs that are on their own line
      if (_isStandaloneUrl(trimmedLine)) continue;

      meaningfulLines.add(trimmedLine);

      // Stop collecting if we have enough content
      final currentLength = meaningfulLines.join(' ').length;
      if (currentLength > maxLength) break;
    }

    if (meaningfulLines.isEmpty) {
      // Fallback: use first non-empty line if no meaningful content found
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty && !_isQuotedLine(trimmedLine)) {
          meaningfulLines.add(trimmedLine);
          break;
        }
      }
    }

    String preview = meaningfulLines.join(' ').trim();

    // Clean up the preview text
    preview = _cleanPreviewText(preview);

    // Truncate to max length intelligently
    if (preview.length > maxLength) {
      preview = _truncateIntelligently(preview, maxLength);
    }

    return preview;
  }

  /// Checks if a line is quoted content
  static bool _isQuotedLine(String line) {
    return line.startsWith('>') ||
           line.startsWith('|') ||
           line.contains('wrote:') ||
           line.contains('said:') ||
           line.contains('On ') && line.contains('wrote:');
  }

  /// Checks if a line is part of an email signature
  static bool _isSignatureLine(String line) {
    final signaturePatterns = [
      RegExp(r'^--\s*$'),
      RegExp(r'^_{3,}'),
      RegExp(r'^-{3,}'),
      RegExp(r'^\s*Sent from my', caseSensitive: false),
      RegExp(r'^\s*Get Outlook for', caseSensitive: false),
      RegExp(r'^\s*Best regards?', caseSensitive: false),
      RegExp(r'^\s*Sincerely', caseSensitive: false),
      RegExp(r'^\s*Thanks?', caseSensitive: false),
      RegExp(r'^\s*Cheers', caseSensitive: false),
      RegExp(r'^\s*Kind regards', caseSensitive: false),
      RegExp(r'^\s*Warm regards', caseSensitive: false),
      RegExp(r'^\s*Yours truly', caseSensitive: false),
      RegExp(r'^\s*Regards', caseSensitive: false),
    ];

    return signaturePatterns.any((pattern) => pattern.hasMatch(line));
  }

  /// Checks if a line is an email header
  static bool _isHeaderLine(String line) {
    final headerPatterns = [
      RegExp(r'^From:', caseSensitive: false),
      RegExp(r'^To:', caseSensitive: false),
      RegExp(r'^Subject:', caseSensitive: false),
      RegExp(r'^Date:', caseSensitive: false),
      RegExp(r'^Cc:', caseSensitive: false),
      RegExp(r'^Bcc:', caseSensitive: false),
      RegExp(r'^Reply-To:', caseSensitive: false),
      RegExp(r'^Sent:', caseSensitive: false),
      RegExp(r'^Received:', caseSensitive: false),
    ];

    return headerPatterns.any((pattern) => pattern.hasMatch(line));
  }

  /// Checks if a line is just a standalone URL
  static bool _isStandaloneUrl(String line) {
    final urlPattern = RegExp(r'^https?://[^\s]+$', caseSensitive: false);
    return urlPattern.hasMatch(line.trim());
  }

  /// Cleans up preview text by removing unwanted characters and patterns
  static String _cleanPreviewText(String text) {
    // Remove email addresses that might clutter the preview
    text = text.replaceAll(RegExp(r'\S+@\S+\.\S+'), '');

    // Remove excessive punctuation
    text = text.replaceAll(RegExp(r'[.]{3,}'), '...');
    text = text.replaceAll(RegExp(r'[-]{3,}'), '---');
    text = text.replaceAll(RegExp(r'[=]{3,}'), '===');

    // Remove common email artifacts
    text = text.replaceAll(RegExp(r'\[cid:[^\]]+\]'), '');
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Clean up whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove very short words that don't add meaning
    final words = text.split(' ');
    final meaningfulWords = words.where((word) {
      return word.length >= _minWordLength ||
             word.toLowerCase() == 'i' ||
             word.toLowerCase() == 'a' ||
             RegExp(r'^\d+$').hasMatch(word);
    });

    return meaningfulWords.join(' ');
  }

  /// Truncates text intelligently at word boundaries
  static String _truncateIntelligently(String text, int maxLength) {
    if (text.length <= maxLength) return text;

    // Find the last complete sentence within the limit
    int lastSentenceEnd = -1;
    final sentenceEnders = ['.', '!', '?'];

    for (int i = 0; i < maxLength - 20 && i < text.length; i++) {
      if (sentenceEnders.contains(text[i]) &&
          i + 1 < text.length &&
          text[i + 1] == ' ') {
        lastSentenceEnd = i + 1;
      }
    }

    if (lastSentenceEnd > maxLength * 0.7) {
      // If we found a good sentence break, use it
      return text.substring(0, lastSentenceEnd).trim();
    }

    // Otherwise, find the last complete word
    int cutoff = maxLength;
    while (cutoff > 0 && text[cutoff] != ' ') {
      cutoff--;
    }

    if (cutoff < maxLength * 0.8) {
      // If the word break is too far back, just cut at max length
      cutoff = maxLength;
    }

    String truncated = text.substring(0, cutoff).trim();

    // Add ellipsis if we truncated
    if (cutoff < text.length) {
      truncated += '...';
    }

    return truncated;
  }

  /// Gets a snippet of text around specific keywords (useful for search)
  static String extractSnippet({
    required String content,
    required String keyword,
    int contextLength = 100,
  }) {
    final lowerContent = content.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();

    final index = lowerContent.indexOf(lowerKeyword);
    if (index == -1) {
      return extractPreview(textContent: content, maxLength: contextLength * 2);
    }

    final start = (index - contextLength / 2).clamp(0, content.length).toInt();
    final end = (index + keyword.length + contextLength / 2).clamp(0, content.length).toInt();

    String snippet = content.substring(start, end);

    if (start > 0) snippet = '...$snippet';
    if (end < content.length) snippet = '$snippet...';

    return snippet.trim();
  }
}