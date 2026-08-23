# Minimal Clock

A minimalist desktop clock app for macOS, Windows, and Linux — clock, timers, stopwatches, and shareable countdowns.

## Features

### Clock
- Clean, minimalist full-screen digital clock.
- Adjustable font size and 12/24-hour display.

### Timers & Stopwatches
- Start a timer by **Duration** (set hours/minutes/seconds) or **Until Time** (pick a target clock time).
- Start a **Stopwatch** that counts up from zero.
- Run multiple timers and stopwatches at once, each shown in a list with its own start/pause/resume/reset controls and its own completion notification.
- Countdown time and elapsed stopwatch time are anchored to a real wall-clock timestamp, so they stay accurate even if the app is backgrounded or the machine sleeps — no time is silently lost.
- Stopwatch displays `mm:ss.hundredths`, switching to `h:mm:ss.hundredths` past an hour.

### Countdowns
- Create countdowns to a future date/time, with an optional **category** (e.g. Birthdays, Trips, Work) set by the owner.
- Filter your countdown list by category.
- **Pin** any countdown (yours or one you're following) to keep it sorted to the top of your list — this is a personal preference, so different people following the same countdown can each pin it independently.
- Share a countdown by link or ID so others can follow it, and toggle notifications for a countdown you follow.
- Look up and follow a countdown by ID.
- Delete a countdown you own, or remove one you're only following, from the list (swipe) or its detail screen.
- Requires a connected Supabase project — see `lib/core/services/supabase_service.dart` and the SQL in `supabase/migrations/` for the schema.

### Settings
- Customize clock font size, 12/24-hour format, and other display preferences.

## Getting Started (development)

This is a Flutter project targeting desktop platforms (macOS, Windows, Linux).

1. Install [Flutter](https://docs.flutter.dev/get-started/install) with desktop support enabled.
2. Configure a Supabase project and set its URL/anon key in `lib/core/services/supabase_service.dart` to enable the Countdowns feature.
3. Run the migrations in `supabase/migrations/` against your Supabase project.
4. `flutter pub get`
5. `flutter run -d macos` / `-d windows` / `-d linux`

## Builds

GitHub Actions workflows in `.github/workflows/` build:
- Linux AppImage & `.deb`
- Windows installer
- macOS Developer-ID-signed, notarized DMG
- Mac App Store package (uploaded to App Store Connect)
