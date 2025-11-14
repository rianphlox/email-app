/// Processes email quotes and converts them to styled HTML
/// Based on Thunderbird's EmailSectionExtractor and EmailTextToHtml
class QuoteProcessor {


  /// Converts plain text email to HTML with quote styling
  static String convertTextToHtml(String plainText, {bool useDarkMode = false}) {
    if (plainText.isEmpty) return '';

    final lines = plainText.split('\n');
    final processedLines = <String>[];
    bool inQuote = false;

    for (final line in lines) {
      final isQuoteLine = _getQuoteLevel(line) > 0;

      if (isQuoteLine && !inQuote) {
        // Start of a quote block
        inQuote = true;
        processedLines.add('''
          <div class="gmail_quote">
            <input type="checkbox" id="gmail_quote_toggle" class="gmail_quote_toggle">
            <label for="gmail_quote_toggle" class="gmail_quote_label">...</label>
            <div class="gmail_quote_content">
        ''');
      } else if (!isQuoteLine && inQuote) {
        // End of a quote block
        inQuote = false;
        processedLines.add('</div></div>');
      }

      if (inQuote) {
        final cleanLine = _cleanQuoteLine(line, _getQuoteLevel(line));
        processedLines.add('<div>$cleanLine</div>');
      } else {
        processedLines.add('<div>${_escapeHtml(line)}</div>');
      }
    }

    if (inQuote) {
      // Close the last quote block if the email ends with it
      processedLines.add('</div></div>');
    }

    return _wrapInHtml(processedLines.join('\n'), useDarkMode);
  }

  /// Extracts preview text by removing quotes and signatures
  static String extractPreviewText(String content, {int maxLength = 200}) {
    if (content.isEmpty) return '';

    // Remove HTML tags if present
    String text = content.replaceAll(RegExp(r'<[^>]*>'), '');

    // Split into lines
    final lines = text.split('\n');
    final previewLines = <String>[];

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Skip empty lines
      if (trimmedLine.isEmpty) continue;

      // Skip quoted content (lines starting with >)
      if (trimmedLine.startsWith('>')) continue;

      // Skip common signature patterns
      if (_isSignatureLine(trimmedLine)) break;

      previewLines.add(trimmedLine);

      // Stop if we have enough content
      if (previewLines.join(' ').length > maxLength) break;
    }

    String preview = previewLines.join(' ');

    // Truncate to max length
    if (preview.length > maxLength) {
      preview = preview.substring(0, maxLength);
      // Find last complete word
      final lastSpace = preview.lastIndexOf(' ');
      if (lastSpace > maxLength - 20) {
        preview = preview.substring(0, lastSpace);
      }
      preview += '...';
    }

    return preview;
  }

  /// Determines the quote level of a line (0 = not quoted)
  static int _getQuoteLevel(String line) {
    int level = 0;
    int index = 0;

    while (index < line.length) {
      final char = line[index];

      if (char == '>') {
        level++;
        index++;
      } else if (char == ' ' || char == '\t') {
        index++;
      } else {
        break;
      }
    }

    return level;
  }

  /// Removes quote prefixes from a line
  static String _cleanQuoteLine(String line, int quoteLevel) {
    if (quoteLevel == 0) return _escapeHtml(line);

    String cleaned = line;
    int removedChars = 0;

    for (int i = 0; i < quoteLevel && removedChars < line.length; i++) {
      // Find and remove the next '>' and any following space
      int quoteIndex = cleaned.indexOf('>', removedChars);
      if (quoteIndex != -1) {
        cleaned = cleaned.substring(0, quoteIndex) + cleaned.substring(quoteIndex + 1);
        // Remove one space after '>' if present
        if (quoteIndex < cleaned.length && cleaned[quoteIndex] == ' ') {
          cleaned = cleaned.substring(0, quoteIndex) + cleaned.substring(quoteIndex + 1);
        }
      }
    }

    return _escapeHtml(cleaned.trimLeft());
  }

  /// Checks if a line looks like a signature
  static bool _isSignatureLine(String line) {
    final signaturePatterns = [
      RegExp(r'^--\s*$'), // Standard signature delimiter
      RegExp(r'^_{3,}'), // Underscores
      RegExp(r'^-{3,}'), // Dashes
      RegExp(r'^\s*Sent from my', caseSensitive: false),
      RegExp(r'^\s*Get Outlook for', caseSensitive: false),
      RegExp(r'^\s*Best regards?', caseSensitive: false),
      RegExp(r'^\s*Sincerely', caseSensitive: false),
      RegExp(r'^\s*Thanks?', caseSensitive: false),
    ];

    return signaturePatterns.any((pattern) => pattern.hasMatch(line));
  }

  /// Escapes HTML characters
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Wraps content in proper HTML structure
  static String _wrapInHtml(String content, bool useDarkMode) {
    final cssStyle = useDarkMode ? _getDarkModeCSS() : _getLightModeCSS();

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    $cssStyle
  </style>
</head>
<body>
  $content
</body>
</html>
''';
  }

  /// CSS for light mode
  static String _getLightModeCSS() {
    return '''
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 16px;
      line-height: 1.6;
      color: #333333;
      background-color: #ffffff;
      margin: 16px;
      padding: 0;
    }
    div {
      margin-bottom: 4px;
    }
    ''';
  }

  /// CSS for dark mode
  static String _getDarkModeCSS() {
    return '''
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 16px;
      line-height: 1.6;
      color: #F3F3F3;
      background-color: #121212;
      margin: 16px;
      padding: 0;
    }
    div {
      margin-bottom: 4px;
    }
    a {
      color: #CCFF33;
    }
    a:visited {
      color: #BB86FC;
    }
    ''';
  }
}