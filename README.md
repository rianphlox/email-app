# QMail - Modern Flutter Email Client

A feature-rich Flutter email client with Gmail-style interface, advanced email management, and multi-provider support.

## 🚀 Latest Features (v2.0)

### ✨ New in This Release
* **Enhanced Email Selection**: Gmail-style bulk actions with download, delete, and reply
* **Profile Picture Support**: Google profile photos in account drawer and avatars
* **Smart Folder Management**: Instant switching with comprehensive caching across all folders
* **Improved Starring System**: Cross-folder starred emails with unstar functionality
* **Performance Optimizations**: Increased display limit to 20 emails for better UX
* **Full-Screen Loading**: Shimmer loading with proper navbar spacing
* **Account Management**: Coming Soon UI for Yahoo/Outlook with enhanced error handling

## 📱 Core Features

### 🔐 Multi-Provider Authentication
* **Gmail Integration**: Complete OAuth 2.0 with Gmail API and profile photo support
* **Yahoo Mail Integration**: OAuth authentication with demo email functionality
* **Outlook Support**: Coming soon with modern placeholder UI
* **Custom IMAP/SMTP**: Support for any email provider with manual configuration
* **Account Switching**: Seamless switching between multiple email accounts

### 📧 Advanced Email Management
* **Gmail-Style Interface**: Modern, clean UI with Material Design 3
* **Conversation Threading**: Smart email grouping with expandable conversations
* **Bulk Email Actions**: Select multiple emails for batch operations (delete, download, reply)
* **Smart Folder System**: Inbox, Sent, Drafts, Trash, Spam, Archive, and Starred
* **Email Starring**: Cross-folder email starring with instant feedback
* **Swipe Actions**: Archive emails with intuitive swipe gestures
* **Rich Email Display**: 5-stage email processing with HTML rendering and sanitization

### 🎯 Smart Email Features
* **Intelligent Categorization**: Auto-categorize emails (Primary, Promotions, Social, Updates)
* **Smart Notifications**: Context-aware notifications with actionable buttons
* **Email Search**: Advanced search across all folders and accounts
* **Spam Detection**: Built-in spam and phishing protection
* **Operation Queue**: Reliable offline action queuing with sync

### 💾 Performance & Reliability
* **Advanced Caching**: Multi-level caching with account isolation
* **Instant Loading**: Cached emails display in <500ms
* **Background Sync**: Smart background synchronization with network awareness
* **Progressive Loading**: Load more emails on scroll with optimized batching
* **Memory Optimization**: Efficient memory usage with proper cleanup

### 🎨 Modern UI/UX
* **Material Design 3**: Latest Material Design with dynamic theming support
* **Responsive Layout**: Adaptive layouts for different screen sizes
* **Smooth Animations**: Polished animations and transitions
* **Accessibility**: Screen reader support and accessibility features
* **Dark Mode Ready**: Infrastructure for dark theme implementation

### 🔧 Developer Experience
* **Clean Architecture**: Well-organized code with 57 Dart files
* **Provider Pattern**: Robust state management with Flutter Provider
* **Type Safety**: Full type safety with null-safety support
* **Hot Reload**: Fast development with Flutter's hot reload
* **Cross-Platform**: Android, iOS, Web, macOS, Windows, and Linux support

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

## 🏗️ Architecture & Project Structure

### Key Architecture Principles
* **Clean Architecture**: Separation of concerns with distinct layers
* **Provider Pattern**: Centralized state management with reactive UI updates
* **Service Layer**: Modular services for different app functionalities
* **Offline-First**: Local caching with intelligent background synchronization

### Project Structure (lib/)

```
lib/
├── main.dart                          # App entry point with provider setup
│
├── models/                            # Data models with Hive serialization
│   ├── email_account.dart             # User account model with profile picture support
│   ├── email_message.dart             # Email message model with conversation threading
│   ├── conversation.dart              # Conversation threading model
│   └── pending_operation.dart         # Offline operation queue model
│
├── providers/                         # State management
│   └── email_provider.dart           # Central state manager (2500+ lines)
│
├── screens/                           # UI screens
│   ├── inbox_screen.dart             # Main email interface with selection mode
│   ├── email_detail_screen.dart      # Rich email viewing experience
│   ├── compose_screen.dart           # Email composition with smart features
│   └── add_account_screen.dart       # Account setup with provider selection
│
├── services/ (24 files)              # Specialized service layer
│   ├── auth_service.dart             # Multi-provider authentication
│   ├── gmail_api_service.dart        # Gmail API integration
│   ├── yahoo_api_service.dart        # Yahoo OAuth and IMAP integration
│   ├── smart_notification_service.dart # Context-aware notifications
│   ├── conversation_manager.dart     # Email threading logic
│   ├── operation_queue.dart          # Offline action management
│   ├── spam_detection_service.dart   # Security and spam protection
│   ├── email_categorizer.dart        # Intelligent email categorization
│   └── ... (16 more specialized services)
│
├── widgets/                           # Reusable UI components
│   ├── conversation_item.dart        # Conversation display widget
│   ├── shimmer_loading.dart          # Loading state animations
│   └── snooze_dialog.dart            # Email snoozing interface
│
└── utils/                             # Helper utilities
    ├── date_utils.dart               # Time formatting and parsing
    ├── preview_extractor.dart        # Email content preview generation
    └── constants.dart                # App-wide configuration
```

## 🛠️ Technology Stack

### Core Framework
* **Flutter 3.9+**: Cross-platform development with Material Design 3
* **Dart**: Type-safe language with null safety
* **Provider Pattern**: Reactive state management

### Email Integration
* **Gmail API**: Full Gmail integration with OAuth 2.0
* **Yahoo OAuth**: Yahoo Mail authentication and API integration
* **IMAP Protocol**: Universal email server support via `enough_mail`
* **HTML Rendering**: Secure email content display with sanitization

### Data & Storage
* **Hive Database**: Lightning-fast local storage with type adapters
* **Shared Preferences**: Settings and configuration persistence
* **Account Isolation**: Secure multi-account data separation

### Networking & Security
* **HTTP Client**: Robust API communication with retry logic
* **OAuth 2.0**: Secure authentication flows
* **Spam Detection**: Built-in security and phishing protection
* **Content Sanitization**: Safe HTML email rendering

### Development Tools
* **Build Runner**: Code generation for models and adapters
* **Flutter Analyzer**: Code quality and linting
* **Platform Channels**: Native platform integration

## 📊 Recent Performance Improvements

### Code Quality Metrics
* **57 Dart files**: Well-organized, modular architecture
* **2,500+ lines**: Comprehensive email provider with advanced features
* **24 specialized services**: Focused, single-responsibility modules
* **Type safety**: 100% null-safe codebase

### Performance Optimizations
* **20-email display limit**: Optimized initial load performance
* **Smart caching**: Multi-level caching with account isolation
* **Background sync**: Non-blocking email synchronization
* **Memory management**: Efficient resource usage and cleanup

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

Built using Flutter
