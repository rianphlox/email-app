import 'package:html/parser.dart' as html_parser;
import 'advanced_quote_processor.dart';

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
    // Try using advanced quote processor for better preview extraction
    try {
      final processedContent = AdvancedQuoteProcessor.processEmailContent(
        htmlContent ?? textContent ?? '',
        isHtml: htmlContent != null && htmlContent.isNotEmpty,
      );

      if (processedContent.previewText.isNotEmpty) {
        return processedContent.previewText.length <= maxLength
            ? processedContent.previewText
            : '${processedContent.previewText.substring(0, maxLength)}...';
      }
    } catch (e) {
      // Fall back to original extraction if advanced processing fails
    }

    // Fallback to original preview extraction
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
      document.querySelectorAll('script, style, head, meta, link').forEach((element) {
        element.remove();
      });

      // Get text content
      String text = document.body?.text ?? document.documentElement?.text ?? '';

      // Clean up whitespace
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      // Apply aggressive CSS cleaning to the extracted text
      text = _aggressiveCssClean(text);

      return text;
    } catch (e) {
      // If HTML parsing fails, clean manually
      String cleaned = htmlContent;

      // Remove style blocks and content
      cleaned = cleaned.replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '');

      // Remove script blocks and content
      cleaned = cleaned.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');

      // Remove CSS in style attributes
      cleaned = cleaned.replaceAll(RegExp(r'style\s*=\s*"[^"]*"'), '');
      cleaned = cleaned.replaceAll(RegExp(r"style\s*=\s*'[^']*'"), '');

      // Remove all HTML tags
      cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');

      // Apply aggressive CSS cleaning
      cleaned = _aggressiveCssClean(cleaned);

      return cleaned;
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
    // Apply aggressive CSS cleaning first
    text = _aggressiveCssClean(text);

    // Remove email addresses that might clutter the preview
    text = text.replaceAll(RegExp(r'\S+@\S+\.\S+'), '');

    // Remove excessive punctuation
    text = text.replaceAll(RegExp(r'[.]{3,}'), '...');
    text = text.replaceAll(RegExp(r'[-]{3,}'), '---');
    text = text.replaceAll(RegExp(r'[=]{3,}'), '===');
    text = text.replaceAll(RegExp(r'[;]{2,}'), ';');

    // Remove common email artifacts
    text = text.replaceAll(RegExp(r'\[cid:[^\]]+\]'), '');
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Clean up whitespace and special characters
    text = text.replaceAll(RegExp(r'\s*:\s*'), ': ');
    text = text.replaceAll(RegExp(r'\s*;\s*'), '; ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove very short words that don't add meaning
    final words = text.split(' ');
    final meaningfulWords = words.where((word) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      return cleanWord.length >= _minWordLength ||
             cleanWord.toLowerCase() == 'i' ||
             cleanWord.toLowerCase() == 'a' ||
             RegExp(r'^\d+$').hasMatch(cleanWord);
    });

    return meaningfulWords.join(' ');
  }

  /// Aggressively cleans CSS and media queries from text content
  static String _aggressiveCssClean(String text) {
    // Remove all style blocks and their content
    text = text.replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '');

    // Remove @media queries completely (more aggressive pattern)
    text = text.replaceAll(RegExp(r'@media[^{]*\{(?:[^{}]*\{[^{}]*\})*[^{}]*\}', caseSensitive: false, dotAll: true), '');

    // Remove all CSS blocks (anything between { }) - multiple passes
    for (int i = 0; i < 3; i++) {
      text = text.replaceAll(RegExp(r'\{[^{}]*\}', dotAll: true), ' ');
    }

    // Remove CSS property patterns (more aggressive)
    text = text.replaceAll(RegExp(r'[a-z-]+\s*:\s*[^;{}\n]*[;}]', caseSensitive: false), '');

    // Remove @-rules (@import, @charset, @media, etc.)
    text = text.replaceAll(RegExp(r'@[a-z-]+[^;{]*[;}]', caseSensitive: false), '');

    // Remove CSS selectors and class/id names
    text = text.replaceAll(RegExp(r'\.[a-z_-][a-z0-9_-]*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'#[a-z_-][a-z0-9_-]*', caseSensitive: false), '');

    // Remove CSS units and values
    text = text.replaceAll(RegExp(r'\d+(?:px|%|em|rem|pt|pc|in|cm|mm|ex|ch|vw|vh|vmin|vmax|deg|s|ms)\b'), '');

    // Remove hex colors, rgb/rgba values
    text = text.replaceAll(RegExp(r'#[0-9a-f]{3,8}\b', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'rgba?\([^)]+\)', caseSensitive: false), '');

    // Remove CSS functions
    text = text.replaceAll(RegExp(r'(?:calc|var|url|linear-gradient|radial-gradient)\([^)]+\)', caseSensitive: false), '');

    // More comprehensive CSS keyword removal
    final cssKeywords = [
      // Layout
      'display', 'position', 'top', 'right', 'bottom', 'left', 'float', 'clear',
      'box-sizing', 'margin', 'padding', 'width', 'height', 'max-width', 'min-width',
      'max-height', 'min-height', 'overflow', 'visibility', 'z-index',

      // Typography
      'font-family', 'font-size', 'font-weight', 'font-style', 'line-height',
      'text-align', 'text-decoration', 'text-transform', 'letter-spacing',
      'word-spacing', 'white-space',

      // Styling
      'color', 'background', 'background-color', 'background-image', 'border',
      'border-radius', 'outline', 'box-shadow', 'text-shadow', 'opacity',

      // Flexbox/Grid
      'flex', 'flex-direction', 'justify-content', 'align-items', 'grid',

      // Animation/Transform
      'transform', 'transition', 'animation',

      // Table
      'table', 'tbody', 'thead', 'tr', 'td', 'th', 'table-layout',

      // Email-specific
      'desktop_hide', 'mobile_show', 'desktop_show', 'mobile_hide',

      // Values
      'none', 'auto', 'inherit', 'initial', 'unset', 'block', 'inline',
      'relative', 'absolute', 'fixed', 'static', 'hidden', 'visible',
      'bold', 'normal', 'italic', 'center', 'left', 'right', 'justify'
    ];

    for (final keyword in cssKeywords) {
      text = text.replaceAll(RegExp('\\b$keyword\\b', caseSensitive: false), '');
    }

    // Remove common email template patterns
    text = text.replaceAll(RegExp(r'\b(?:desktop_hide|mobile_show|table\.i|mso-[a-z-]+)[a-z_\d-]*', caseSensitive: false), '');

    // Remove Microsoft Outlook specific CSS
    text = text.replaceAll(RegExp(r'mso-[a-z-]+', caseSensitive: false), '');

    // Remove parentheses with CSS-like content
    text = text.replaceAll(RegExp(r'\([^)]*(?:max-width|px|%|em|pt|rem)[^)]*\)', caseSensitive: false), '');

    // Remove CSS punctuation and syntax
    text = text.replaceAll(RegExp(r'[{}();:!]'), ' ');
    text = text.replaceAll(RegExp(r'[,;]\s*'), ' ');

    // Remove sequences of special characters
    text = text.replaceAll(RegExp(r'[-=_]{2,}'), ' ');

    // Clean up whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Filter out CSS-like lines more aggressively
    final lines = text.split(RegExp(r'[\n\r]'));
    final cleanLines = lines.where((line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.length < 4) return false;

      // Skip lines that look like CSS properties
      if (RegExp(r'^[a-z-]+\s*:.*$', caseSensitive: false).hasMatch(trimmed)) return false;

      // Skip lines with @-rules
      if (RegExp(r'^@[a-z]', caseSensitive: false).hasMatch(trimmed)) return false;

      // Skip lines with lots of CSS units
      if (RegExp(r'(\d+(?:px|%|em|pt).*){2,}', caseSensitive: false).hasMatch(trimmed)) return false;

      // Skip lines that are mostly CSS selectors/classes
      if (RegExp(r'^[\.\#][a-z_-]', caseSensitive: false).hasMatch(trimmed)) return false;

      // Skip lines that contain CSS property patterns
      if (RegExp(r'[a-z-]+\s*:\s*[^;]+;', caseSensitive: false).hasMatch(trimmed)) return false;

      // Skip lines with too many CSS-like tokens
      final cssTokens = RegExp(r'(\{|\}|px|%|em|#[0-9a-f]+|rgba?|\.|:)', caseSensitive: false);
      if (cssTokens.allMatches(trimmed).length > 3) return false;

      return true;
    });

    final result = cleanLines.join(' ').trim();

    // Final cleanup pass - remove any remaining CSS artifacts
    return result
        .replaceAll(RegExp(r'\b[a-z-]+\s*:\s*[^;]+;?', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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