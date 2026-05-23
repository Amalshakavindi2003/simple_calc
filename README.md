# 🧮 Simple Calc - Professional Flutter Calculator

A feature-rich, professional-grade Flutter calculator application built with Material Design. Combines essential arithmetic operations with advanced scientific functions, supported by a sleek, modern UI with theme customization, persistent history, and smooth animations.

## ✨ Features

### 🔢 Calculator Operations
- **Basic Arithmetic**: Addition (+), Subtraction (-), Multiplication (*), Division (/)
- **Scientific Mode**: Toggle to access advanced mathematical functions
  - Trigonometric: sin, cos, tan
  - Logarithmic: log (base 10), ln (natural log)
  - Power Operations: x², x³, √ (square root)
  - Mathematical Constants: π (pi), e (Euler's number)

### 🎨 User Interface
- **Dual Theme Support**: Seamless dark/light theme switching
- **Professional Design**: Gradient background, shadow effects, auto-resizing display text
- **Number Formatting**: Comma-separated number display for easy readability (e.g., 1,000,000)
- **Smooth Animations**: Button press scale effects, fade animations for results, sliding history panel
- **Responsive Display**: Shows both expression (small text) and result (large text)

### 📊 History & Persistence
- **Calculation History**: Saves the last 10 calculations with persistent storage
- **History Panel**: Elegant sliding drawer from right side
- **Quick Restore**: Click any previous calculation to load it back
- **Auto-save**: History persists across app restarts

### ⌨️ Input Methods
- **Keyboard Support**: Direct typing for numbers and operations
- **Gesture Controls**: Swipe left to delete (backspace functionality)
- **Copy to Clipboard**: Quick copy button for results
- **Touch Interface**: Responsive button grid with visual feedback

### 🛠️ Technical Excellence
- **State Management**: Efficient setState() with SharedPreferences integration
- **Error Handling**: Smart validation for invalid inputs (e.g., log of negative numbers)
- **Code Organization**: Modular architecture with separate files for screens and widgets
- **Testing**: Full test coverage with flutter test - all tests passing
- **Analysis**: Clean code with flutter analyze - no warnings or errors

## 📁 Project Structure

```
lib/
├── main.dart                 # Application entry point
├── app.dart                  # App configuration and theme setup
├── screens/
│   └── calculator_page.dart  # Main calculator UI and logic
│       ├── Scientific mode toggle
│       ├── History panel drawer
│       ├── Theme management (dark/light)
│       ├── Display formatting with comma separators
│       └── Gesture & keyboard event handling
└── widgets/
    └── calc_button.dart      # Reusable button component with animations

test/
└── widget_test.dart          # Unit and widget tests

pubspec.yaml                  # Dependencies and project metadata
```

## 🛠️ Tech Stack

- **Framework**: Flutter (Latest)
- **Language**: Dart
- **UI**: Material Design 3
- **State Management**: setState() with StreamBuilder
- **Data Persistence**: SharedPreferences
- **Animations**: AnimatedSwitcher, SlideTransition, Transform.scale
- **Testing**: Flutter Test Framework

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- Dart SDK (comes with Flutter)
- Android Studio / VS Code with Flutter extensions

### Run the App

**On Chrome (Web):**
```powershell
cd C:\Users\Amalsha\simple_calc
flutter pub get
flutter run -d chrome
```

**On Android Emulator/Device:**
```powershell
cd C:\Users\Amalsha\simple_calc
flutter devices
flutter run
```

### Run Tests
```powershell
cd C:\Users\Amalsha\simple_calc
flutter test
```

### Code Analysis
```powershell
cd C:\Users\Amalsha\simple_calc
flutter analyze
```

## 💡 Usage Guide

### Basic Mode
1. Enter numbers using the number buttons
2. Select an operation (+, -, *, /)
3. Enter second number
4. Press = to calculate
5. Use C to clear

### Scientific Mode
1. Tap the **Science** button to toggle scientific mode
2. Access advanced functions: sin, cos, tan, log, ln, √, x², x³
3. Use π and e constants for mathematical calculations
4. Error handling prevents invalid operations (e.g., log of negative numbers)

### Theme Switching
- Tap the **theme toggle** button (sun/moon icon) in top bar
- Switch seamlessly between dark and light themes

### History
1. Tap the **History** button in top bar
2. View last 10 calculations
3. Click any calculation to restore it
4. History persists across app restarts

### Copy Result
- Tap the **Copy** button to copy current result to clipboard

## 🔗 GitHub Repository

This project is version-controlled using Git with feature branches. All major features were developed on separate branches and merged into main for production-ready code.

**Repository**: [Amalsha-kavindi-2003/simple_calc](https://github.com/Amalsha-kavindi-2003/simple_calc)

## 📝 Project Details

- **Entry Point**: `lib/main.dart`
- **Main UI Logic**: `lib/screens/calculator_page.dart`
- **Reusable Components**: `lib/widgets/calc_button.dart`
- **Code Quality**: ✅ `flutter analyze` - No warnings or errors
- **Test Coverage**: ✅ `flutter test` - All tests passing
- **Build Status**: Production-ready

## 🎯 Key Improvements & Features

- ✅ Persistent calculation history with SharedPreferences
- ✅ Smooth animations and transitions for professional feel
- ✅ Responsive and accessible UI with dark/light theme support
- ✅ Scientific functions with comprehensive error handling
- ✅ Number formatting for better readability
- ✅ Multi-input method support (touch, keyboard, gestures)
- ✅ Comprehensive testing and code analysis

## 📦 Dependencies

See `pubspec.yaml` for complete dependency list. Key packages:
- `flutter`: UI framework
- `shared_preferences`: Local data persistence
- `material_design_icons_flutter`: Icon library

## 📄 License

This project is available on GitHub. Feel free to fork and contribute!

## 👨‍💻 Author

Developed by **Amalsha Kavindi** - [GitHub](https://github.com/Amalsha-kavindi-2003)
