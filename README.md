# SmartContent Mobile App

This directory contains the Dart source code and UI structure for the SmartContent Flutter application.

## ⚠️ Important Note: Missing Platform Folders

Because Flutter was not installed on this system when the project structure was generated, **only the `lib` directory and `pubspec.yaml` have been created**. The native platform folders (`android/`, `ios/`, `web/`, etc.) do not exist yet.

## How to Initialize the Project

1. **Install Flutter:** If you haven't already, install the Flutter SDK from [docs.flutter.dev](https://docs.flutter.dev/get-started/install/windows) and add it to your system PATH.
2. **Open a Terminal:** Navigate to this `mobile` folder.
3. **Generate Platform Files:** Run the following command. It will create the missing `android`, `ios`, and other necessary native files *without* overwriting the custom `lib` directory we've built:
   ```bash
   flutter create .
   ```
4. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
5. **Run the App:**
   ```bash
   flutter run
   ```

---

## App Architecture

The app follows a feature-first architecture using **Riverpod** for state management and **Dio** for networking.

### Key Screens Implemented
- **Auth:** Login and Account/Profile screens.
- **Dashboard:** Hero slider for career dreams and a list of recommended content cards. Features a custom glassmorphic Top Floating Navbar.
- **Content Detail:** Embedded YouTube player using `youtube_player_flutter`, along with XP and metadata.
- **Distraction/Focus Apps:** Grid view of blocked apps that can be unlocked.
- **Membership & Rewards:** Circular progress indicator for XP and a list of redeemable rewards.
- **Pomodoro Timer:** A custom circular focus timer.
- **Statistics:** A daily/weekly progress bar chart using `fl_chart`.

### Connecting to the Backend
The base API URL is defined in `lib/core/api/api_constants.dart`. 
- By default, it is set to `http://10.0.2.2:8000/api/v1` (which maps to `localhost` on the host machine when using an Android Emulator).
- If you are running on a physical device, update this to your computer's local IP address (e.g., `http://192.168.1.X:8000/api/v1`).
