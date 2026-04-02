# PANIKASOG – Community Disaster Response App

> **Bisaya for "Run/Flee"** — a mobile platform empowering communities to respond,
> report, and recover together during disasters.

---

## Tech Stack

| Layer            | Technology                     |
| ---------------- | ------------------------------ |
| Framework        | Flutter 3.x (Dart 3.x)         |
| State Management | Provider 6.x                   |
| Backend          | Firebase (Auth + Firestore)    |
| Maps             | Google Maps Flutter            |
| Auth Providers   | Email/Password, Google Sign-In |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── colors.dart          # AppColors — all brand colors
│   │   └── text_styles.dart     # AppTextStyles — all typography
│   └── theme/
│       └── app_theme.dart       # ThemeData config (Material 3)
│
├── models/
│   └── user_model.dart          # User data class + Firestore serialization
│
├── providers/
│   └── auth_provider.dart       # Auth state (login / signup / Google)
│
├── services/
│   └── auth_service.dart        # Firebase Auth + Firestore logic
│
├── widgets/
│   ├── app_logo.dart            # AppLogo + PanikasogAppBar
│   ├── custom_button.dart       # AppButton (primary/outline/social/ghost)
│   ├── custom_text_field.dart   # AppTextField + AppSearchField
│   └── chip_input_field.dart    # ChipInputField for Skills / Tasks
│
├── screens/
│   ├── auth/
│   │   ├── landing_screen.dart      # 4-slide onboarding carousel
│   │   ├── signup_step1_screen.dart # Email / Phone / Password
│   │   ├── signup_step2_screen.dart # Name / Skills / Tasks / Referral
│   │   └── login_screen.dart        # Login + social auth + forgot password
│   │
│   └── main_screen.dart         # Bottom nav shell + FAB overlay menu
│
├── firebase_options.dart        # ⚠️ Generate with flutterfire configure
└── main.dart                    # App entry point + Provider setup + routing
```

---

## Quick Start

### 1. Clone & Install Dependencies

```bash
git clone <your-repo-url>
cd panikasog
flutter pub get
```

### 2. Firebase Setup

#### 2a. Create a Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project named **panikasog** (or any name)
3. Enable **Google Analytics** (optional but recommended)

#### 2b. Enable Authentication

In Firebase Console → Authentication → Sign-in method, enable:

- ✅ **Email/Password**
- ✅ **Google**

#### 2c. Create Firestore Database

In Firebase Console → Firestore Database:

1. Click **Create Database**
2. Choose **Start in production mode**
3. Select a region (e.g., `asia-southeast1` for Philippines)
4. Copy the contents of `firestore.rules` into the **Rules** tab

#### 2d. Generate firebase_options.dart

```bash
# Install FlutterFire CLI (once)
dart pub global activate flutterfire_cli

# Configure (run from project root)
flutterfire configure
```

Select your Firebase project and target platforms (Android/iOS).
This auto-generates `lib/firebase_options.dart` with your real keys.

#### 2e. Enable the Options in main.dart

Open `lib/main.dart` and:

1. Uncomment: `import 'firebase_options.dart';`
2. Update the `Firebase.initializeApp()` call:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 3. Google Sign-In Setup (Android)

1. In Firebase Console → Authentication → Sign-in method → Google → add your **Support email**
2. Download `google-services.json` and place it at:
   `android/app/google-services.json`
3. Get your SHA-1 fingerprint:

   ```bash
   cd android
   ./gradlew signingReport
   ```

   (or if it doesn't work, try this:)

   ```bash
   keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```

4. Add the SHA-1 to Firebase Console → Project Settings → Your Android App

### 4. Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Credentials
2. Create an **API Key** and restrict it to the **Maps SDK for Android / iOS**
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml`
4. For iOS, add to `ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

### 5. Run the App

```bash
flutter run
```

---

## Auth Flow

```
LandingScreen (carousel)
    │
    ├── [Sign Up] ──► SignupStep1Screen (Email + Phone + Password)
    │                       │
    │                       └── [Next →] ──► SignupStep2Screen (Profile + Skills)
    │                                               │
    │                                               └── [Finish Sign up] ──► MainScreen
    │
    └── [Login] ──► LoginScreen ──► MainScreen
