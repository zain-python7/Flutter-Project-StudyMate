# StudyMate

**Plan Smart. Learn Better.**

StudyMate is a gamified student planner built with Flutter. It helps students manage tasks, stay consistent with Duolingo-style streaks, focus with a study/break timer, calculate their GPA, and study with an AI buddy powered by Google Gemini.

## Screenshots

Screenshots of the app are in the [screenshots](screenshots/) folder

## Features

- **Dashboard:** greeting, daily motivational quotes, live stats, today's classes, next exam and upcoming tasks
- **Tasks:** subjects, priorities, due dates, filters (Pending, Today, Overdue, Done), swipe to delete
- **XP and levels:** earn XP for finishing tasks, goals and study sessions, with level-up rewards and ranks
- **Streaks:** Duolingo-style streak with freeze days, monthly calendar history, activity log and milestones
- **Study timer:** separate study and Break timers; pause to take a break and study resumes automatically afterwards
- **GPA calculator:** subject cards, credit hours, colored grade chips, live GPA ring and a detailed report
- **AI Study Buddy:** ask questions or get quizzed on any topic (Google Gemini)
- **Notes, timetable, exam countdown, subjects and grades, goals, calendar view**
- **Profile:** photo upload, level and XP, stats, achievement badges, light and dark mode
- **Offline storage:** all data is saved locally on the device with SQLite

## Tech Stack

- Flutter and Dart (Material 3)
- SQLite (`sqflite`) for local storage
- Google Gemini API for the AI Study Buddy
- `image_picker` for profile photos
- `http` for API requests

## Getting Started

1. Install [Flutter](https://docs.flutter.dev/get-started/install).
2. Clone the repo and install packages:
   ```
   git clone https://github.com/zain-python7/studymate.git
   cd studymate
   flutter pub get
   ```
3. Create your API key file. Copy `lib/config.example.dart` to `lib/config.dart` and paste your own Gemini key from [Google AI Studio](https://aistudio.google.com/):
   ```dart
   const builtInGeminiKey = 'YOUR_KEY_HERE';
   ```
   Leave it as `PASTE_YOUR_KEY_HERE` to run the app without the AI feature.
4. Run the app:
   ```
   flutter run
   ```
5. Build an APK:
   ```
   flutter build apk --release
   ```
   The file will be in `build/app/outputs/flutter-apk/app-release.apk`.

## Download

Download the latest APK from the [Releases](../../releases) page, then open it on your Android phone and allow "install unknown apps".

## Project Structure

```
lib/
  main.dart          app entry and theme
  store.dart         SQLite storage, XP and streak logic
  home_page.dart     dashboard
  tasks_page.dart    tasks
  study_page.dart    study and break timer
  streak_page.dart   streak details
  gpa_page.dart      GPA calculator
  ai_page.dart       AI Study Buddy
  profile_page.dart  profile, badges, settings
  ...
```

## Author

**Zain Ul Abideen**
[LinkedIn](https://www.linkedin.com/in/zain-ul-abideen-745aab320/) | [GitHub](https://github.com/zain-python7)

Feedback and ideas are welcome.
