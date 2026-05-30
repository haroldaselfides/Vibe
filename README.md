# VibeWrite App

A Flutter app for writing, reading, and publishing stories.

## Project Structure

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

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
