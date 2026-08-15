# Grocery Control

**Grocery Control** is a shared, realtime checklist app for shopping lists (and any similar checklist). Multiple people can watch and update the same group list over the cloud—no mid-shopping calls, texts, or paper lists.

For architecture (data model, Cloud Functions, app flow), see [ARCHITECTURE.md](ARCHITECTURE.md).

## Features

- Email/password sign-up and sign-in
- Shared groups (checklists) with realtime item sync
- Create groups; join via QR code
- Add, edit, check/uncheck, delete, and tag items
- Owner-only group rename

## Prerequisites

| Tool | Notes |
|------|--------|
| [Flutter](https://docs.flutter.dev/get-started/install) | Dart SDK `>= 3.12.2` (see `pubspec.yaml`) |
| Chrome (or another browser) | Primary target today is **web** |
| [Node.js](https://nodejs.org/) | Only needed for Cloud Functions |
| [Firebase CLI](https://firebase.google.com/docs/cli) | Only needed to deploy/emulate functions |
| Firebase project access | Project id: `grocery-control` |

Check Flutter:

```bash
flutter doctor
```

## Quick start (web)

Firebase options for **web** are already in `lib/firebase_options.dart`. That is the supported path out of the box.

```bash
# From the repo root
flutter pub get
flutter run -d chrome
```

Other useful commands:

```bash
# List devices
flutter devices

# Release web build (output under build/web)
flutter build web

# Analyze
flutter analyze
```

Serve the release build locally if you want:

```bash
# After flutter build web
# e.g. with any static file server pointing at build/web
```

## Project layout (build-relevant)

```
grocery-control/           # Flutter app root — run flutter commands here
├── lib/
├── web/
├── android/               # Scaffold present; Firebase options not configured yet
├── ios/                   # Scaffold present; Firebase options not configured yet
└── firebase_functions/    # Cloud Functions (SignUp, CreateGroup, JoinGroup)
    ├── firebase.json
    └── functions/
```

## Firebase backend

The app expects:

- **Auth** — email/password
- **Firestore** — users, groups, items
- **Cloud Functions** — `SignUp` (auth onCreate), `CreateGroup`, `JoinGroup`

Functions live under `firebase_functions/`. Deploy and emulate from that directory (it has its own `firebase.json` and `.firebaserc`).

### Install and build functions

```bash
cd firebase_functions/functions
npm install
npm run build
```

> `package.json` pins `"engines": { "node": "12" }`. Use a compatible Node version (or update the engine + Firebase runtime when you modernize the functions).

### Emulators (optional)

From `firebase_functions/`:

```bash
cd firebase_functions
firebase emulators:start
```

Configured ports: Auth `9099`, Functions `5001`, Firestore `8081`, Emulator UI enabled.

To point the Flutter app at emulators, you must wire `useFirestoreEmulator` / `useFunctionsEmulator` / Auth emulator in code (not configured by default).

### Deploy functions

```bash
cd firebase_functions
firebase login
firebase use grocery-control   # if needed
firebase deploy --only functions
```

Or from `firebase_functions/functions`:

```bash
npm run deploy
```

## Android / iOS (not configured yet)

Native runners exist under `android/` and `ios/`, but `DefaultFirebaseOptions` only defines **web**. Running on a phone/emulator will fail Firebase init until you regenerate options:

```bash
# Install FlutterFire CLI if needed
dart pub global activate flutterfire_cli

# From repo root, while logged into Firebase
flutterfire configure --project=grocery-control
```

That updates `lib/firebase_options.dart` (and platform config). Then:

```bash
flutter run -d android
# or
flutter run -d ios
```

For QR scanning on device, also add camera permissions (`AndroidManifest.xml` / `Info.plist`)—they are not fully set up for release scanning yet.

## Common issues

| Symptom | Likely fix |
|---------|------------|
| `UnsupportedError` / Firebase options for android/ios | Run `flutterfire configure`, or use `flutter run -d chrome` |
| “Error - No Group Found” after signup | Ensure Cloud Function `SignUp` is deployed and Auth triggers are enabled |
| Create/join group fails | Ensure `CreateGroup` / `JoinGroup` are deployed; user must be signed in |
| `flutter pub get` fails on SDK | Upgrade Flutter so Dart satisfies `>= 3.12.2` |

## Docs

- [ARCHITECTURE.md](ARCHITECTURE.md) — system design, schema, flows
- [TODO.md](TODO.md) — planned features and polish
