import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:flutter_html_video/flutter_html_video.dart';
import 'package:flutter_html_audio/flutter_html_audio.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:url_launcher/url_launcher.dart';
import '../utils/quote_processor.dart';
import '../utils/attachment_processor.dart';
import '../models/email_message.dart';
import '../widgets/enhanced_webview_renderer.dart';

class HtmlEmailRenderer {
  static final HtmlEmailRenderer _instance = HtmlEmailRenderer._internal();
  factory HtmlEmailRenderer() => _instance;
  HtmlEmailRenderer._internal();

  /// Renders HTML email content with proper styling and security
  Widget renderEmailContent({
    required String? htmlContent,
    required String? textContent,
    required BuildContext context,
    bool useDarkMode = false,
    List<EmailAttachment>? attachments,
  }) {
    // Try with a fallback strategy for better reliability
    try {
      if (htmlContent != null && htmlContent.isNotEmpty) {
        // First check if content is valid
        final cleanedHtml = _cleanAndValidateHtml(htmlContent);
        if (cleanedHtml.isEmpty) {
          // Fall back to text content if HTML is empty after cleaning
          if (textContent != null && textContent.isNotEmpty) {
            return _renderPlainText(textContent, context, useDarkMode);
          }
          return _renderEmptyContent(context);
        }

        // Use Enhanced WebView for emails with quoted text or complex HTML
        if (_shouldUseEnhancedRenderer(cleanedHtml, textContent)) {
          return _createRobustRenderer(
            htmlContent: cleanedHtml,
            textContent: textContent,
            attachments: attachments,
            useDarkMode: useDarkMode,
          );
        } else if (_shouldUseWebView(cleanedHtml)) {
          return _createRobustRenderer(
            htmlContent: cleanedHtml,
            textContent: textContent,
            attachments: attachments,
            useDarkMode: useDarkMode,
          );
        } else {
          return _renderHtml(cleanedHtml, context, useDarkMode, attachments);
        }
      } else if (textContent != null && textContent.isNotEmpty) {
        // Check if plain text has quoted content
        if (_hasQuotedText(textContent)) {
          return _createRobustRenderer(
            textContent: textContent,
            attachments: attachments,
            useDarkMode: useDarkMode,
          );
        } else {
          return _renderPlainText(textContent, context, useDarkMode);
        }
      } else {
        return _renderEmptyContent(context);
      }
    } catch (e) {
      debugPrint('Email rendering error: $e');
      // Fallback to simple text rendering
      if (textContent != null && textContent.isNotEmpty) {
        return _renderPlainText(textContent, context, useDarkMode);
      } else if (htmlContent != null && htmlContent.isNotEmpty) {
        return _renderHtml(htmlContent, context, useDarkMode, attachments);
      }
      return _renderErrorContent(context, e.toString());
    }
  }

  /// Determines if WebView should be used for complex HTML rendering
  bool _shouldUseWebView(String htmlContent) {
    // Use WebView for emails with:
    // - Complex CSS styling
    // - Images
    // - Tables with complex layouts
    // - Background images/colors
    // - Advanced HTML structure

    final lowerContent = htmlContent.toLowerCase();

    return lowerContent.contains('<style') ||
           lowerContent.contains('background-image') ||
           lowerContent.contains('background-color') ||
           lowerContent.contains('<img') ||
           lowerContent.contains('<table') ||
           lowerContent.contains('css') ||
           lowerContent.contains('font-') ||
           lowerContent.contains('color:') ||
           lowerContent.contains('margin:') ||
           lowerContent.contains('padding:') ||
           lowerContent.contains('text-align') ||
           htmlContent.length > 1000; // Complex emails are usually longer
  }

  /// Renders HTML content using flutter_html with security and styling
  Widget _renderHtml(String htmlContent, BuildContext context, bool useDarkMode, List<EmailAttachment>? attachments) {
    // Process inline attachments
    String processedHtml = AttachmentProcessor.processInlineAttachments(
      htmlContent: htmlContent,
      attachments: attachments,
    );

    final sanitizedHtml = _sanitizeHtml(processedHtml, useDarkMode);

    return Html(
      data: sanitizedHtml,
      style: _getHtmlStyles(context, useDarkMode),
      extensions: [
        // Critical for emails with tables (newsletters, invoices)
        const TableHtmlExtension(),
        // For audio/video attachments
        const AudioHtmlExtension(),
        const VideoHtmlExtension(),
        // For SVG graphics in emails
        const SvgHtmlExtension(),
      ],
      shrinkWrap: true,
      onLinkTap: (url, _, __) => _handleLinkTap(url),
    );
  }

