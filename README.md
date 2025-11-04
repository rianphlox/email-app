# QMail - Flutter Email Client

A modern Flutter email client application with Gmail-style interface and multi-provider support.

## Features

### 🔐 Multi-Provider Authentication

* **Gmail Integration**: Full OAuth 2.0 with Gmail API support
* **Outlook Support**: Microsoft email account integration
* **Yahoo Mail**: Yahoo email account support
* **Custom IMAP/SMTP**: Support for any email provider with IMAP/SMTP configuration

### 📧 Email Management

* **Gmail-Style UI**: Clean, modern interface inspired by Gmail
* **Folder Navigation**: Support for Inbox, Sent, Drafts, and Trash folders
* **Smart Email Rendering**: 5-stage Gmail-style email processing pipeline
* **Sender Name Display**: Intelligent extraction of display names from email headers
* **HTML Email Support**: Safe HTML rendering with content sanitization
* **Attachment Handling**: View and manage email attachments

### 🌍 Localization & Time

* **West African Time (WAT)**: Optimized for Lagos timezone
* **Smart Time Display**: Gmail-style relative time formatting
* **Date Parsing**: Robust RFC 2822 email date format support

### 💾 Offline Capabilities

* **Local Caching**: Emails cached locally using Hive database
* **Instant Loading**: Cached emails display immediately on app startup
* **Background Sync**: Automatic email synchronization

### 🔧 Technical Features

* **Provider Pattern**: Clean state management with Flutter Provider
* **Cross-Platform**: Support for Android, iOS, Web, macOS, Windows, and Linux
* **Hot Reload**: Fast development with Flutter's hot reload
* **Material Design**: Modern UI following Material Design guidelines

## Getting Started

### Prerequisites

* Flutter SDK (latest stable version)
* Dart SDK
* Android Studio / Xcode (for mobile development)
* Chrome browser (for web development)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/rianphlox/email-app.git
cd qmail
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure Gmail API (for Gmail integration):

   * Create a project in Google Cloud Console
   * Enable Gmail API
   * Configure OAuth 2.0 credentials
   * Update the client ID in the code

4. Run the application:

```bash

# For mobile emulator
flutter run -d emulator

```

## Project Structure (lib only)

```
lib/
├── main.dart                     # Entry point; initializes Flutter and sets up the root widget.
│
├── models/                       # Data structures and models for the app.
│   ├── email_account.dart         # Model representing a user's email account.
│   ├── email_account.g.dart       # Auto-generated file for JSON serialization.
│   ├── email_message.dart         # Model representing a single email message.
│   ├── email_message.g.dart       # Auto-generated file for JSON serialization.
│   ├── pending_operation.dart     # Tracks pending background actions like sending emails.
│   └── pending_operation.g.dart   # Auto-generated file for JSON serialization.
│
├── providers/                    # State management logic using Provider.
│   └── email_provider.dart        # Manages state for emails, accounts, and user actions.
│
├── screens/                      # UI screens for the application.
│   ├── add_account_screen.dart    # Add a new email account.
│   ├── compose_screen.dart        # Compose and send new emails.
│   ├── email_detail_screen.dart   # View full email content.
│   └── inbox_screen.dart          # Displays categorized inbox (Primary, Social, etc.).
│
├── services/                     # Core app services and API interactions.
│   ├── auth_service.dart          # Handles authentication (e.g., Google Sign-In).
│   ├── connectivity_manager.dart  # Monitors network connectivity.
│   ├── email_categorizer.dart     # Categorizes emails (Primary, Promotions, Social, etc.).
│   ├── final_email_service.dart   # Core IMAP/SMTP email handler.
│   ├── gmail_api_service.dart     # Handles Gmail API communication.
│   ├── gmail_email_renderer.dart  # Parses and renders Gmail-style HTML.
│   ├── google_auth_client.dart    # Adds OAuth tokens to HTTP requests.
│   ├── html_email_renderer.dart   # Safely renders generic HTML email content.
│   └── operation_queue.dart       # Queues async operations for offline actions.
│
└── utils/                        # Helper functions and constants.
    └── constants.dart             # App-wide constants and configurations.
```

## Key Technologies

* **Flutter**: Cross-platform UI framework
* **Provider**: State management solution
* **Hive**: Local database for caching
* **Google Sign-In**: OAuth authentication
* **Gmail API**: Google email integration
* **HTML Rendering**: Secure and modern email display
* **Material Design**: UI design system

## Development

### Running Tests

```bash
flutter test
```

### Building for Production

```bash
flutter build apk     # Android  
flutter build ios     # iOS  
flutter build web     # Web  
flutter build macos   # Desktop  
```

### Code Analysis

```bash
flutter analyze
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and analysis
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue on the GitHub repository:
👉 [https://github.com/rianphlox/email-app](https://github.com/rianphlox/email-app)

---

Built with ❤️ using Flutter
