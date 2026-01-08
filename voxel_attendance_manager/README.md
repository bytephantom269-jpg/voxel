# Flutter Attendance Manager

A complete offline Flutter mobile/desktop application for employee attendance tracking. The app operates entirely offline with a local SQLite database, featuring barcode scanning, employee management, attendance logging, and configurable late arrival detection.

## Features

- ✅ **Complete Offline Operation** - All data stored locally in SQLite
- ✅ **Barcode Scanning** - Manual barcode entry with automatic status detection
- ✅ **Employee Management** - Add, view, and delete employees with unique barcodes
- ✅ **Attendance Logging** - Automatic IN/OUT/LATE status tracking with timestamps
- ✅ **Configurable Late Time** - Set custom late arrival time via Settings
- ✅ **Desktop Platform Support** - Windows, macOS, and Linux using sqflite_common_ffi
- ✅ **Material Design 3** - Modern, clean UI with blue theme
- ❌ **NO Audio** - Completely silent operation (visual feedback only)
- ❌ **NO Cloud Dependency** - Works without internet connection

## Technology Stack

- **Framework:** Flutter 3.x
- **Database:** SQLite (sqflite for mobile, sqflite_common_ffi for desktop)
- **State Management:** Provider pattern
- **Settings Persistence:** SharedPreferences
- **Date Formatting:** intl package

## Project Structure

```
lib/
├── main.dart                      # App entry point with desktop initialization
├── models/
│   ├── employee.dart              # Employee data model
│   └── attendance_log.dart        # Attendance log data model
├── services/
│   └── database_service.dart      # SQLite database operations
├── providers/
│   ├── settings_provider.dart     # Settings state management
│   ├── employee_provider.dart     # Employee state management
│   └── attendance_provider.dart   # Attendance state management
├── screens/
│   ├── home_screen.dart           # Main screen with TabBar navigation
│   ├── scanner_screen.dart        # Barcode scanning interface
│   ├── employees_screen.dart      # Employee CRUD operations
│   ├── logs_screen.dart           # Attendance history view
│   └── settings_screen.dart       # Late time configuration
└── utils/
    └── config.dart                # App constants
```

## Prerequisites

### Install Flutter

1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Extract the archive to a location (e.g., `C:\flutter` or `~/flutter`)
3. Add Flutter to your PATH:
   - **Windows:** Add `C:\flutter\bin` to System Environment Variables
   - **macOS/Linux:** Add `export PATH="$PATH:$HOME/flutter/bin"` to `.bashrc` or `.zshrc`
4. Verify installation: `flutter --version`
5. Run Flutter doctor to check dependencies: `flutter doctor`

### Platform-Specific Setup

#### Windows
```bash
flutter doctor
# Install Visual Studio 2022 with "Desktop development with C++" if prompted
```

#### macOS
```bash
flutter doctor
# Install Xcode and CocoaPods if prompted
```

#### Linux
```bash
sudo apt-get update
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
flutter doctor
```

## Installation & Setup

1. **Clone or Download this project**

2. **Navigate to project directory:**
   ```bash
   cd attendance_manager
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Verify everything is set up correctly:**
   ```bash
   flutter doctor
   ```

## Running the Application

### For Development

```bash
flutter run
```

This will launch the app on your connected device or default platform.

### Select Specific Platform

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Mobile (if device connected)
flutter run -d <device-id>
```

### List Available Devices

```bash
flutter devices
```

## Building for Distribution

### Windows
```bash
flutter build windows --release
```
Executable will be in: `build\windows\runner\Release\`

### macOS
```bash
flutter build macos --release
```
App bundle will be in: `build/macos/Build/Products/Release/`

### Linux
```bash
flutter build linux --release
```
Executable will be in: `build/linux/x64/release/bundle/`

## How to Use

### 1. Add Employees
1. Navigate to **Employees** tab
2. Enter unique barcode and employee name
3. Click **Add Employee**
4. Employee will appear in the list below

### 2. Scan Barcode (Clock In/Out)
1. Navigate to **Scanner** tab
2. Enter barcode or employee ID
3. Press Enter or click **Submit**
4. System automatically detects:
   - **IN** - First scan or after clocking OUT
   - **OUT** - After clocking IN or LATE
   - **LATE** - Clocking IN after configured late time

### 3. View Attendance Logs
1. Navigate to **Logs** tab
2. View all attendance records sorted by newest first
3. Status badges show:
   - 🟢 **IN** (Green)
   - 🔵 **OUT** (Blue)
   - 🔴 **LATE** (Red)

### 4. Configure Late Time
1. Navigate to **Settings** tab (or click gear icon in top-right)
2. Adjust **Hour** slider (0-23)
3. Adjust **Minute** slider (0-59)
4. Settings save automatically
5. Default late time: **11:30 AM**

## Database

The application uses SQLite database stored locally:

- **Mobile:** App's documents directory
- **Desktop:** Application documents folder

### Database Schema

**employees table:**
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `barcode` TEXT UNIQUE NOT NULL
- `name` TEXT NOT NULL
- `photoPath` TEXT (reserved for future use)
- `createdAt` TEXT NOT NULL

**attendance_logs table:**
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `employeeId` INTEGER NOT NULL
- `employeeName` TEXT NOT NULL
- `status` TEXT NOT NULL (IN, OUT, or LATE)
- `timestamp` TEXT NOT NULL

## Attendance Logic

When a barcode is scanned:

1. Look up employee by barcode
2. If not found → Display "Employee not found"
3. Get last attendance log for employee
4. Determine status:
   - **No previous log** → IN (or LATE if past late time)
   - **Last status was IN or LATE** → OUT
   - **Last status was OUT** → IN (or LATE if past late time)
5. Insert new log with current timestamp
6. Display confirmation: "{Employee Name} - {STATUS}"

## Troubleshooting

### Flutter command not found
- Ensure Flutter is added to your PATH
- Restart terminal/command prompt after installation

### sqflite_common_ffi errors on desktop
- The app automatically initializes sqflite_common_ffi for desktop platforms
- Ensure you're using Flutter 3.x or later

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Database issues
- Database is created automatically on first launch
- Delete app data to reset database (varies by platform)

## Development Notes

- **No Audio Libraries** - Project intentionally excludes all audio functionality
- **Offline First** - No network permissions required
- **Cross-Platform** - Supports Windows, macOS, Linux, Android, and iOS
- **State Management** - Uses Provider pattern for reactive UI updates
- **Database Singleton** - DatabaseService uses singleton pattern for consistency

## Version

**Version:** 1.0.0

## License

This project is provided as-is for attendance tracking purposes.

## Support

For Flutter-specific issues, visit:
- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter GitHub Issues](https://github.com/flutter/flutter/issues)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)

## Building on Replit

Note: This project was generated in the Replit environment but requires local Flutter installation to run. Replit does not provide Flutter mobile emulators or desktop windowing systems. To develop and run this app:

1. Download all project files
2. Install Flutter SDK locally
3. Run `flutter pub get` and `flutter run` on your local machine

---

**Happy Attendance Tracking!** 🎯
