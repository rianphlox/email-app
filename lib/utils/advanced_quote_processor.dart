
/// Advanced quoted text processor that provides Gmail-like quote handling
/// with collapsible sections and smart text extraction
class AdvancedQuoteProcessor {

  /// Processes email content to identify and handle quoted text
  static ProcessedEmailContent processEmailContent(String content, {
    bool isHtml = false,
    bool useDarkMode = false,
  }) {
    if (content.isEmpty) {
      return ProcessedEmailContent.empty();
    }

    String plainText = isHtml ? _htmlToPlainText(content) : content;
    final sections = _extractEmailSections(plainText);

    return ProcessedEmailContent(
      originalContent: content,
      processedHtml: _generateInteractiveHtml(sections, useDarkMode),
      previewText: _generatePreview(sections),
      hasQuotedText: sections.any((section) => section.type == EmailSectionType.quoted),
      hasSignature: sections.any((section) => section.type == EmailSectionType.signature),
      sections: sections,
    );
  }

  /// Extracts different sections from email content
  static List<EmailSection> _extractEmailSections(String plainText) {
    final lines = plainText.split('\n');
    final sections = <EmailSection>[];

    var currentSection = StringBuffer();
    var currentType = EmailSectionType.original;
    var quoteLevel = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineQuoteLevel = _getQuoteLevel(line);

      // Detect section changes
      EmailSectionType? newType;

      if (_isReplyHeaderLine(line)) {
        newType = EmailSectionType.replyHeader;
      } else if (lineQuoteLevel > 0) {
        newType = EmailSectionType.quoted;
      } else if (_isSignatureLine(line, lines, i)) {
        newType = EmailSectionType.signature;
      } else if (_isForwardHeaderLine(line)) {
        newType = EmailSectionType.forwardHeader;
      } else if (currentType != EmailSectionType.original) {
        newType = EmailSectionType.original;
      }

      // If section type changed, save current section and start new one
      if (newType != null && newType != currentType) {
        if (currentSection.isNotEmpty) {
          sections.add(EmailSection(
            type: currentType,
            content: currentSection.toString().trimRight(),
            quoteLevel: quoteLevel,
          ));
        }
        currentSection.clear();
        currentType = newType;
        quoteLevel = lineQuoteLevel;
      }

      // Add line to current section
      currentSection.writeln(line);
    }

    // Add final section
    if (currentSection.isNotEmpty) {
      sections.add(EmailSection(
        type: currentType,
        content: currentSection.toString().trimRight(),
        quoteLevel: quoteLevel,
      ));
    }

