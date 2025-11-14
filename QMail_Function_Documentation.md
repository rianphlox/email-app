# QMail Function Documentation

## Overview
This document provides a comprehensive overview of all functions in the QMail Flutter email client application. The app implements a Thunderbird-style email architecture with Gmail API integration, offline caching, and modern UI.

## Table of Contents
- [Core Models](#core-models)
- [Services](#services)
- [Providers](#providers)
- [Screens](#screens)
- [Widgets](#widgets)
- [Utilities](#utilities)

---

## Core Models

### EmailMessage (`lib/models/email_message.dart`)

Core data model representing an email message with Hive storage support.

#### Properties:
- `messageId: String` - Unique identifier for the email message
- `accountId: String` - ID of the account this message belongs to
- `subject: String` - Email subject line
- `from: String` - Sender of the email
- `to: List<String>` - List of recipients
- `cc: List<String>?` - Carbon copy recipients (optional)
- `bcc: List<String>?` - Blind carbon copy recipients (optional)
- `date: DateTime` - Date and time the email was sent
- `textBody: String` - Plain text body of the email
- `htmlBody: String?` - HTML body of the email (optional)
- `isRead: bool` - Whether the email has been read
- `isImportant: bool` - Whether the email is marked as important
- `folder: EmailFolder` - Folder this email belongs to
- `attachments: List<EmailAttachment>?` - List of attachments (optional)
- `uid: int` - Unique identifier on the server
- `category: EmailCategory` - Email category (Primary, Promotions, Social, Updates)
- `previewText: String?` - Auto-generated preview text

### EmailFolder (Enum)
Represents different email folders:
- `inbox` - The inbox folder
- `sent` - The sent folder
- `drafts` - The drafts folder
- `trash` - The trash folder
- `spam` - The spam folder
- `archive` - The archive folder
- `custom` - A custom folder

### EmailCategory (Enum)
Represents email categories for Gmail-style organization:
- `primary` - Important emails
- `promotions` - Marketing emails
- `social` - Social media notifications
- `updates` - Notifications and updates

### EmailAttachment
Represents an email attachment:
- `name: String` - Name of the attachment file
- `mimeType: String` - MIME type of the attachment
- `size: int` - Size of the attachment in bytes
- `localPath: String?` - Local storage path after download
- `contentId: String` - Content ID for inline images

### EmailAccount (`lib/models/email_account.dart`)

Represents a user's email account with authentication details.

#### Properties:
- `id: String` - Unique identifier for the account
- `name: String` - Name of the account holder
- `email: String` - Email address
- `provider: EmailProvider` - Email provider (Gmail, Outlook, Yahoo, Custom)
- `accessToken: String` - OAuth 2.0 access token
- `refreshToken: String?` - OAuth 2.0 refresh token
- `lastSync: DateTime` - Last synchronization time
- `imapServer: String?` - IMAP server address for custom providers
- `imapPort: int?` - IMAP server port
- `smtpServer: String?` - SMTP server address
- `smtpPort: int?` - SMTP server port
- `isSSL: bool` - Whether to use SSL connection

#### Constructor:
- `EmailAccount()` - Creates a new account with required fields
- `EmailAccount.empty()` - Creates an empty account object

---

## Services

### GmailApiService (`lib/services/gmail_api_service.dart`)

Handles all Gmail API interactions including authentication, fetching, and sending emails.

#### Public Methods:

##### `Future<bool> connectWithGoogleSignIn(GoogleSignInAccount googleUser)`
Connects to Gmail API using Google Sign-In account.
- **Parameters:** `googleUser` - Authenticated Google user account
- **Returns:** `bool` - Success status of connection
- **Purpose:** Establishes Gmail API connection and tests authentication

##### `Future<List<EmailMessage>> fetchEmails({required String accountId, int maxResults = 50, String query = '', EmailFolder folder = EmailFolder.inbox})`
Fetches emails from Gmail with proper account and folder isolation.
- **Parameters:**
  - `accountId` - Account identifier for proper isolation
  - `maxResults` - Maximum number of emails to fetch (default: 50)
  - `query` - Custom Gmail search query
  - `folder` - Target folder to fetch from
- **Returns:** `List<EmailMessage>` - List of email messages
- **Purpose:** Retrieves emails with account/folder isolation for proper data segregation

##### `Future<bool> sendEmail({required String to, String? cc, String? bcc, required String subject, required String body, List<String>? attachmentPaths})`
Sends an email via Gmail API.
- **Parameters:** Email composition data including recipients, subject, body, and attachments
- **Returns:** `bool` - Success status
- **Purpose:** Sends emails through Gmail API (implementation pending)

##### `Future<bool> markAsRead(String messageId)`
Marks an email as read by removing UNREAD label.
- **Parameters:** `messageId` - Gmail message ID
- **Returns:** `bool` - Success status
- **Purpose:** Updates read status in Gmail

##### `Future<bool> deleteEmail(String messageId)`
Moves email to trash.
- **Parameters:** `messageId` - Gmail message ID
- **Returns:** `bool` - Success status
- **Purpose:** Deletes email by moving to trash folder

##### `void disconnect()`
Disconnects from Gmail API and clears connection state.
- **Purpose:** Clean up API connection

#### Private Helper Methods:

##### `EmailMessage _convertGmailMessageToEmailMessage(gmail.Message message, {required String accountId, required EmailFolder folder})`
Converts Gmail API message to internal EmailMessage format.
- **Parameters:**
  - `message` - Raw Gmail message
  - `accountId` - Account identifier for isolation
  - `folder` - Folder for proper categorization
- **Returns:** `EmailMessage` - Converted email message
- **Purpose:** Transforms Gmail API data to internal format with proper account/folder association

##### `Map<String, String?> _extractBodyFromPayload(gmail.MessagePart? payload)`
Extracts text and HTML content from Gmail message payload.
- **Parameters:** `payload` - Gmail message part
- **Returns:** `Map<String, String?>` - Text and HTML content
- **Purpose:** Parses multipart email content

##### `String _decodeBase64Url(String data)`
Decodes base64 URL-encoded strings from Gmail API.
- **Parameters:** `data` - Encoded string
- **Returns:** `String` - Decoded content
- **Purpose:** Handles Gmail's base64 URL encoding

##### `DateTime _parseRfc2822Date(String dateStr)`
Parses RFC 2822 date format used in emails.
- **Parameters:** `dateStr` - Date string
- **Returns:** `DateTime` - Parsed date
- **Purpose:** Converts email date strings to DateTime objects

##### `String _extractSenderName(String fromHeader)`
Extracts display name from email From header.
- **Parameters:** `fromHeader` - From header value
- **Returns:** `String` - Sender display name
- **Purpose:** Parses sender information for better display

##### `String _extractNameFromEmail(String email)`
Creates readable name from email address.
- **Parameters:** `email` - Email address
- **Returns:** `String` - Generated display name
- **Purpose:** Fallback name generation when display name unavailable

### EmailCategorizer (`lib/services/email_categorizer.dart`)

Automatically categorizes emails similar to Gmail's tabbed interface.

#### Public Methods:

##### `static EmailCategory categorizeEmail(EmailMessage email)`
Analyzes email content and assigns appropriate category.
- **Parameters:** `email` - Email message to categorize
- **Returns:** `EmailCategory` - Assigned category (Primary, Promotions, Social, Updates)
- **Purpose:** Provides Gmail-style automatic email organization

---

## Providers

### EmailProvider (`lib/providers/email_provider.dart`)

Central state management class using ChangeNotifier pattern for email functionality.

#### Properties:
- `_messages: List<EmailMessage>` - Currently displayed email list
- `_accounts: List<EmailAccount>` - Available email accounts
- `_currentAccount: EmailAccount?` - Currently selected account
- `_currentFolder: EmailFolder` - Currently selected folder
- `_isLoading: bool` - Loading state indicator
- `_isOnline: bool` - Online connectivity status
- `_accountEmailCache: Map<String, Map<EmailFolder, List<EmailMessage>>>` - Fast in-memory email cache

#### Public Getters:
- `List<EmailMessage> get messages` - Current email list
- `List<EmailAccount> get accounts` - Available accounts
- `EmailAccount? get currentAccount` - Active account
- `EmailFolder get currentFolder` - Active folder
- `bool get isLoading` - Loading status
- `bool get isOnline` - Connectivity status
- `bool get hasMessages` - Whether emails exist

#### Core Methods:

##### `Future<void> initialize()`
Initializes the provider, loads accounts, and preloads cached emails.
- **Purpose:** Sets up provider state and loads cached data for immediate display

##### `Future<void> addAccount(EmailAccount account)`
Adds a new email account and connects to its service.
- **Parameters:** `account` - Account to add
- **Purpose:** Registers new email account and establishes connection

##### `Future<void> removeAccount(String accountId)`
Removes an account and its cached emails.
- **Parameters:** `accountId` - Account identifier to remove
- **Purpose:** Cleanly removes account data and cache

##### `void switchAccount(EmailAccount account)`
Switches to a different email account.
- **Parameters:** `account` - Target account
- **Purpose:** Changes active account and loads its cached emails

##### `void switchFolder(EmailFolder folder)`
Switches to a different folder.
- **Parameters:** `folder` - Target folder
- **Purpose:** Changes active folder and loads appropriate cached emails

##### `Future<void> refreshEmails()`
Refreshes current folder's emails from server.
- **Purpose:** Pull-to-refresh functionality with haptic feedback

##### `Future<void> markAsRead(EmailMessage email)`
Marks email as read both locally and on server.
- **Parameters:** `email` - Email to mark as read
- **Purpose:** Updates read status with server synchronization

##### `Future<void> deleteEmail(EmailMessage email)`
Deletes email both locally and on server.
- **Parameters:** `email` - Email to delete
- **Purpose:** Removes email with server synchronization

#### Private Helper Methods:

##### `Future<void> _preloadAllCachedEmails()`
Loads all cached emails into memory for fast access.
- **Purpose:** Creates fast lookup cache organized by account and folder

##### `void _loadAccountCachedEmails(String accountId, EmailFolder folder)`
Loads cached emails for specific account and folder with isolation verification.
- **Parameters:**
  - `accountId` - Account identifier
  - `folder` - Folder identifier
- **Purpose:** Ensures proper account/folder isolation with safety checks

##### `Future<List<EmailMessage>> _fetchEmailsForAccount(EmailAccount account, EmailFolder folder, {int limit = 50})`
Fetches emails from server for specific account and folder.
- **Parameters:**
  - `account` - Target account
  - `folder` - Target folder
  - `limit` - Maximum emails to fetch
- **Returns:** `List<EmailMessage>` - Fetched emails
- **Purpose:** Server email retrieval with proper account/folder targeting

##### `void _mergeEmailsWithCache(String accountId, EmailFolder folder, List<EmailMessage> newEmails)`
Merges new emails with existing cache, avoiding duplicates.
- **Parameters:**
  - `accountId` - Account identifier
  - `folder` - Folder identifier
  - `newEmails` - New emails to merge
- **Purpose:** Updates cache while maintaining data integrity

---

## Screens

### InboxScreen (`lib/screens/inbox_screen.dart`)

Main email interface with tabbed categories and navigation drawer.

#### State Properties:
- `_tabController: TabController` - Manages category tabs
- `_selectedEmails: Set<String>` - Selected emails for batch operations
- `_isSelectionMode: bool` - Whether in selection mode

#### Methods:

##### `Widget build(BuildContext context)`
Builds the main screen UI with AppBar, tabs, drawer, and email list.
- **Returns:** `Widget` - Complete screen widget
- **Purpose:** Main UI construction

##### `Widget _buildDrawer()`
Creates navigation drawer with accounts and folders.
- **Returns:** `Widget` - Drawer widget
- **Purpose:** Provides account switching and folder navigation

##### `Widget _buildFolderTile(String title, IconData icon, EmailFolder folder, EmailProvider emailProvider)`
Creates folder navigation tile.
- **Parameters:** Title, icon, folder, and provider
- **Returns:** `Widget` - ListTile for folder
- **Purpose:** Folder navigation with selection indication

##### `Widget _buildAccountTile(EmailAccount account, EmailProvider emailProvider)`
Creates account selection tile.
- **Parameters:** Account and provider
- **Returns:** `Widget` - ListTile for account
- **Purpose:** Account switching with visual indication

##### `Widget _buildEmailList(List<EmailMessage> emails)`
Builds scrollable email list with pull-to-refresh.
- **Parameters:** `emails` - List of emails to display
- **Returns:** `Widget` - RefreshIndicator with ListView
- **Purpose:** Email display with refresh functionality

##### `Widget _buildEmailTile(EmailMessage email)`
Creates individual email list item.
- **Parameters:** `email` - Email message
- **Returns:** `Widget` - Email tile widget
- **Purpose:** Individual email display with tap handling

### AddAccountScreen (`lib/screens/add_account_screen.dart`)

Screen for adding new email accounts with OAuth authentication.

#### Methods:

##### `Widget build(BuildContext context)`
Builds account addition interface.
- **Purpose:** Provides UI for adding Gmail, Outlook, or custom email accounts

### EmailDetailScreen (`lib/screens/email_detail_screen.dart`)

Detailed view for individual emails with full content rendering.

#### Methods:

##### `Widget build(BuildContext context)`
Builds detailed email view with WebView rendering.
- **Purpose:** Full email content display with attachments and actions

### ComposeScreen (`lib/screens/compose_screen.dart`)

Email composition interface for creating and sending emails.

#### Methods:

##### `Widget build(BuildContext context)`
Builds email composition form.
- **Purpose:** Email creation and sending interface

---

## Widgets

### WebViewEmailRenderer (`lib/widgets/webview_email_renderer.dart`)

Thunderbird-style email content renderer using WebView with security measures.

#### Properties:
- `htmlContent: String?` - HTML email content
- `textContent: String?` - Plain text content
- `attachments: List<EmailAttachment>?` - Email attachments
- `useDarkMode: bool` - Dark mode preference
- `onLinkTap: Function(String)?` - Link tap callback

#### Methods:

##### `void _initializeWebView()`
Sets up WebView with security configurations.
- **Purpose:** Creates secure WebView with disabled JavaScript and navigation blocking

##### `String _prepareHtmlContent()`
Prepares and sanitizes HTML content for display.
- **Returns:** `String` - Sanitized HTML
- **Purpose:** Security hardening and content preparation

##### `String _sanitizeAndEnhanceHtml(String htmlContent)`
Removes dangerous elements and adds responsive styling.
- **Parameters:** `htmlContent` - Raw HTML content
- **Returns:** `String` - Sanitized and enhanced HTML
- **Purpose:** Security and display optimization

##### `void _removeDangerousElements(html_dom.Document document)`
Removes potentially dangerous HTML elements and attributes.
- **Parameters:** `document` - Parsed HTML document
- **Purpose:** Security hardening by removing scripts, forms, and event handlers

##### `void _addCustomCSS(html_dom.Document document)`
Adds Thunderbird-style CSS for consistent email rendering.
- **Parameters:** `document` - HTML document
- **Purpose:** Provides consistent, responsive email styling

##### `void _processImages(html_dom.Document document)`
Optimizes images for responsive display.
- **Parameters:** `document` - HTML document
- **Purpose:** Responsive image handling with lazy loading

##### `void _processLinks(html_dom.Document document)`
Secures and processes email links.
- **Parameters:** `document` - HTML document
- **Purpose:** Link security and JavaScript removal

---

## Utilities

### QuoteProcessor (`lib/utils/quote_processor.dart`)

Processes email quotes and signatures similar to Thunderbird's quote handling.

#### Methods:

##### `static String processQuotes(String textContent)`
Converts plain text email with quotes to styled HTML.
- **Parameters:** `textContent` - Plain text email content
- **Returns:** `String` - HTML with styled quotes
- **Purpose:** Creates Thunderbird-style quote visualization with color coding

##### `static List<Map<String, dynamic>> _parseQuoteStructure(String text)`
Analyzes text to identify quote levels and content.
- **Parameters:** `text` - Email text content
- **Returns:** `List<Map<String, dynamic>>` - Structured quote data
- **Purpose:** Identifies quote hierarchy for proper styling

##### `static String _generateQuoteHtml(List<Map<String, dynamic>> structure)`
Converts quote structure to styled HTML.
- **Parameters:** `structure` - Parsed quote structure
- **Returns:** `String` - Styled HTML
- **Purpose:** Creates visual quote hierarchy with colors and indentation

##### `static bool _isQuoteLine(String line)`
Determines if a line is a quote based on common patterns.
- **Parameters:** `line` - Text line to analyze
- **Returns:** `bool` - Whether line is a quote
- **Purpose:** Quote detection for processing

##### `static bool _isSignatureLine(String line)`
Identifies email signature lines.
- **Parameters:** `line` - Text line to analyze
- **Returns:** `bool` - Whether line is part of signature
- **Purpose:** Signature detection for formatting

### PreviewExtractor (`lib/utils/preview_extractor.dart`)

Intelligent email preview text generation that skips quotes and signatures.

#### Methods:

##### `static String extractPreview({String? htmlContent, String? textContent, int maxLength = 150})`
Extracts meaningful preview text from email content.
- **Parameters:**
  - `htmlContent` - HTML email content
  - `textContent` - Plain text content
  - `maxLength` - Maximum preview length
- **Returns:** `String` - Generated preview text
- **Purpose:** Creates intelligent previews by skipping quotes, signatures, and headers

##### `static String _extractFromHtml(String htmlContent, int maxLength)`
Extracts preview from HTML content.
- **Parameters:**
  - `htmlContent` - HTML email content
  - `maxLength` - Maximum length
- **Returns:** `String` - Extracted preview
- **Purpose:** HTML content processing for previews

##### `static String _extractFromText(String textContent, int maxLength)`
Extracts preview from plain text content.
- **Parameters:**
  - `textContent` - Plain text content
  - `maxLength` - Maximum length
- **Returns:** `String` - Extracted preview
- **Purpose:** Plain text processing for previews

##### `static bool _shouldSkipLine(String line)`
Determines if a line should be skipped in preview generation.
- **Parameters:** `line` - Text line to analyze
- **Returns:** `bool` - Whether to skip the line
- **Purpose:** Filters out quotes, signatures, and email artifacts

##### `static String _smartTruncate(String text, int maxLength)`
Intelligently truncates text at word/sentence boundaries.
- **Parameters:**
  - `text` - Text to truncate
  - `maxLength` - Maximum length
- **Returns:** `String` - Smartly truncated text
- **Purpose:** Clean text truncation for better readability

### AttachmentProcessor (`lib/utils/attachment_processor.dart`)

Handles email attachments with inline display support and secure file handling.

#### Methods:

##### `static String processInlineAttachments({required String htmlContent, List<EmailAttachment>? attachments})`
Processes inline attachments in HTML content.
- **Parameters:**
  - `htmlContent` - HTML email content
  - `attachments` - List of email attachments
- **Returns:** `String` - Processed HTML with inline attachments
- **Purpose:** Handles inline images and attachments in emails

##### `static Widget buildAttachmentList(List<EmailAttachment> attachments)`
Creates UI widget for displaying attachment list.
- **Parameters:** `attachments` - List of email attachments
- **Returns:** `Widget` - Attachment list widget
- **Purpose:** Visual attachment display with download/preview options

##### `static Widget _buildAttachmentTile(EmailAttachment attachment)`
Creates individual attachment tile.
- **Parameters:** `attachment` - Email attachment
- **Returns:** `Widget` - Attachment tile widget
- **Purpose:** Individual attachment display with type-specific icons

##### `static IconData _getAttachmentIcon(String mimeType)`
Determines appropriate icon for attachment type.
- **Parameters:** `mimeType` - MIME type of attachment
- **Returns:** `IconData` - Appropriate icon
- **Purpose:** Visual file type identification

##### `static Color _getAttachmentColor(String mimeType)`
Determines color scheme for attachment type.
- **Parameters:** `mimeType` - MIME type of attachment
- **Returns:** `Color` - Appropriate color
- **Purpose:** Visual file type categorization

##### `static String _formatFileSize(int bytes)`
Formats file size in human-readable format.
- **Parameters:** `bytes` - File size in bytes
- **Returns:** `String` - Formatted size (KB, MB, GB)
- **Purpose:** User-friendly file size display

---

## Architecture Summary

### Key Design Principles:

1. **Account Isolation**: All email operations properly isolate data by account to prevent cross-contamination
2. **Offline-First**: Cached emails load immediately on app startup for instant access
3. **Security-Hardened**: WebView rendering with disabled JavaScript and sanitized HTML
4. **Thunderbird-Style**: Quote processing and email rendering similar to Thunderbird's approach
5. **Responsive Design**: Proper mobile optimization with pull-to-refresh and adaptive layouts
6. **State Management**: Provider pattern for clean state management across the app
7. **Data Persistence**: Hive database for fast, local email caching

### Data Flow:

1. **Initialization**: App loads cached emails into memory for immediate display
2. **Account Management**: Users can switch between multiple accounts with proper isolation
3. **Email Fetching**: Background sync updates cache while maintaining UI responsiveness
4. **Folder Navigation**: Spam, inbox, sent, and other folders maintain separate cached data
5. **Rendering**: WebView-based rendering preserves original email styling while ensuring security
6. **Offline Support**: Cached emails remain accessible without internet connection

This architecture provides a modern, secure, and efficient email client experience similar to Thunderbird but optimized for mobile Flutter applications.