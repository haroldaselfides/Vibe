# VibeWrite
A professional writing and storytelling application built with Flutter and Firebase.

## Getting Started

### Prerequisites
* Flutter SDK: `^3.8.1`
* Firebase project setup (Firestore & Authentication)

### Installation
1. Clone the repository.
2. Install the necessary dependencies:
   ```bash
   flutter pub get
   ```

### Running the Project
To launch the application on a connected device or emulator:
```bash
flutter run
```
vibewrite_app/
├── android/                        # Android platform files
├── ios/                            # iOS platform files
├── linux/                          # Linux desktop support
├── macos/                          # macOS desktop support
├── windows/                        # Windows desktop support
├── web/                            # Web deployment files
├── assets/                         # Static assets: fonts, images, etc.
├── lib/                            # Main Flutter source code
│   ├── main.dart                   # App entry point
│   ├── pages/                      # App screens and routes
│   │   ├── home.dart
│   │   ├── login.dart
│   │   ├── signup.dart
│   │   ├── splash.dart
│   │   └── welcome.dart
│   ├── main_tabs/                  # Bottom navigation tab screens
│   │   ├── explore.dart
│   │   ├── post.dart
│   │   └── profile.dart
│   ├── story/                      # Story reader and setup UI
│   │   ├── read_screen.dart
│   │   └── story_setup_modal.dart
│   ├── services/                   # Firebase and backend services
│   │   ├── auth_service.dart
│   │   └── firebase_options.dart
│   ├── theme/                      # Theme definitions
│   │   └── app_theme.dart
│   └── widgets/                    # Reusable widgets
│       ├── background_shape.dart
│       ├── navigation.dart
│       └── social_login_buttons.dart
├── test/                           # Widget and unit tests
├── pubspec.yaml                    # Flutter metadata and dependencies
└── README.md                       # Project documentation
```

## Getting Started
## Project Structure

This project is a starting point for a Flutter application.
The project follows a modular **Feature-First** architecture to ensure high maintainability:

A few resources to get you started if this is your first Flutter project:
* **`lib/features/`**: Contains independent functional modules.
  * `editor/`: Writing tools, chapter management, and text editing logic.
  * `explore/`: Discovery screens and story browsing.
* **`lib/core/`**: Shared utilities, constants, and application-wide configurations.
* **`lib/theme/`**: Design system and `AppTheme` definitions.
* **`lib/shared/`**: Reusable widgets and data models used across multiple features.

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
## Key Dependencies
* `firebase_core` & `cloud_firestore`: Database and backend infrastructure.
* `firebase_auth` & `google_sign_in`: Secure user authentication.
* `flutter_quill`: Rich text editing capabilities.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
---
*Built with VibeWrite App Template v1.0.0*