```

### Referral Code Logic

- Every user gets a unique 8-character code generated on signup (e.g. `A1B2C3D4`)
- When a new user enters a referral code:
  - New user gets **+100 points** immediately
  - Referrer also gets **+100 points** (via Firestore update)
- Invalid codes are silently ignored (no crash)

---

## Firestore Data Model

### `/users/{uid}`

```json
{
  "email": "juan@email.com",
  "phoneNumber": "+639123456789",
  "name": "Juan Dela Cruz",
  "username": "juan_01",
  "address": "Brgy. Mainis, Iloilo City",
  "skills": ["First Aid", "Driving"],
  "preferredTasks": ["Emergency Response", "Cleanup & Recovery"],
  "referralCode": "JUAN8X4Z",
  "usedReferralCode": null,
  "points": 100,
  "jobsTaken": 0,
  "jobsFinished": 0,
  "avatarUrl": null,
  "level": "Community Member",
  "levelProgress": 0,
  "dateJoined": "2026-03-25T00:00:00Z",
  "badges": []
}
```

---

## Environment Variables

Never commit real keys. Use these placeholder patterns:

| Key                        | Where                                                          |
| -------------------------- | -------------------------------------------------------------- |
| Firebase Config            | Generated by `flutterfire configure` → `firebase_options.dart` |
| Google Maps Key            | `AndroidManifest.xml` + `AppDelegate.swift`                    |
| `google-services.json`     | `android/app/` (git-ignored)                                   |
| `GoogleService-Info.plist` | `ios/Runner/` (git-ignored)                                    |

---

## Modules Roadmap

| Module             | Status      | Description                                   |
| ------------------ | ----------- | --------------------------------------------- |
| 🔐 **Auth**        | ✅ **Done** | Landing, Sign-up (2-step), Login, Google auth |
| 🏠 **Home Feed**   | ⏳ Next     | Post cards, filter chips, Urgent Tasks drawer |
| 📋 **Tasks**       | ⏳ Planned  | List, Detail, Timer, Verification, Rewards    |
| 📍 **Reports**     | ⏳ Planned  | Map view, Hazard categories, Create Report    |
| 👤 **Profile**     | ⏳ Planned  | Tabs, Achievements, Stats, Edit profile       |
| 🏆 **Leaderboard** | ⏳ Planned  | Daily/Monthly rankings, Badges                |
| 🎁 **Rewards**     | ⏳ Planned  | Points wallet, Partner redemption             |
| ⚙️ **Settings**    | ⏳ Planned  | Accessibility, Theme, Notifications           |

---

## Design System

### Colors

```dart
AppColors.primary       // #B1004E  — Deep Magenta (main brand)
AppColors.primaryLight  // #D4006A  — Lighter magenta (gradients)
AppColors.white         // #FFFFFF
AppColors.lightGrey     // #F5F5F5  — Page backgrounds
AppColors.borderGrey    // #E0E0E0  — Input borders
AppColors.chipBg        // #FCE4EC  — Chip backgrounds
AppColors.referralBg    // #FFEBF3  — Referral section tint
```

### Typography

All text uses **Poppins**. Add the font files to `assets/fonts/`:

- `Poppins-Regular.ttf`
- `Poppins-Medium.ttf`
- `Poppins-SemiBold.ttf`
- `Poppins-Bold.ttf`

Download from [Google Fonts](https://fonts.google.com/specimen/Poppins).

### Reusable Widgets

```dart
// Buttons
AppButton(label: 'Log in', onPressed: ...) // primary
AppButton(label: 'Login', variant: ButtonVariant.outline, ...)
AppButton(label: 'Google', variant: ButtonVariant.social, prefixIcon: ...)

// Text Fields
AppTextField(label: 'Email', hint: '...', controller: ..., validator: ...)

// Chip Input
ChipInputField(
  label: 'Skills',
  suggestions: [...],
  selectedValues: _skills,
  onChanged: (vals) => setState(() => _skills = vals),
)

// Logo
AppLogo()           // standard
AppLogo(darkBackground: true)  // for dark/gradient backgrounds
```

---

## Contributing

1. Branch from `main`
2. Use the feature-first folder structure
3. Each screen should use a `Consumer<XProvider>` or `context.watch<XProvider>()`
4. Keep business logic in `services/` and state in `providers/`
5. Use `AppColors`, `AppTextStyles`, and `AppTheme` — no hardcoded styles

---

_Built with ❤️ for communities in the Philippines and beyond._
