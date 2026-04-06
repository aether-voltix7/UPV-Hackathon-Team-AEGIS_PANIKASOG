# PANIKASOG – Community Disaster Response App


> **Hiligaynon word for "relentless/persistent"** — a mobile platform empowering Ilonggo communities to respond, report, and recover together during disasters.


Panikasog is a community-centric, gamified disaster resilience mobile application built for the communities of Panay Island, one of the most disaster-prone island groups in the Philippines. The name comes from the Hiligaynon word meaning "relentless" or "persistent," reflecting the platform's core philosophy: that consistent, small, preventive actions taken by ordinary citizens are more powerful than reactive emergency response after the damage has been done.


## Functional Scope — What our System Does


### Current Features


- **Home**: Community feed with upvote/downvote verification
- **Posts:** Community-driven updates for disaster phases (e.g., preparedness cleanup drives, real-time rescue requests or route alerts, and post-disaster recovery efforts)
- **Tasks:** Community task management — citizens accept, complete, and verify disaster prevention missions
- **Reports:** Hazard and disaster reporting with GPS tagging and status tracking.
- **Leaderboards:** Points and experience-based gamification with leaderboards with weekly and monthly rankings.
- **Rewards:** Rewards redemption via partner merchant networks, and Referral incentive system for community growth


### In Scope (for Future Development)


- **Home:** LGU announcement pinning
- **Leaderboards:** Individual and Barangay-level rankings
- **Tasks:** Automated post generation upon task completion for community feed visibility
- **Reports:**
  - Real-time heatmap visualization,
  - SMS reporting fallback for users without internet connectivity
- **LGU Interface:** LGU dashboard for task creation, report management, and data monitoring
- **Accessibility:** Multi-language support (Filipino, Hiligaynon, English) with accessibility features
- **Partnerships:**
  - Integration with PAGASA weather data for pre-emptive mission triggers
  - Integration with the ICARE (Iloilo City Action and Response Center) dispatch system
- National-level rollout outside the Panay Island pilot region


## Quick Links


- **GitHub:** https://github.com/aether-voltix7/UPV-Hackathon-Team-AEGIS_PANIKASOG
- **Figma:** https://www.figma.com/design/21VUDwITmUnhC1aFwxEWPf/PANIKASOG-%7C-KOMSAI.HACK-2026?node-id=0-1&t=vdCP4EJTCwdHxvr6-1

## Tech Stack


| Layer            | Technology                     |
| ---------------- | ------------------------------ |
| Framework        | Flutter 3.x (Dart 3.x)         |
| State Management | Provider 6.x                   |
| Backend          | Firebase (Auth + Firestore)    |
| Maps             | Google Maps Flutter            |
| Auth Providers   | Email/Password, Google Sign-In |


---


## Modules Roadmap


| Module             | Status            | Description                                   |
| ------------------ | ----------------- | --------------------------------------------- |
| 🔐 **Auth**        | ✅ **Done**       | Landing, Sign-up (2-step), Login, Google auth |
| 🏠 **Home Feed**   | ✅ **Done**       | Post cards, filter chips, Urgent Tasks drawer |
| 📋 **Tasks**       | ⏳ For Refinement | List, Detail, Timer, Verification, Rewards    |
| 📍 **Reports**     | ⏳ For Refinement | Map view, Hazard categories, Create Report    |
| 👤 **Profile**     | ✅ **Done**       | Tabs, Achievements, Stats, Edit profile       |
| 🏆 **Leaderboard** | ⏳ For Refinement | Daily/Monthly rankings, Badges                |
| 🎁 **Rewards**     | ✅ **Done**       | Points wallet, Partner redemption             |
| ⚙️ **Settings**    | ✅ **Done**       | Accessibility, Theme, Notifications           |


---


## Installation


1. Clone the repo
   git clone https://github.com/aether-voltix7/UPV-Hackathon-Team-AEGIS_PANIKASOG.git


2. Install dependencies
   flutter pub get


3. Run the app
   flutter run


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
├── firebase_options.dart        # Generated with 'flutterfire configure'
└── main.dart                    # App entry point + Provider setup + routing
```


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


Pull requests are welcome! For major changes, open an issue first.


---


## Known Issues


- Only supports Android for now
- No LGU Interface yet
- Searching location when creating a task
- No SMS parsing yet
- Partnerships for Rewards coming soon


## License


MIT License


## Author


Team AEGIS
Developed for UPV’s Komsai Hack 2026: RiskReady


_Built with ❤️ for communities in the Philippines and beyond._