    return _mergeSimilarSections(sections);
  }

  /// Merges adjacent sections of the same type
  static List<EmailSection> _mergeSimilarSections(List<EmailSection> sections) {
    if (sections.length <= 1) return sections;

    final merged = <EmailSection>[];
    EmailSection? current = sections.first;

    for (int i = 1; i < sections.length; i++) {
      final next = sections[i];

      // Merge if same type and similar quote level
      if (current!.type == next.type &&
          (current.quoteLevel == next.quoteLevel ||
           current.type == EmailSectionType.original)) {
        current = EmailSection(
          type: current.type,
          content: '${current.content}\n${next.content}',
          quoteLevel: current.quoteLevel,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }

    if (current != null) merged.add(current);
    return merged;
  }

  /// Generates interactive HTML with collapsible quotes
  static String _generateInteractiveHtml(List<EmailSection> sections, bool useDarkMode) {
    final html = StringBuffer();

    html.write(_getHtmlHeader(useDarkMode));

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];

      switch (section.type) {
        case EmailSectionType.original:
          html.write(_formatOriginalSection(section));
          break;

        case EmailSectionType.quoted:
          final isLastQuoted = i == sections.length - 1 ||
                               sections[i + 1].type != EmailSectionType.quoted;
          html.write(_formatQuotedSection(section, i, isLastQuoted, useDarkMode));
          break;

        case EmailSectionType.replyHeader:
          html.write(_formatReplyHeader(section, useDarkMode));
          break;

        case EmailSectionType.forwardHeader:
          html.write(_formatForwardHeader(section, useDarkMode));
          break;

        case EmailSectionType.signature:
          html.write(_formatSignature(section, useDarkMode));
          break;
      }
    }

    html.write(_getHtmlFooter());

    return html.toString();
  }

  /// Formats original (non-quoted) email content
  static String _formatOriginalSection(EmailSection section) {
    final escapedContent = _escapeHtml(section.content);
    return '''
      <div class="original-content">
        ${_formatPlainTextAsHtml(escapedContent)}
      </div>
    ''';
  }

  /// Formats quoted email content with collapsible UI
  static String _formatQuotedSection(EmailSection section, int index, bool isLast, bool useDarkMode) {
    final escapedContent = _escapeHtml(section.content);
    final previewLines = section.content.split('\n').take(2).join(' ').trim();
    final cleanPreview = _cleanQuotePrefix(previewLines);

    return '''
      <div class="quoted-section" data-quote-level="${section.quoteLevel}">
        <div class="quote-toggle-container">
          <button class="quote-toggle" onclick="toggleQuote('quote-$index')" aria-expanded="false">
            <span class="toggle-icon">⋯</span>
            <span class="quote-preview">${_escapeHtml(cleanPreview)}</span>
            <span class="show-text">Show quoted text</span>
          </button>
        </div>
        <div class="quote-content" id="quote-$index" style="display: none;">
          ${_formatQuotedText(escapedContent, section.quoteLevel)}
        </div>
      </div>
    ''';
  }

  /// Formats reply header (e.g., "On Mon, Jan 1, 2024 at 1:00 PM, John wrote:")
  static String _formatReplyHeader(EmailSection section, bool useDarkMode) {
    return '''
      <div class="reply-header">
        ${_escapeHtml(section.content)}
      </div>
    ''';
  }

  /// Formats forward header
  static String _formatForwardHeader(EmailSection section, bool useDarkMode) {
    return '''
      <div class="forward-header">
        ${_escapeHtml(section.content)}
      </div>
    ''';
  }

  /// Formats email signature
  static String _formatSignature(EmailSection section, bool useDarkMode) {
    return '''
      <div class="signature">
        ${_formatPlainTextAsHtml(_escapeHtml(section.content))}
      </div>
    ''';
  }

  /// Formats quoted text with proper indentation
  static String _formatQuotedText(String content, int quoteLevel) {
    final lines = content.split('\n');
    final formattedLines = lines.map((line) {
      final cleanLine = _cleanQuotePrefix(line);
      return '<div class="quote-line" data-level="$quoteLevel">${_escapeHtml(cleanLine)}</div>';
    }).join('');

    return formattedLines;
  }

  /// Formats plain text as HTML with proper line breaks
  static String _formatPlainTextAsHtml(String text) {
    return text
        .split('\n')
        .map((line) => line.trim().isEmpty ? '<br>' : '<div>${line}</div>')
        .join('');
  }

  /// Generates preview text without quotes and signatures
  static String _generatePreview(List<EmailSection> sections) {
    final originalSections = sections
        .where((section) => section.type == EmailSectionType.original)
        .map((section) => section.content.trim())
        .where((content) => content.isNotEmpty);

    if (originalSections.isEmpty) return '';

    String preview = originalSections.join(' ');

    // Clean up and truncate
    preview = preview.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (preview.length > 150) {
      preview = preview.substring(0, 150);
      final lastSpace = preview.lastIndexOf(' ');
      if (lastSpace > 130) {
        preview = preview.substring(0, lastSpace);
      }
      preview += '...';
    }

    return preview;
  }

  /// Detects reply header lines
  static bool _isReplyHeaderLine(String line) {
    final replyPatterns = [
      RegExp(r'On .+,.*wrote:', caseSensitive: false),
      RegExp(r'Am .+schrieb.*:', caseSensitive: false), // German
      RegExp(r'Le .+a écrit.*:', caseSensitive: false), // French
      RegExp(r'^From:.*', caseSensitive: false),
      RegExp(r'^\s*>\s*From:.*', caseSensitive: false),
    ];

    return replyPatterns.any((pattern) => pattern.hasMatch(line.trim()));
  }

  /// Detects forward header lines
  static bool _isForwardHeaderLine(String line) {
    final forwardPatterns = [
      RegExp(r'---------- Forwarded message', caseSensitive: false),
      RegExp(r'Begin forwarded message', caseSensitive: false),
      RegExp(r'Original Message', caseSensitive: false),
    ];

    return forwardPatterns.any((pattern) => pattern.hasMatch(line.trim()));
  }

  /// Detects signature lines with context
  static bool _isSignatureLine(String line, List<String> allLines, int index) {
    final trimmedLine = line.trim();

    // Standard signature delimiter
    if (trimmedLine == '--') return true;

    // Common signature patterns
    final signaturePatterns = [
      RegExp(r'^_{3,}'), // Underscores
      RegExp(r'^-{3,}'), // Dashes
      RegExp(r'^\s*Sent from my', caseSensitive: false),
      RegExp(r'^\s*Get Outlook for', caseSensitive: false),
      RegExp(r'^\s*Best regards?', caseSensitive: false),
      RegExp(r'^\s*Sincerely', caseSensitive: false),
      RegExp(r'^\s*Thanks?\s*,?\s*$', caseSensitive: false),
      RegExp(r'^\s*Cheers?\s*,?\s*$', caseSensitive: false),
    ];

    if (signaturePatterns.any((pattern) => pattern.hasMatch(trimmedLine))) {
      return true;
    }

    // Context-based detection: short lines near end of email
    if (index > allLines.length * 0.7 && // In last 30% of email
        trimmedLine.length < 50 && // Short line
        trimmedLine.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// Gets the quote level (number of > prefixes)
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
  static String _cleanQuotePrefix(String line) {
    return line.replaceAll(RegExp(r'^(\s*>+\s*)+'), '').trimLeft();
  }

  /// Converts HTML to plain text
  static String _htmlToPlainText(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#x27;'), "'");
  }

  /// Escapes HTML special characters
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Gets HTML header with styling and JavaScript
  static String _getHtmlHeader(bool useDarkMode) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    ${_getCss(useDarkMode)}
  </style>
</head>
<body>
    ''';
  }

  /// Gets HTML footer with JavaScript
  static String _getHtmlFooter() {
    return '''
  <script>
    ${_getJavaScript()}
  </script>
</body>
</html>
    ''';
  }

  /// Gets CSS for styling quoted text
  static String _getCss(bool useDarkMode) {
    final bgColor = useDarkMode ? '#1c1c1e' : '#ffffff';
    final textColor = useDarkMode ? '#ffffff' : '#000000';
    final quoteBg = useDarkMode ? '#2c2c2e' : '#f8f9fa';
    final borderColor = useDarkMode ? '#404040' : '#e1e4e8';
    final buttonBg = useDarkMode ? '#3a3a3c' : '#f1f3f4';
    final buttonHover = useDarkMode ? '#4a4a4c' : '#e8eaed';

    return '''
      html, body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        font-size: 14px;
        line-height: 1.6;
        margin: 0;
        padding: 16px;
        background-color: $bgColor;
        color: $textColor;
        word-wrap: break-word;
        overflow-x: hidden;
        box-sizing: border-box;
        -webkit-text-size-adjust: 100%;
        -webkit-font-smoothing: antialiased;
      }

      * {
        box-sizing: border-box;
        max-width: 100%;
      }

      img {
        max-width: 100% !important;
        height: auto !important;
        display: block;
        margin: 8px auto;
      }

      table {
        max-width: 100% !important;
        table-layout: fixed;
        border-collapse: collapse;
        word-wrap: break-word;
      }

      td, th {
        word-wrap: break-word;
        overflow-wrap: break-word;
        max-width: 0;
        padding: 4px 8px;
      }

      pre {
        white-space: pre-wrap;
        word-wrap: break-word;
        overflow-x: auto;
        max-width: 100%;
      }

      .original-content {
        margin-bottom: 16px;
      }

      .quoted-section {
        margin: 12px 0;
      }

      .quote-toggle-container {
        margin: 8px 0;
      }

      .quote-toggle {
        background: $buttonBg;
        border: 1px solid $borderColor;
        border-radius: 6px;
        padding: 8px 12px;
        font-size: 13px;
        color: $textColor;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 8px;
        transition: background-color 0.2s;
        width: 100%;
        text-align: left;
      }

      .quote-toggle:hover {
        background: $buttonHover;
      }

      .toggle-icon {
        font-weight: bold;
        font-size: 16px;
      }

      .quote-preview {
        flex: 1;
        color: ${useDarkMode ? '#a0a0a0' : '#666666'};
        font-style: italic;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .show-text {
        color: ${useDarkMode ? '#66b3ff' : '#1a73e8'};
        font-size: 12px;
        white-space: nowrap;
      }

      .quote-content {
        background: $quoteBg;
        border-left: 4px solid ${useDarkMode ? '#66b3ff' : '#1a73e8'};
        padding: 12px 16px;
        margin: 8px 0;
        border-radius: 0 4px 4px 0;
      }

      .quote-line {
        margin: 2px 0;
      }

      .quote-line[data-level="2"] {
        margin-left: 16px;
        border-left: 2px solid $borderColor;
        padding-left: 8px;
      }

      .quote-line[data-level="3"] {
        margin-left: 32px;
        border-left: 2px solid $borderColor;
        padding-left: 8px;
      }

      .reply-header, .forward-header {
        font-size: 13px;
        color: ${useDarkMode ? '#a0a0a0' : '#666666'};
        margin: 16px 0 8px 0;
        padding: 8px 12px;
        background: $quoteBg;
        border-radius: 4px;
        border-left: 4px solid ${useDarkMode ? '#ff9500' : '#fbbc04'};
      }

      .signature {
        margin-top: 16px;
        padding-top: 12px;
        border-top: 1px solid $borderColor;
        font-size: 13px;
        color: ${useDarkMode ? '#a0a0a0' : '#666666'};
      }

      /* Responsive design */
      @media (max-width: 600px) {
        body {
          padding: 12px;
        }

        .quote-toggle {
          padding: 12px;
        }

        .quote-content {
          padding: 12px;
        }
      }
    ''';
  }

  /// Gets JavaScript for quote toggling
  static String _getJavaScript() {
    return '''
      function toggleQuote(elementId) {
        const quoteContent = document.getElementById(elementId);
        const button = document.querySelector('[onclick*="' + elementId + '"]');
        const isVisible = quoteContent.style.display !== 'none';

        if (isVisible) {
          quoteContent.style.display = 'none';
          button.setAttribute('aria-expanded', 'false');
          button.querySelector('.toggle-icon').textContent = '⋯';
          button.querySelector('.show-text').textContent = 'Show quoted text';
        } else {
          quoteContent.style.display = 'block';
          button.setAttribute('aria-expanded', 'true');
          button.querySelector('.toggle-icon').textContent = '⋯';
          button.querySelector('.show-text').textContent = 'Hide quoted text';
        }

        // Notify Flutter about content change
        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
          window.flutter_inappwebview.callHandler('onQuoteToggled', {
            quoteId: elementId,
            expanded: !isVisible
          });
        }
      }

      // Auto-expand if there's only one quote and it's short
      document.addEventListener('DOMContentLoaded', function() {
        const quotes = document.querySelectorAll('.quote-content');
        if (quotes.length === 1) {
          const content = quotes[0].textContent || '';
          if (content.length < 200) {
            const button = document.querySelector('.quote-toggle');
            if (button) {
              toggleQuote(quotes[0].id);
            }
          }
        }
      });
    ''';
  }
}

/// Represents the result of processing email content
class ProcessedEmailContent {
  final String originalContent;
  final String processedHtml;
  final String previewText;
  final bool hasQuotedText;
  final bool hasSignature;
  final List<EmailSection> sections;

  const ProcessedEmailContent({
    required this.originalContent,
    required this.processedHtml,
    required this.previewText,
    required this.hasQuotedText,
    required this.hasSignature,
    required this.sections,
  });

  factory ProcessedEmailContent.empty() {
    return const ProcessedEmailContent(
      originalContent: '',
      processedHtml: '',
      previewText: '',
      hasQuotedText: false,
      hasSignature: false,
      sections: [],
    );
  }
}

/// Represents a section of email content
class EmailSection {
  final EmailSectionType type;
  final String content;
  final int quoteLevel;

  const EmailSection({
    required this.type,
    required this.content,
    this.quoteLevel = 0,
  });
}

/// Types of email content sections
enum EmailSectionType {
  original,
  quoted,
  replyHeader,
  forwardHeader,
  signature,
}