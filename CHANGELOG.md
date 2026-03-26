# ClassWidget Changelog

## v3.0.0 (Production Release)

The "Production Hardening" release. Massive reliability improvements, unified database architecture, and UI stability for all screen sizes.

### 🏗️ Unified Database & Performance (v3)
* **Unified Event Table**: Migrated tasks and events into a single high-performance `events` table with robust legacy migration logic.
* **Atomic Transactions**: Implemented database `Batch` operations for zero-risk data clearing and bulk importing.
* **Memory Safety**: Disposed of background debounce timers and implemented native SQLite cleanup to prevent long-term leaks.

### 🔴 Widget & Android Resilience
* **Persistent Alarms**: Hardened Kotlin alarm scheduling to ensure home screen countdowns persist across midnight and deep-sleep (Doze).
* **Boot Recovery**: Implemented high-priority `BootReceiver` for instant widget reactivation after device restarts.
* **Lifecycle Syncing**: App now immediately triggers a home-widget update on resume, ensuring data consistency without manual refresh.

### 🎨 UI/UX Stability & Modernization
* **Sliver Refactor**: Completely rebuilt the Import Preview screen using `CustomScrollView` and `Slivers` to eliminate "bottom overflow" errors on all devices.
* **Material 3 Tokens**: Updated core UI to use modern `surfaceContainerHighest` and `withValues` alpha tokens for future-proof styling.
* **Smart Dashboard**: Corrected indexing logic for "Today" and better handling of empty states in the 14-day view.

---

## v2.1.0

Maintenance and Bug Fix Release.

Features:
* **Database Cleanups**: Fixed recursive method calls and corrected `getTasks()` implementation to point to the right table.
* **Theme Uniformity**: Synchronized theme defaults across `PreferenceService` and `ThemeController`.
* **Repository Polish**: Cleaned up build artifacts and updated meta-documentation.

---

## v2.0.0

Improved UI/UX changes for better accessibility and aesthetics.

Features:
* **Dark Academic Gold Theme**: A high-contrast color palette paired with readable local fonts (Outfit for headers, Inter for body) to enhance legibility.
* **Modern Navigation**: Replaced the drawer with a persistent Bottom Navigation Bar for easier one-handed reachability.
* **Refined Schedule View**: Color-coded subject assignments, staggered animations for smoother rendering, and clearer empty states.
* **Enhanced Task Management**: Added swipe-to-delete gestures, visual priority indicators, and interactive completion toggles.
* **Redesigned Import Flow**: Better layout framing to prevent UI overflow on smaller screens and high-contrast confirmation dialogs.
* **Accessibility Enhancements**: Simplified Theme Toggle (binary Light/Dark mode) and improved touch targets.

---

## v1.1.0

Horizontal swipe navigation and improved synchronization.

Features:

* **Horizontal Swipe Navigation**: Seamlessly browse schedules for up to 14 days directly from the dashboard.
* **Automatic Midnight Sync**: Native Android listeners ensure the widget is always up-to-date at the start of a new day.
* **Zero-Touch Background Refresh**: Flutter background tasks now wake up on system time changes for instant data consistency.
* **Dashboard State Management**: Fixed issue where app kept previous day's view on resume; now automatically resets to today.

---

## v1.0.0

Initial release.

Features:

* CSV schedule import
* Android home screen widget (3 sizes)
* Dark / Light mode
* Task / To-Do system
* Task completion from widget
