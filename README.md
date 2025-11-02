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
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── email_account.dart       # Email account model
│   ├── email_message.dart       # Email message model
│   └── email.dart              # Legacy email model
├── providers/                   # State management
│   └── email_provider.dart     # Main email provider
├── screens/                     # UI screens
│   ├── inbox_screen.dart       # Main inbox interface
│   ├── email_detail_screen.dart # Email detail view
│   └── login_screen.dart       # Authentication screen
├── services/                    # Business logic
│   ├── gmail_api_service.dart  # Gmail API integration
│   ├── gmail_email_renderer.dart # Email rendering engine
│   ├── auth_service.dart       # Authentication service
│   └── final_email_service.dart # IMAP/SMTP service
└── views/                      # UI components
    └── email_list_screen/      # Email list components
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