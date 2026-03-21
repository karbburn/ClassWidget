# ClassWidget Changelog

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