  /// Renders plain text content with proper formatting and quote processing
  Widget _renderPlainText(String textContent, BuildContext context, bool useDarkMode) {
    // Convert plain text with quote processing to HTML
    final processedHtml = QuoteProcessor.convertTextToHtml(textContent, useDarkMode: useDarkMode);

    return Html(
      data: processedHtml,
      style: _getHtmlStyles(context, useDarkMode),
      extensions: [
        const TableHtmlExtension(),
        const AudioHtmlExtension(),
        const VideoHtmlExtension(),
        const SvgHtmlExtension(),
      ],
      shrinkWrap: true,
      onLinkTap: (url, _, __) => _handleLinkTap(url),
    );
  }

  /// Renders empty content placeholder
  Widget _renderEmptyContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.email_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No content available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// Sanitizes HTML content for security
  String _sanitizeHtml(String htmlContent, bool useDarkMode) {
    final document = html_parser.parse(htmlContent);

    // Remove dangerous elements
    _removeDangerousElements(document);

    // Clean up CSS
    _sanitizeCss(document);

    // Process images
    _processImages(document);

    // Clean up links
    _processLinks(document);

    // Inject dark mode styles if needed
    if (useDarkMode) {
      _injectDarkModeStyles(document);
    }

    return document.outerHtml;
  }

  /// Removes potentially dangerous HTML elements
  void _removeDangerousElements(html_dom.Document document) {
    final dangerousTags = [
      'script',
      'iframe',
      'object',
      'embed',
      'form',
      'input',
      'button',
      'meta',
      'link',
      'base',
    ];

    for (final tag in dangerousTags) {
      document.querySelectorAll(tag).forEach((element) => element.remove());
    }

    // Remove event handlers
    document.querySelectorAll('*').forEach((element) {
      final attributesToRemove = <String>[];
      element.attributes.forEach((name, value) {
        if (name.toString().startsWith('on') || name.toString() == 'javascript:') {
          attributesToRemove.add(name.toString());
        }
      });
      for (final attr in attributesToRemove) {
        element.attributes.remove(attr);
      }
    });
  }

  /// Sanitizes CSS to prevent layout breaking and security issues
  void _sanitizeCss(html_dom.Document document) {
    // Instead of removing all style tags, process them to remove dangerous CSS
    document.querySelectorAll('style').forEach((element) {
      final cssContent = element.innerHtml;
      final cleanedCss = _cleanStyleTagContent(cssContent);
      if (cleanedCss.trim().isNotEmpty) {
        element.innerHtml = cleanedCss;
      } else {
        element.remove();
      }
    });

    // Clean inline styles but preserve email-important ones
    document.querySelectorAll('*').forEach((element) {
      final style = element.attributes['style'];
      if (style != null) {
        element.attributes['style'] = _cleanInlineStyle(style);
      }
    });
  }

  /// Cleans inline CSS styles
  String _cleanInlineStyle(String style) {
    // Only remove truly dangerous properties, keep email styling
    final dangerousProperties = [
      'position',
      'z-index',
      'overflow',
      'animation',
      'transition',
      'cursor',
      'pointer-events',
      'javascript',
      'expression',
    ];

    String cleanStyle = style;
    for (final property in dangerousProperties) {
      cleanStyle = cleanStyle.replaceAll(RegExp('$property\\s*:[^;]*;?', caseSensitive: false), '');
    }

    return cleanStyle;
  }

  /// Cleans content of style tags while preserving email styling
  String _cleanStyleTagContent(String cssContent) {
    final dangerousRules = [
      r'@import[^;]*;',
      r'@charset[^;]*;',
      r'javascript:',
      r'expression\(',
      r'position\s*:\s*fixed',
      r'position\s*:\s*absolute',
      r'z-index\s*:\s*\d+',
    ];

    String cleanCss = cssContent;
    for (final rule in dangerousRules) {
      cleanCss = cleanCss.replaceAll(RegExp(rule, caseSensitive: false), '');
    }

    return cleanCss;
  }

  /// Processes images for security and loading
  void _processImages(html_dom.Document document) {
    document.querySelectorAll('img').forEach((img) {
      final src = img.attributes['src'];
      if (src != null) {
        // Add loading="lazy" for performance
        img.attributes['loading'] = 'lazy';

        // Set reasonable max dimensions
        if (!img.attributes.containsKey('style')) {
          img.attributes['style'] = 'max-width: 100%; height: auto;';
        } else {
          String style = img.attributes['style'] ?? '';
          if (!style.contains('max-width')) {
            style += ' max-width: 100%;';
          }
          if (!style.contains('height')) {
            style += ' height: auto;';
          }
          img.attributes['style'] = style;
        }
      }
    });
  }

