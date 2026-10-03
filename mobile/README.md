# Homecare Platform Mobile App

The Flutter mobile application for the Homecare Platform, with native apps for customers and service providers.

## Roles

- **Customers** — browse service categories, create service requests with multiple items, review and approve provider quotes, track assignments, record payments, leave reviews, report issues, and view notifications.
- **Service providers** — manage service listings, view and update assigned jobs (in progress / completed), view reviews and ratings, and manage their profile, location, and notifications.

## Technology

- Flutter / Dart

## Running locally

Install the Flutter SDK, then run the app with the API base URL for your environment:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

`API_BASE_URL` is compile-time configuration. Without it, the app falls back to development defaults (`http://10.0.2.2:8000` on the Android emulator, `http://localhost:8000` otherwise). Always pass `API_BASE_URL` for release builds.

## Tests

```bash
flutter test
```

## Current limitations

- The API base URL is set at build time (`--dart-define`), not at runtime.
- Payments are recorded in the app only; there is no real payment gateway integration yet.
- Notifications are in-app only; push notifications are not implemented.
- Password reset and contact-form emails are not sent yet (the backend stores the records).
