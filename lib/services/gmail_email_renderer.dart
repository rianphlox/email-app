import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/email_message.dart';

/// Gmail-style email renderer following the 5-stage pipeline:
/// 1. Message Fetch (already done by Gmail API)
/// 2. MIME Parsing (extract HTML/plain text parts)
/// 3. Sanitization (strip unsafe HTML)
/// 4. Rendering (convert to Flutter widgets)
/// 5. Inline Styling (apply Gmail-like styling)
class GmailEmailRenderer {

  /// Renders an email message with Gmail-style rendering pipeline
  static Widget renderEmail(EmailMessage message, BuildContext context) {
    try {
      // Stage 2 & 3: Extract and sanitize content
      final sanitizedContent = _sanitizeAndProcessContent(message);

      // Stage 4 & 5: Render with Gmail-style UI
      return _buildEmailUI(message, sanitizedContent, context);
    } catch (e) {
      print('Error rendering email: $e');
      return _buildErrorUI('Failed to render email content');
    }
  }

  /// Stage 2 & 3: MIME Parsing + Sanitization
  static String _sanitizeAndProcessContent(EmailMessage message) {
    // Prefer HTML content over plain text (Gmail priority)
    String content;

    if (message.htmlBody != null && message.htmlBody!.isNotEmpty) {
      // Use HTML content and sanitize it
      content = _sanitizeHtml(message.htmlBody!);
    } else {
      // Convert plain text to HTML for consistent rendering
      content = _convertPlainTextToHtml(message.textBody);
    }

    return content;
  }

  /// HTML Sanitization (like Gmail's Sanitizer)
  static String _sanitizeHtml(String htmlContent) {
    try {
      // Parse the HTML
      dom.Document doc = html_parser.parse(htmlContent);

      // Remove dangerous elements (scripts, iframes, etc.)
      doc.querySelectorAll('script, style, iframe, object, embed, form, input, button').forEach((element) {
        element.remove();
      });

      // Remove duplicate header information that's already shown in the header card
      _removeDuplicateHeaders(doc);

      // Remove dangerous attributes
      doc.querySelectorAll('*').forEach((element) {
        element.attributes.removeWhere((key, value) {
          final keyStr = key.toString();
          return keyStr.startsWith('on') || // onclick, onload, etc.
              keyStr == 'javascript:' ||
              keyStr == 'data' ||
              keyStr == 'formaction';
        });
      });

      // Convert external images to safe placeholders
      doc.querySelectorAll('img').forEach((img) {
        final src = img.attributes['src'];
        if (src != null && (src.startsWith('http') || src.startsWith('//'))) {
          // Replace external images with placeholder
          img.attributes['src'] = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTE5IDNINUMzLjkgMyAzIDMuOSAzIDVWMTlDMyAyMC4xIDMuOSAyMSA1IDIxSDE5QzIwLjEgMjEgMjEgMjAuMSAyMSAxOVY1QzIxIDMuOSAyMC4xIDMgMTkgM1pNNSA1SDE5VjE1TDE1IDExTDEwLjUgMTUuNUw3IDEyTDUgMTRWNVoiIGZpbGw9IiM5RTlFOUUiLz4KPC9zdmc+'; // Image placeholder icon
          img.attributes['alt'] = 'External image blocked for security';
          img.attributes['title'] = 'External image blocked for security';
        }
      });

      // Remove external links or make them safe
      doc.querySelectorAll('a').forEach((link) {
        final href = link.attributes['href'];
        if (href != null && (href.startsWith('http') || href.startsWith('//'))) {
          link.attributes['target'] = '_blank';
          link.attributes['rel'] = 'noopener noreferrer';
        }
      });

      return doc.outerHtml;
    } catch (e) {
      print('Error sanitizing HTML: $e');
      // Fallback to plain text if HTML sanitization fails
      return _convertPlainTextToHtml(htmlContent.replaceAll(RegExp(r'<[^>]*>'), ''));
    }
  }

  /// Convert plain text to HTML for consistent rendering
  static String _convertPlainTextToHtml(String plainText) {
    if (plainText.isEmpty) return '<p>No content</p>';

    // Convert line breaks to paragraphs
    final paragraphs = plainText.split('\n\n').where((p) => p.trim().isNotEmpty);
    final htmlParagraphs = paragraphs.map((p) => '<p>${_escapeHtml(p.replaceAll('\n', '<br>'))}</p>');

    return '<div>${htmlParagraphs.join('')}</div>';
  }

