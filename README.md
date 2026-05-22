# Simple Calc

A simple Flutter calculator app built for Android Studio and GitHub.

## Features

- Basic arithmetic: `+`, `-`, `*`, `/`
- Clear button
- Simple dark calculator UI
- Split into separate files for easier navigation

## Project Structure

```text
lib/
├── main.dart
├── app.dart
├── screens/
│   └── calculator_page.dart
└── widgets/
	└── calc_button.dart
test/
└── widget_test.dart
```

## Tech Stack

- Flutter
- Dart
- Material Design

## Run the App

From the project folder:

```powershell
cd C:\Users\Amalsha\simple_calc
flutter pub get
flutter run -d chrome
```

To run on an Android emulator or phone:

```powershell
cd C:\Users\Amalsha\simple_calc
flutter devices
flutter run
```

## Test

```powershell
cd C:\Users\Amalsha\simple_calc
flutter test
```

## GitHub Upload

If this is a new Git repo, use:

```powershell
git add .
git commit -m "Initial Flutter calculator app"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/simple_calc.git
git push -u origin main
```

## Notes

- The app entry point is `lib/main.dart`
- The main UI is in `lib/screens/calculator_page.dart`
- Reusable calculator buttons are in `lib/widgets/calc_button.dart`
- `flutter analyze` and `flutter test` both pass in this project
