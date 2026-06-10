# ClassWidget

**Flutter** **Android** **v3.1.0**

A student scheduling app for Android with a home screen widget. Import university timetables from Excel or CSV files, manage tasks and assignments, and view your daily schedule in a unified timeline -- all with a Material 3 dark theme.

---

## Features

### Schedule Import
Import university timetables from Excel (.xlsx) or CSV files. The parser automatically detects time slots, dates, professors, and sections. A preview screen lets you verify imported data before saving.

### Android Home Screen Widget
Three widget sizes (2x1 small, 4x2 medium, 4x4 large) show your daily schedule directly on the home screen. Features include real-time "Up Next" countdowns, interactive task checkboxes that update the database without a Flutter cold-start, and dark theme styling.

### Task Management
Create, edit, complete, and delete tasks. Swipe-to-delete with priority indicators. Tasks appear alongside classes in the chronological dashboard.

### Unified Timeline
Classes and tasks are displayed together in a single scrollable daily view. The dashboard anchors to today's schedule on launch.

### Material 3 Theme
Full Material 3 design with a dark color scheme, sky-blue accent palette, and Inter typography. A theme toggle switches between light and dark modes.

### Midnight Persistence
Android alarm listeners survive Doze mode and device reboots (via `BootReceiver`). Widget alarms and day-boundary updates remain reliable across sleep and restart cycles.

---

## Screenshots

Screenshots will be added here.

---

## Tech Stack

- **Core**: Flutter / Dart 3.0+
- **State Management**: flutter_riverpod (reactive providers)
- **Database**: SQLite (via sqflite)
- **Native Bridge**: Kotlin (AppWidget Provider, ListRemoteViewsService, BootReceiver)
- **Widget Framework**: home_widget, workmanager
- **File Parsing**: excel, csv, file_picker
- **Utilities**: intl, shared_preferences, path

---

## Getting Started

### Prerequisites

- Flutter SDK 3.0+ / Dart 3.0+
- Android Studio or VS Code with Flutter extensions
- Android device or emulator (API 24+)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/karbburn/ClassWidget.git
   cd ClassWidget
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

---

## Project Structure

```
lib/
  database/          -- SQLite helper (database_helper.dart)
  models/            -- Data models (schedule_event.dart, task_item.dart)
  repositories/      -- Data access layer (schedule_repository, task_repository)
  providers/         -- Riverpod state providers (theme, database, preferences, widget_data)
  services/          -- Business logic (schedule import, export, widget sync, preferences)
  ui/                -- Screens (dashboard, day schedule, tasks, import, preview, add task)
  utils/             -- Constants, color utilities
  widgets/           -- Reusable widgets (theme toggle)
test/
  database/          -- Database helper tests
  repositories/      -- Repository unit tests
  ui/                -- Widget tests
```

---

## License

MIT
