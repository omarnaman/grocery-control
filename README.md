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
| [Node.js](https://nodejs.org/) | Node **22** for Cloud Functions |
| [Firebase CLI](https://firebase.google.com/docs/cli) | Only needed to deploy/emulate functions locally |
| Firebase project access | Project id: `grocery-control` (Blaze plan required for Functions) |

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

> `package.json` pins `"engines": { "node": "22" }`. Use Node 22 locally when installing or building functions.

### Emulators (optional)

From `firebase_functions/`:

```bash
cd firebase_functions
firebase emulators:start
```

Configured ports: Auth `9099`, Functions `5001`, Firestore `8081`, Emulator UI enabled.

To point the Flutter app at emulators, you must wire `useFirestoreEmulator` / `useFunctionsEmulator` / Auth emulator in code (not configured by default).

### Deploy functions (local)

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

## GitHub Actions deployment

CI deploys from the **`prod`** branch only. **`main`** is for development and does not ship.

| Branch / event | Hosting | Cloud Functions |
|----------------|---------|-----------------|
| Push to `prod` | Live channel | Deployed (when `firebase_functions/**` changes) |
| PR targeting `prod` | Preview channel (PR comment with URL) | Not deployed |
| Push / PR on `main` | No deploy | No deploy |
| Manual `workflow_dispatch` | Live Hosting (run from `prod`) | Functions (run from `prod`) |

**Ship a release:** land work on `main`, then merge `main` into `prod` (or open a PR into `prod`). Merging to `prod` triggers production deploys.

### One-time setup

1. Create the GitHub repo, push `main`, then create and push a `prod` branch.
2. Create a GCP service account on project `grocery-control` with at least:
   - Firebase Hosting Admin
   - Cloud Functions Admin
   - Service Account User
   - Cloud Build Editor
   - Artifact Registry Writer
3. Add the service account JSON as the GitHub secret `FIREBASE_SERVICE_ACCOUNT`.
4. Confirm the Firebase project is on the **Blaze** plan (required to deploy Functions).

Workflows:

- [`.github/workflows/deploy-hosting.yml`](.github/workflows/deploy-hosting.yml) — Flutter web build → Firebase Hosting
- [`.github/workflows/deploy-functions.yml`](.github/workflows/deploy-functions.yml) — npm build → Cloud Functions

### Manual deploy from GitHub

In the repo: **Actions** → choose **Deploy Hosting** or **Deploy Functions** → **Run workflow** → select branch **`prod`**.

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
