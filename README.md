# Visitor Management Mobile Application

A Flutter mobile application for managing visitors, built as part of the Flutter Developer assignment for **Sumadhura Group**.

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack and Versions](#tech-stack-and-versions)
- [Setup and Run Instructions](#setup-and-run-instructions)
- [Test Login Credentials](#test-login-credentials)
- [API Details](#api-details)
- [Third-Party Packages Used](#third-party-packages-used)
- [Project Structure](#project-structure)
- [Known Limitations](#known-limitations)
- [Author](#author)

---

## Features

- Login / Authentication
- Visitor list with search and filter
- Add new visitor
- Visitor check-in / check-out
- Visitor details screen
- Form validation and error handling
- Loading, empty and error states

---

## Screenshots

| Login | Dashboard | Visitor List |
|:-----:|:---------:|:------------:|
| <img src="screenshots/login.png" width="200"/> | <img src="screenshots/dashboard.png" width="200"/> | <img src="screenshots/visitor_list.png" width="200"/> |

| Add Visitor | Visitor Details |
|:-----------:|:---------------:|
| <img src="screenshots/add_visitor.png" width="200"/> | <img src="screenshots/details.png" width="200"/> |

---

## Tech Stack and Versions

| Tool | Version |
|------|---------|
| Flutter | 3.38.3 (stable channel) |
| Dart | 3.10.1 |
| Android minSdk | 21 |
| State Management | Provider |

> Run `flutter --version` to get the exact values on your machine.

---

## Setup and Run Instructions

### Prerequisites

- Flutter SDK 3.38.3 installed ([install guide](https://docs.flutter.dev/get-started/install))
- Android Studio or VS Code with the Flutter plugin
- An Android emulator or a physical device with USB debugging enabled

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/badmakumar26-creator/Visitor-Management-.git
cd Visitor-Management-

# 2. Install dependencies
flutter pub get

# 3. Check the environment
flutter doctor

# 4. Run the app
flutter run
```

### Build the APK

```bash
flutter build apk --release
```

The APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Test Login Credentials

| Field | Value |
|-------|-------|
| Email / Username | `<add test email here>` |
| Password | `<add test password here>` |

---

## API Details

- **Base URL:** `https://6ae04b7abe3bc8fead96d649.mockapi.io/`
- **Authentication:** `<Bearer token / API key / none>`

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/login` | POST | User login |
| `/visitors` | GET | Fetch visitor list |
| `/visitors` | POST | Add a new visitor |
| `/visitors/{id}` | PUT | Update visitor / check-out |

HTTP calls are handled with the `http` package, with error handling for timeouts, no internet, and server errors.

---

## Third-Party Packages Used

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `http` | REST API calls |
| `shared_preferences` | Local storage (token, session) |
| `intl` | Date and time formatting |

---

## Project Structure

```
lib/
├── main.dart
├── models/       # Data models
├── services/     # API / network layer
├── providers/    # State management
├── screens/      # UI screens
├── widgets/      # Reusable widgets
└── utils/        # Constants, helpers
```

---

## Known Limitations

- Tested on Android only
- No offline mode
- Image upload is not supported

---

## Author

**Badma Kumar S**

- Email: [badmakumar26@gmail.com](mailto:badmakumar26@gmail.com)
- GitHub: [badmakumar26-creator](https://github.com/badmakumar26-creator)
