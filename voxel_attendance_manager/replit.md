# Voxel Attendance Manager

## Overview

A complete offline Flutter desktop application for Windows/macOS/Linux with employee attendance tracking. The application operates entirely without internet connectivity by default, storing all data locally in SQLite. **Now includes optional multi-device sync** via Node.js backend for real-time data synchronization across devices in the same company. Features include manual barcode entry for employee check-in/check-out, automatic status detection (IN/OUT/LATE), employee management with photos and positions, configurable late arrival times, and Excel-based import/export functionality. Visual-only feedback with no audio ensures silent operation in professional environments. Professional Material Design 3 interface with modern deep blue theme (#1565C0).

## Status

**HYBRID SYNC ENABLED** - Successfully implemented multi-device synchronization with company code isolation. Standalone .exe works 100% offline; optional backend server enables real-time team sync.

## Recent Changes (Nov 26, 2025)

**Multi-Device Sync with Company Isolation:**
- Added Node.js backend server for optional real-time synchronization
- Company code system ensures complete data isolation between different organizations
- Each device syncs with backend when connected to internet
- Hybrid approach: Works offline locally, syncs changes when online
- Intelligent conflict resolution using timestamps (last-write-wins)
- Sync endpoints:
  - `POST /api/sync/upload` - Device uploads local changes
  - `GET /api/sync/download?companyCode=XXX` - Device downloads company-specific data
- Settings screen now includes:
  - Server URL configuration
  - Company code entry (e.g., ACME2024)
  - Enable/Disable sync toggle
  - Manual "Sync Now" button
  - Online/Offline status indicator
- Backend maintains separate database tables with companyCode field
- PostgreSQL ensures data integrity and concurrent access

## Previous Changes (Nov 24, 2025)

- Added comprehensive security patches:
  - Input validation for barcode, name, and position fields
  - File upload validation with size/format checks
  - CSV/Excel import validation with row limits
  - Image file validation
  - Safe error messaging (no sensitive data exposure)
  - SQL injection prevention (parameterized queries + input sanitization)
  - Directory traversal prevention
  - Denial-of-service mitigation (file size/row limits)
- Professional UI redesign:
  - Deeper blue color scheme (#1565C0)
  - Improved typography with letter spacing
  - Better spacing and visual hierarchy
  - Refined card and button styling
  - Status indicators with colored containers
- Added delete all logs functionality with confirmation dialog
- Redesigned to look like a professional desktop application

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture

**Platform**: Flutter 3.x desktop application (Windows/macOS/Linux)

**UI Framework**: Material Design 3 with deep blue theme (#1565C0)

**Navigation Pattern**: TabBar-based navigation with 3 primary sections:
- Scanner (barcode entry interface)
- Employees (CRUD operations)
- Logs (attendance history)

**State Management**: Provider pattern for reactive state updates:
- `EmployeeProvider` - manages employee data and operations
- `AttendanceProvider` - handles attendance logging and queries
- `SettingsProvider` - persists user preferences (late time threshold)

### Security Architecture

**Input Validation Layer** (`lib/utils/security.dart`):
- Barcode validation: alphanumeric, hyphens, underscores (max 100 chars)
- Name validation: letters, spaces, hyphens, apostrophes (max 255 chars)
- Position validation: alphanumeric, spaces, hyphens (max 100 chars)
- Image file validation: JPG/PNG/GIF/BMP only (max 5MB)
- Excel/CSV file validation: xlsx/xls only (max 10MB)
- File path validation: prevents directory traversal attacks

**Database Security**:
- Parameterized queries (SQLite) prevent SQL injection
- Database file in secure app directory
- Single instance database connection
- Row limits on CSV imports (max 10,000 rows)

**Error Handling**:
- Safe error messages (no stack traces or file paths exposed)
- User-friendly error feedback with red indicators
- Validation errors shown before database operations

### Backend Architecture

**Database**: SQLite with platform-specific implementations
- Desktop: `sqflite_common_ffi` for Windows/macOS/Linux using FFI bindings
- Database auto-migrations from v1 to v2 (adds position field to employees table)
- Secure database directory creation

**Data Models**:
1. **Employee** (`employee.dart`)
   - Fields: id, name, barcode (unique), position (optional), photoPath (optional), createdAt
   
2. **AttendanceLog** (`attendance_log.dart`)
   - Fields: id, employeeId, employeeName, timestamp, status (IN/OUT/LATE)

**Service Layer**:
- `DatabaseService` - SQLite CRUD operations, table creation, migrations
- `CSVService` - CSV import with validation and size limits
- `ExportService` - Excel file export with file picker

**Status Logic**:
- First scan of day = IN (or LATE if after configured time)
- Subsequent same-day scan = OUT
- Status automatically determined by comparing current time against late threshold

### Data Storage

**Primary Storage**: Local SQLite database
- Location: Platform-specific app data directory (via `path_provider`)
- All data persists locally on device
- No cloud sync or remote backup
- Secure file permissions

**Settings Storage**: SharedPreferences
- Stores user configuration (late arrival time threshold)

### Authentication and Authorization

**Not Implemented** - Application has no authentication. All users have full access. Suitable for single-user or trusted environment deployment.

## External Dependencies

### Flutter Packages

**Database & Storage**:
- `sqflite: ^2.2.8+4` - SQLite plugin
- `sqflite_common_ffi: ^2.2.0` - SQLite with FFI for desktop
- `path_provider: ^2.0.16` - Platform-specific storage directories
- `path: ^1.8.4` - Cross-platform path manipulation
- `shared_preferences: ^2.2.2` - Persistent key-value storage

**UI & Features**:
- `provider: ^6.0.0` - State management
- `intl: ^0.19.0` - Date/time formatting
- `image_picker: ^1.0.0` - Employee photo capture
- `file_picker: ^5.3.0` - File selection dialogs
- `excel: ^1.1.12` - Excel import/export
- `csv: ^6.0.0` - CSV parsing

### Platform Requirements

**Desktop Support**: Windows/macOS/Linux via `sqflite_common_ffi`
- FFI initialization in `main.dart` before database access
- Platform-specific setup required

### Notable Exclusions

- **NO Audio Libraries**: Visual-only feedback throughout
- **NO Network Libraries**: Complete offline operation
- **NO Asset Dependencies**: No images or icon files in assets/

## Deployment

### Flutter Application

**Windows Executable**: `build\windows\x64\runner\Release\voxel_attendance_manager.exe`
- Standalone, completely self-contained
- Works 100% offline with local SQLite
- Optional: Configure server URL in Settings to enable multi-device sync

### Backend Server (Optional for Multi-Device Sync)

**Location**: `backend/` directory

**Setup Steps**:
1. Install Node.js and PostgreSQL
2. Run `npm install` in backend folder
3. Create PostgreSQL database: `createdb voxel_sync`
4. Configure `.env` file with database credentials
5. Start server: `npm start`

**Server URLs**:
- Local network: `http://192.168.1.100:3000` (where 192.168.1.100 is server PC IP)
- Cloud hosting: Configure on external server (AWS, DigitalOcean, Heroku, etc.)

**Windows Installer** (Optional):
1. Install NSIS (nsis.sourceforge.io)
2. Use `installer.nsi` script in project root
3. Run: `"C:\Program Files (x86)\NSIS\makensis.exe" installer.nsi`
4. Output: `voxel_attendance_manager_installer.exe`

## Security Features

✅ **Input Validation** - All user inputs validated before database operations
✅ **File Upload Security** - File type and size validation
✅ **SQL Injection Prevention** - Parameterized queries + input sanitization
✅ **Directory Traversal Prevention** - File path validation
✅ **DOS Mitigation** - File size limits and import row limits
✅ **Error Handling** - Safe messages without exposing system details
✅ **Secure File Handling** - Proper directory creation and file permissions

## Project Structure

```
lib/
├── main.dart                          # App entry, FFI initialization
├── models/
│   ├── employee.dart                  # JSON serialization for sync
│   └── attendance_log.dart            # JSON serialization for sync
├── providers/
│   ├── employee_provider.dart
│   ├── attendance_provider.dart
│   └── settings_provider.dart         # Company code & server URL storage
├── screens/
│   ├── home_screen.dart               # Main navigation container
│   ├── scanner_screen.dart            # Barcode scanning with validation
│   ├── employees_screen.dart          # Employee CRUD with security
│   ├── logs_screen.dart               # Attendance history with delete
│   └── settings_screen.dart           # Sync settings (URL, company code, manual sync)
├── services/
│   ├── database_service.dart          # Secure SQLite operations
│   ├── export_service.dart
│   ├── csv_service.dart               # CSV import with validation
│   └── sync_service.dart              # Multi-device sync (NEW)
└── utils/
    ├── config.dart                     # Constants and status definitions
    └── security.dart                   # Input validation and sanitization

backend/
├── server.js                          # Express.js sync server
├── package.json                       # Node.js dependencies
├── .env.example                       # Database config template
└── README.md                          # Backend setup instructions
```
