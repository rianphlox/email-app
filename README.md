# QMail - Flutter Email Client

A modern Flutter email client application with Gmail-style interface and multi-provider support.

## Features

### 🔐 Multi-Provider Authentication
- **Gmail Integration**: Full OAuth 2.0 with Gmail API support
- **Outlook Support**: Microsoft email account integration
- **Yahoo Mail**: Yahoo email account support
- **Custom IMAP/SMTP**: Support for any email provider with IMAP/SMTP configuration

### 📧 Email Management
- **Gmail-Style UI**: Clean, modern interface inspired by Gmail
- **Folder Navigation**: Support for Inbox, Sent, Drafts, and Trash folders
- **Smart Email Rendering**: 5-stage Gmail-style email processing pipeline
- **Sender Name Display**: Intelligent extraction of display names from email headers
- **HTML Email Support**: Safe HTML rendering with content sanitization
- **Attachment Handling**: View and manage email attachments

### 🌍 Localization & Time
- **West African Time (WAT)**: Optimized for Lagos timezone
- **Smart Time Display**: Gmail-style relative time formatting
- **Date Parsing**: Robust RFC 2822 email date format support

### 💾 Offline Capabilities
- **Local Caching**: Emails cached locally using Hive database
- **Instant Loading**: Cached emails display immediately on app startup
- **Background Sync**: Automatic email synchronization

### 🔧 Technical Features
- **Provider Pattern**: Clean state management with Flutter Provider
- **Cross-Platform**: Support for Android, iOS, Web, macOS, Windows, and Linux
- **Hot Reload**: Fast development with Flutter's hot reload
- **Material Design**: Modern UI following Material Design guidelines

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Chrome browser (for web development)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/qmail.git
cd qmail
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Gmail API (for Gmail integration):
   - Create a project in Google Cloud Console
   - Enable Gmail API
   - Configure OAuth 2.0 credentials
   - Update the client ID in the code

4. Run the application:
```bash
# For web
flutter run -d chrome

# For mobile emulator
flutter run -d emulator

# For desktop
flutter run -d macos  # or windows/linux
```

## Project Structure

```
├── pubspec.yaml               # Defines project dependencies, metadata, and assets.
├── lib/                         # Main application source code directory.
│   ├── main.dart                # The entry point of the application; initializes Flutter and sets up the root widget.
│   ├── models/                  # Contains the data structures and models for the application.
│   │   ├── email_account.dart   # Model for representing a user's email account.
│   │   ├── email_account.g.dart # Auto-generated file for JSON serialization/deserialization.
│   │   ├── email_message.dart   # Model for representing a single email message.
│   │   ├── email_message.g.dart # Auto-generated file for JSON serialization/deserialization.
│   │   ├── pending_operation.dart # Model for tracking pending background operations like sending an email.
│   │   └── pending_operation.g.dart # Auto-generated file for JSON serialization/deserialization.
│   ├── providers/               # State management logic using the Provider pattern.
│   │   └── email_provider.dart  # Manages the application's state for emails, accounts, and user interactions.
│   ├── screens/                 # UI widgets that represent full screens in the app.
│   │   ├── add_account_screen.dart # Screen for users to add a new email account.
│   │   ├── compose_screen.dart  # Screen for composing and sending new emails.
│   │   ├── email_detail_screen.dart # Screen to display the full content of a selected email.
│   │   └── inbox_screen.dart    # The main screen that displays the list of emails in the inbox.
│   ├── services/                # Contains business logic, API interactions, and other core functionalities.
│   │   ├── auth_service.dart    # Handles user authentication, including Google Sign-In.
│   │   ├── connectivity_manager.dart # Monitors the device's network connectivity status.
│   │   ├── email_categorizer.dart # Service to categorize emails (e.g., Primary, Social).
│   │   ├── final_email_service.dart # Core service for handling email protocols like IMAP/SMTP.
│   │   ├── gmail_api_service.dart # Service for interacting specifically with the Gmail API.
│   │   ├── gmail_email_renderer.dart # Renders Gmail-specific content and formatting.
│   │   ├── google_auth_client.dart # An HTTP client that automatically adds authentication headers for Google API requests.
│   │   ├── html_email_renderer.dart # Service to render standard HTML email content safely.
│   │   └── operation_queue.dart # Manages a queue of asynchronous tasks to ensure they are executed sequentially.
│   └── utils/                   # Utility functions, helpers, and constants.
│       └── constants.dart       # Application-wide constants and configuration values.
├── test/                        # Contains all the automated tests for the application.
│   └── widget_test.dart         # Example widget tests to ensure UI components work as expected.
├── android/                     # Android-specific project files and configurations.
├── ios/                         # iOS-specific project files and configurations.
├── web/                         # Web-specific project files and configurations.
├── macos/                       # macOS-specific project files and configurations.
├── linux/                       # Linux-specific project files and configurations.
└── windows/                     # Windows-specific project files and configurations.
```

## Key Technologies

- **Flutter**: Cross-platform UI framework
- **Provider**: State management solution
- **Hive**: Local database for caching
- **Google Sign-In**: OAuth authentication
- **Gmail API**: Google email integration
- **HTML**: Email content rendering
- **Material Design**: UI design system

## Development

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Web
flutter build web

# Android
flutter build apk

# iOS
flutter build ios

# Desktop
flutter build macos  # or windows/linux
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

For support and questions, please open an issue on the GitHub repository.

---

Built with ❤️ using Flutter