  /// Escape HTML entities
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Stage 4 & 5: Build Gmail-style UI with sanitized content
  static Widget _buildEmailUI(EmailMessage message, String sanitizedContent, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email header (Gmail-style)
        _buildEmailHeader(message, context),

        const SizedBox(height: 16),

        // Main content area
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content area
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Html(
                  data: sanitizedContent,
                  style: _getGmailHtmlStyles(context),
                  onLinkTap: (url, attributes, element) => _handleLinkTap(url, context),
                ),
              ),

              // Attachments section (if any)
              if (message.attachments != null && message.attachments!.isNotEmpty)
                _buildAttachmentsSection(message.attachments!, context),
            ],
          ),
        ),
      ],
    );
  }

  /// Gmail-style email header
  static Widget _buildEmailHeader(EmailMessage message, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          Text(
            message.subject,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          // From, To, Date info
          _buildInfoRow('From', message.from, Icons.person, context),
          if (message.to.isNotEmpty)
            _buildInfoRow('To', message.to.join(', '), Icons.email, context),
          if (message.cc != null && message.cc!.isNotEmpty)
            _buildInfoRow('CC', message.cc!.join(', '), Icons.copy, context),
          _buildInfoRow('Date', _formatEmailDate(message.date), Icons.access_time, context),
        ],
      ),
    );
  }

  /// Build info row for email metadata
  static Widget _buildInfoRow(String label, String value, IconData icon, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gmail-style HTML rendering styles
  static Map<String, Style> _getGmailHtmlStyles(BuildContext context) {
    return {
      "body": Style(
        backgroundColor: Colors.transparent,
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: FontSize(16.0),
        lineHeight: LineHeight.number(1.5),
        fontFamily: 'Roboto',
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
      ),
      "p": Style(
        margin: Margins.only(bottom: 12),
        lineHeight: LineHeight.number(1.6),
      ),
      "div": Style(
        margin: Margins.only(bottom: 8),
      ),
      "h1, h2, h3, h4, h5, h6": Style(
        fontWeight: FontWeight.bold,
        margin: Margins.only(bottom: 12, top: 16),
        color: Theme.of(context).colorScheme.primary,
      ),
      "blockquote": Style(
        margin: Margins.only(left: 16, bottom: 12),
        padding: HtmlPaddings.only(left: 12),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      "pre, code": Style(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        fontFamily: 'monospace',
        padding: HtmlPaddings.all(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      "a": Style(
        color: Theme.of(context).colorScheme.primary,
        textDecoration: TextDecoration.underline,
      ),
      "img": Style(
        width: Width(100, Unit.percent),
        margin: Margins.only(bottom: 8),
      ),
      "ul, ol": Style(
        margin: Margins.only(bottom: 12),
        padding: HtmlPaddings.only(left: 20),
      ),
      "li": Style(
        margin: Margins.only(bottom: 4),
      ),
      "table": Style(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        width: Width(100, Unit.percent),
      ),
      "th, td": Style(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        padding: HtmlPaddings.all(8),
      ),
      "th": Style(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        fontWeight: FontWeight.bold,
      ),
    };
  }

  /// Build attachments section
  static Widget _buildAttachmentsSection(List<EmailAttachment> attachments, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Attachments (${attachments.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachments.map((attachment) => _buildAttachmentChip(attachment, context)).toList(),
          ),
        ],
      ),
    );
  }

  /// Build individual attachment chip
  static Widget _buildAttachmentChip(EmailAttachment attachment, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(attachment.mimeType),
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.name,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Get appropriate icon for file type
  static IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.video_file;
    if (mimeType.startsWith('audio/')) return Icons.audio_file;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('document') || mimeType.contains('msword')) return Icons.description;
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) return Icons.table_chart;
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) return Icons.slideshow;
    return Icons.attach_file;
  }

  /// Format email date in Gmail style using West African Time (Lagos)
  static String _formatEmailDate(DateTime date) {
    // Convert dates to West African Time (UTC+1) for Lagos timezone
    final lagosOffset = const Duration(hours: 1);
    final lagosDate = date.toUtc().add(lagosOffset);
    final now = DateTime.now().toUtc().add(lagosOffset);

    // For email detail view, show full date and time (Gmail style)
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[lagosDate.month - 1];
    final day = lagosDate.day;
    final year = lagosDate.year;
    final hour = lagosDate.hour > 12 ? lagosDate.hour - 12 : (lagosDate.hour == 0 ? 12 : lagosDate.hour);
    final minute = lagosDate.minute.toString().padLeft(2, '0');
    final ampm = lagosDate.hour >= 12 ? 'PM' : 'AM';

    if (year == now.year) {
      return '$month $day at $hour:$minute $ampm';
    } else {
      return '$month $day, $year at $hour:$minute $ampm';
    }
  }

  /// Handle link taps
  static void _handleLinkTap(String? url, BuildContext context) {
    if (url != null) {
      // Show a dialog asking if user wants to open the link
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Open Link'),
          content: Text('Do you want to open this link?\n\n$url'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Launch URL safely
                print('Opening URL: $url');
              },
              child: const Text('Open'),
            ),
          ],
        ),
      );
    }
  }


  /// Remove duplicate header information from email content
  static void _removeDuplicateHeaders(dom.Document doc) {
    // Much more aggressive approach to remove duplicate headers

    // First, remove any elements that look like email headers entirely
    final elementsToRemove = <dom.Element>[];

    doc.querySelectorAll('*').forEach((element) {
      final text = element.text.trim();

      // Remove elements that contain header patterns
      if (_isLikelyHeaderElement(text)) {
        elementsToRemove.add(element);
        return;
      }

      // Look for specific patterns that indicate header blocks
      if (_isHeaderBlock(text)) {
        elementsToRemove.add(element);
        return;
      }
    });

    // Remove all identified header elements
    for (final element in elementsToRemove) {
      element.remove();
    }

    // Additional cleanup: remove first few paragraphs/divs if they contain header info
    final body = doc.body;
    if (body != null) {
      final children = body.children.toList();
      for (int i = 0; i < children.length && i < 5; i++) {
        final element = children[i];
        final text = element.text.trim();

        // Remove if it's clearly a header line
        if (_isHeaderLine(text)) {
          element.remove();
        } else if (text.isNotEmpty && !_isHeaderLine(text)) {
          // Stop if we find actual content
          break;
        }
      }
    }

    // Clean up empty elements left behind
    doc.querySelectorAll('p, div, span').forEach((element) {
      if (element.text.trim().isEmpty) {
        element.remove();
      }
    });
  }

  /// Very aggressive header detection for likely header elements
  static bool _isLikelyHeaderElement(String text) {
    if (text.length > 500) return false; // Too long to be just headers

    final lowerText = text.toLowerCase();

    // Look for header patterns with more specific matching
    final headerPatterns = [
      RegExp(r'from\s*:\s*.+', caseSensitive: false),
      RegExp(r'to\s*:\s*.+', caseSensitive: false),
      RegExp(r'date\s*:\s*.+', caseSensitive: false),
      RegExp(r'subject\s*:\s*.+', caseSensitive: false),
      RegExp(r'sent\s*:\s*.+', caseSensitive: false),
    ];

    // If it contains multiple header patterns, it's likely a header block
    int headerMatches = headerPatterns.where((pattern) => pattern.hasMatch(text)).length;
    return headerMatches >= 2; // At least 2 header fields = header block
  }

  /// Check if this is a header block (contains complete header info)
  static bool _isHeaderBlock(String text) {
    if (text.length > 800) return false; // Too long

    final lowerText = text.toLowerCase();

    // Check for common header block patterns
    bool hasFrom = lowerText.contains('from:');
    bool hasTo = lowerText.contains('to:');
    bool hasDate = lowerText.contains('date:') || lowerText.contains('sent:');

    // If it has from, to, and date - it's definitely a header block
    return hasFrom && hasTo && hasDate;
  }

  /// Check if this is a single header line
  static bool _isHeaderLine(String text) {
    if (text.length > 200) return false; // Single lines shouldn't be too long

    final lowerText = text.toLowerCase().trim();

    // Single header line patterns
    final singleHeaderPatterns = [
      RegExp(r'^from\s*:\s*.+', caseSensitive: false),
      RegExp(r'^to\s*:\s*.+', caseSensitive: false),
      RegExp(r'^date\s*:\s*.+', caseSensitive: false),
      RegExp(r'^subject\s*:\s*.+', caseSensitive: false),
      RegExp(r'^sent\s*:\s*.+', caseSensitive: false),
      RegExp(r'^cc\s*:\s*.+', caseSensitive: false),
      RegExp(r'^bcc\s*:\s*.+', caseSensitive: false),
    ];

    return singleHeaderPatterns.any((pattern) => pattern.hasMatch(lowerText));
  }

  /// Build error UI when rendering fails
  static Widget _buildErrorUI(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}