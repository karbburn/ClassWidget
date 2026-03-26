# ClassWidget 🎓

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://android.com)
[![Stable Version](https://img.shields.io/badge/Release-v3.0.0-blue.svg?style=for-the-badge)](https://github.com/karbburn/ClassWidget/releases)

---

## 🚀 What's New in v3.0.0 (Production Release)

The "Production Hardening" release. Focused on 100% data integrity, native Android reliability, and modern Material 3 styling.

- **Unified Database Architecture**: Migrated to a single high-performance `events` table with atomic `Batch` transactions.
- **Resilient Home Screen Widget**: Completely rewritten Kotlin provider for guaranteed background updates and instant boot-time recovery.
- **Sliver UI Refactor**: The Import Preview screen now uses a high-performance `CustomScrollView` with `Slivers` for zero-overflow layouts.
- **Lifecycle Synchronization**: App-to-Widget state syncing now happens immediately on resume, ensuring real-time accuracy.

---

## ⚡ Key Features

### 📅 Intelligent Schedule Overhaul
- **Dynamic Excel/CSV Import**: Automated parsing of complex university spreadsheets with intelligent time-slot detection.
- **Double-Quote CSV Support**: Robust handling of complex cells and multiline strings during imports.
- **Strict Sheet Isolation**: Explicit sheet selection ensures data integrity for individual sections and batches.
- **ISO 8601 Compliance**: Robust date parsing architecture for seamless synchronization across semesters.

### 🖼️ Premium Widget Ecosystem
- **Premium Dark UI**: Deep navy widget design with high-contrast typography and sky-blue accents, optimized for at-a-glance readability on any home screen.
- **Adaptive Sizing**: Native Support for Small (2x1), Medium (4x2), and Large (4x4) interactive layouts.
- **Interactive Checkbox**: Mark tasks as completed directly from the home screen with instant state-syncing.
- **Smart Countdown**: Real-time "Up Next" tracking for upcoming classes and assignments.
- **Persistent Alarm Ticks**: Native Android listeners and Doze-mode persistence for 24/7 accuracy.

### ✅ Integrated Task Management
- **Context-Aware Tasks**: Link assignments directly to specific course dates.
- **Unified Timeline**: View classes and to-dos in a single, chronological dashboard.
- **Smart Indexing**: Chronologically-aware view that always anchors to "Today's" schedule on app launch.

### 🎨 Material 3 Architecture (v3.0)
- **Modern Tokens**: Updated UI to use `surfaceContainerHighest` and unified alpha values for premium aesthetics.
- **High-Contrast Typography**: Readability enhanced with Outfit (Headers) and Inter (Body) font pairings.
- **Responsive Layouts**: Fully scrollable Sliver components that adapt to high-density content without overflows.
---

## 🛠️ Technology Stack

- **Core**: Flutter / Dart
- **Database**: SQLite (Local-first reliability)
- **Native Bridge**: Kotlin (Android AppWidget Provider)
- **Design System**: Custom dark UI with CSS-inspired XML layouts
- **State Management**: Provider / Controller patterns
- **Utilities**: HomeWidget, Excel Parser, Intl (Localization)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- Android Device/Emulator (API 24+)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/karbburn/ClassWidget.git
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

## 📄 License
Internal Development / Proprietary - © 2026 Karbburn.