  /// Processes links for security
  void _processLinks(html_dom.Document document) {
    document.querySelectorAll('a').forEach((link) {
      // Add security attributes
      link.attributes['rel'] = 'noopener noreferrer';
      link.attributes['target'] = '_blank';

      // Remove javascript: links
      final href = link.attributes['href'];
      if (href != null && href.toLowerCase().startsWith('javascript:')) {
        link.attributes.remove('href');
      }
    });
  }

  /// Injects dark mode styles into HTML document
  void _injectDarkModeStyles(html_dom.Document document) {
    final head = document.head;
    if (head != null) {
      final styleElement = html_dom.Element.tag('style');
      styleElement.innerHtml = '''
        * {
          background: #121212 !important;
          color: #F3F3F3 !important;
        }
        :link, :link * {
          color: #CCFF33 !important;
        }
        :visited, :visited * {
          color: #BB86FC !important;
        }
      ''';
      head.append(styleElement);
    }
  }

  /// Defines HTML styles for proper email rendering
  Map<String, Style> _getHtmlStyles(BuildContext context, bool useDarkMode) {
    final theme = Theme.of(context);
    final textColor = useDarkMode ? Colors.white70 : theme.colorScheme.onSurface;

    return {
      'html': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
      ),
      'body': Style(
        margin: Margins.all(16),
        padding: HtmlPaddings.zero,
        fontSize: FontSize(theme.textTheme.bodyLarge?.fontSize ?? 16),
        color: textColor,
        lineHeight: LineHeight.number(1.6),
        fontFamily: theme.textTheme.bodyLarge?.fontFamily,
      ),
      'p': Style(
        margin: Margins.only(bottom: 12),
        lineHeight: LineHeight.number(1.6),
      ),
      'h1, h2, h3, h4, h5, h6': Style(
        margin: Margins.only(top: 16, bottom: 12),
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      'h1': Style(fontSize: FontSize(24)),
      'h2': Style(fontSize: FontSize(20)),
      'h3': Style(fontSize: FontSize(18)),
      'h4': Style(fontSize: FontSize(16)),
      'h5': Style(fontSize: FontSize(14)),
      'h6': Style(fontSize: FontSize(12)),
      'a': Style(
        color: theme.colorScheme.primary,
        textDecoration: TextDecoration.underline,
      ),
      'img': Style(
        width: Width(100, Unit.percent),
        height: Height.auto(),
        margin: Margins.only(top: 8, bottom: 8),
        display: Display.block,
        border: Border.all(color: Colors.transparent),
        textAlign: TextAlign.center,
      ),
      'table': Style(
        width: Width(100, Unit.percent),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        margin: Margins.only(top: 12, bottom: 12),
      ),
      'th': Style(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        padding: HtmlPaddings.all(8),
        fontWeight: FontWeight.bold,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      'td': Style(
        padding: HtmlPaddings.all(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      'blockquote': Style(
        margin: Margins.only(left: 16, top: 12, bottom: 12),
        padding: HtmlPaddings.only(left: 16),
        border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      'ul, ol': Style(
        margin: Margins.only(top: 8, bottom: 8),
        padding: HtmlPaddings.only(left: 20),
      ),
      'li': Style(
        margin: Margins.only(bottom: 4),
      ),
      'code': Style(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: theme.colorScheme.onSurface,
        fontFamily: 'monospace',
        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
      ),
      'pre': Style(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: theme.colorScheme.onSurface,
        fontFamily: 'monospace',
        padding: HtmlPaddings.all(12),
        margin: Margins.only(top: 12, bottom: 12),
        whiteSpace: WhiteSpace.pre,
      ),
      'hr': Style(
        margin: Margins.symmetric(vertical: 16),
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      // Gmail-specific quote styling
      '.gmail_quote': Style(
        margin: Margins.only(left: 16, top: 12, bottom: 12),
        padding: HtmlPaddings.only(left: 16),
        border: Border(left: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5), width: 2)),
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontSize: FontSize(14),
      ),
      // Outlook/Apple Mail quote styling
      '.AppleMailSignature': Style(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: FontSize(12),
        fontStyle: FontStyle.italic,
      ),
      // Common email elements
      'div[dir="ltr"]': Style(
        textAlign: TextAlign.left,
      ),
      'div[dir="rtl"]': Style(
        textAlign: TextAlign.right,
      ),
    };
  }


  /// Handles link taps
  void _handleLinkTap(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      // Invalid URL, ignore
    }
  }

  /// Handles image taps to show in full screen
  void _handleImageTap(String? src) async {
    if (src == null || src.isEmpty) return;

    try {
      final uri = Uri.parse(src);
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Failed to open image: $e');
    }
  }

  /// Handles quote toggle events from the enhanced renderer
  void _handleQuoteToggled(String quoteId, bool isExpanded) {
    debugPrint('Quote $quoteId ${isExpanded ? 'expanded' : 'collapsed'}');
    // TODO: Add analytics or user preference tracking here
  }

  /// Determines if enhanced renderer should be used for advanced quote handling
  bool _shouldUseEnhancedRenderer(String? htmlContent, String? textContent) {
    // Check HTML content for quoted text patterns
    if (htmlContent != null && htmlContent.isNotEmpty) {
      if (_hasQuotedText(htmlContent)) {
        return true;
      }
    }

    // Check text content for quoted text patterns
    if (textContent != null && textContent.isNotEmpty) {
      if (_hasQuotedText(textContent)) {
        return true;
      }
    }

    // Use enhanced renderer for emails with reply/forward headers
    if (htmlContent != null && _hasReplyForwardHeaders(htmlContent)) {
      return true;
    }
    if (textContent != null && _hasReplyForwardHeaders(textContent)) {
      return true;
    }

    return false;
  }

  /// Checks if content has quoted text (lines starting with >)
  bool _hasQuotedText(String content) {
    final lines = content.split('\n');
    return lines.any((line) => line.trim().startsWith('>'));
  }

  /// Checks if content has reply or forward headers
  bool _hasReplyForwardHeaders(String content) {
    final replyPatterns = [
      RegExp(r'On .+,.*wrote:', caseSensitive: false),
      RegExp(r'From:.*To:.*Subject:', caseSensitive: false),
      RegExp(r'---------- Forwarded message', caseSensitive: false),
      RegExp(r'Begin forwarded message', caseSensitive: false),
      RegExp(r'Original Message', caseSensitive: false),
    ];

    return replyPatterns.any((pattern) => pattern.hasMatch(content));
  }

  /// Cleans and validates HTML content to prevent rendering issues
  String _cleanAndValidateHtml(String htmlContent) {
    try {
      // Parse HTML to check if it's valid
      final document = html_parser.parse(htmlContent);

      // Remove script and style tags completely
      document.querySelectorAll('script, style').forEach((element) {
        element.remove();
      });

      // Remove CSS-like content that might still be present
      final cleanedHtml = document.outerHtml;

      // Further clean CSS remnants
      String cleaned = cleanedHtml
          .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '')
          .replaceAll(RegExp(r'style\s*=\s*"[^"]*"'), '')
          .replaceAll(RegExp(r"style\s*=\s*'[^']*'"), '')
          .replaceAll(RegExp(r'\*\s*\{[^}]*\}'), '') // CSS selectors
          .replaceAll(RegExp(r'body\s*\{[^}]*\}'), '')
          .replaceAll(RegExp(r'font-[a-z-]*\s*:\s*[^;]*;?'), '')
          .replaceAll(RegExp(r'margin\s*:\s*[^;]*;?'), '')
          .replaceAll(RegExp(r'padding\s*:\s*[^;]*;?'), '')
          .replaceAll(RegExp(r'box-sizing\s*:\s*border-box;?'), '');

      // Check if there's actual content left
      final parsedDoc = html_parser.parse(cleaned);
      final element = parsedDoc.documentElement;
      final textContent = element?.text.trim();

      if (textContent == null || textContent.isEmpty) {
        return '';
      }

      return cleaned;
    } catch (e) {
      debugPrint('HTML cleaning error: $e');
      return htmlContent; // Return original if cleaning fails
    }
  }

  /// Creates a robust renderer with timeout and error handling
  Widget _createRobustRenderer({
    String? htmlContent,
    String? textContent,
    List<EmailAttachment>? attachments,
    bool useDarkMode = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight > 0 ? constraints.maxHeight : 600, // Ensure minimum height
          child: FutureBuilder<Widget>(
            future: _buildRendererWithTimeout(
              htmlContent: htmlContent,
              textContent: textContent,
              attachments: attachments,
              useDarkMode: useDarkMode,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading email...'),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return _renderErrorContent(context, snapshot.error.toString());
              }

              return snapshot.data ?? _renderErrorContent(context, 'Failed to load content');
            },
          ),
        );
      },
    );
  }

  /// Builds renderer with timeout to prevent hanging
  Future<Widget> _buildRendererWithTimeout({
    String? htmlContent,
    String? textContent,
    List<EmailAttachment>? attachments,
    bool useDarkMode = false,
  }) {
    return Future.delayed(Duration.zero, () {
      try {
        return EnhancedWebViewRenderer(
          htmlContent: htmlContent,
          textContent: textContent,
          attachments: attachments,
          useDarkMode: useDarkMode,
          onLinkTap: _handleLinkTap,
          onQuoteToggled: _handleQuoteToggled,
        );
      } catch (e) {
        throw Exception('Renderer creation failed: $e');
      }
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Renderer creation timed out');
      },
    );
  }

  /// Renders error content with retry option
  Widget _renderErrorContent(BuildContext context, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Email Content Error',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There was a problem displaying this email.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}