# Grocery Control — Architecture

## 1. Overview

**Grocery Control** is a shared, realtime checklist app built for household shopping lists (and general checklists). Multiple people watch and update the same list over the cloud so mid-shopping calls, texts, or paper lists are unnecessary.

**Primary capabilities:**

- Email/password authentication
- Per-user groups (shared checklists), with a default group provisioned on signup
- Create groups and join others via QR code
- Realtime item list: add, edit, check/uncheck, delete, tag, and filter checked items
- Owner-only group rename

**Package / product:** `grocery_control` / “Grocery Control”  
**Firebase project:** `grocery-control`  
**Android application id:** `com.aqel.grocery_control`

---

## 2. System context

```
┌─────────────────┐         ┌──────────────────────────────────────┐
│  Flutter client │────────▶│  Firebase (project: grocery-control) │
│  (web primary)  │         │  • Auth (email/password)             │
│                 │         │  • Cloud Firestore                   │
│  screens /      │         │  • Cloud Functions (Node/TS)         │
│  services       │         └──────────────────────────────────────┘
└─────────────────┘
```

Clients talk to Firebase Auth, Firestore, and HTTPS callable Functions. Privileged multi-document writes (signup provisioning, create group, join group) run in Cloud Functions with the Admin SDK. Day-to-day item CRUD and group rename run from the client against Firestore.

---

## 3. Tech stack

| Layer | Technology |
|--------|------------|
| Client | Flutter (Dart SDK `>= 3.12.2`), Material, dark theme |
| Auth | Firebase Auth (email/password) |
| Database | Cloud Firestore |
| Server | Cloud Functions (TypeScript, Node 12 runtime in `package.json`) |
| QR | `qr_flutter` (display), `qr_code_scanner_plus` (scan) |

**Notable Flutter dependencies:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `qr_flutter`, `qr_code_scanner_plus`.

**Cloud Functions dependencies:** `firebase-admin`, `firebase-functions`.

There is no Provider, Riverpod, Bloc, or similar state-management package. UI state uses `StatefulWidget` / `setState`, plus `StreamBuilder` and `FutureBuilder` over Firebase streams and futures.

---

## 4. Repository layout

```
grocery-control/
├── lib/                         # Flutter application
│   ├── main.dart                # Entry, Firebase init, auth gate (Root)
│   ├── firebase_options.dart    # FlutterFire options (web configured today)
│   ├── models/                  # GroupModel, GroceryItemModel
│   ├── screens/                 # Login, Home, QRCodeScanner
│   ├── services/                # Auth, Database wrappers
│   ├── utils/                   # SortDirection
│   └── widgets/                 # Item card, tags, QR dialog, dialogs, checkbox
├── firebase_functions/          # Firebase Functions project
│   ├── .firebaserc              # default project: grocery-control
│   ├── firebase.json            # functions, rules path, emulators
│   └── functions/src/index.ts   # SignUp, CreateGroup, JoinGroup
├── android/, ios/, web/         # Platform runners
├── test/                        # Widget tests (currently stale)
├── pubspec.yaml
├── firebase.json                # FlutterFire platform map
├── README.md
└── TODO.md
```

---

## 5. Client architecture

### 5.1 Layering

```
UI (screens + widgets)
        │  constructor injection of FirebaseAuth / FirebaseFirestore
        ▼
Services (Auth, Database)  +  direct httpsCallable for CreateGroup / JoinGroup
        ▼
Firebase SDKs
        ▼
Auth · Firestore · Cloud Functions
```

Services are thin wrappers. `Auth` and `Database` receive SDK instances via constructors (manual DI). Create/join group callables are invoked from the UI (`Home`) rather than through a dedicated service.

### 5.2 Application bootstrap and navigation

**Entry:** `main()` → `runApp(App())` (`lib/main.dart`).

```
App (MaterialApp, ThemeData.dark)
  └─ FutureBuilder(Firebase.initializeApp)
       └─ Root
            └─ StreamBuilder(Auth.user / authStateChanges)
                 ├─ null  → Login
                 └─ User  → FutureBuilder(Database.getLastGroup)
                              └─ Home(group)  or  "No Group Found"
```

**Routing:** No named routes or router package. Navigation is:

- Auth-driven swap of the root child (`Login` ↔ `Home`)
- `Navigator.push` to `QRCodeScanner`
- `showDialog` for rename, create group, QR share, and delete confirmation

### 5.3 Screens

| Class | File | Responsibility |
|-------|------|----------------|
| `App` | `lib/main.dart` | Theme + Firebase init gate |
| `Root` | `lib/main.dart` | Auth stream → Login vs Home |
| `Login` | `lib/screens/login.dart` | Email/password sign-in and account creation |
| `Home` | `lib/screens/home.dart` | Item list, drawer (groups, create, filter, QR share/join), add/edit |
| `QRCodeScanner` | `lib/screens/qr_scanner.dart` | Camera scan; decode JSON; return payload via `Navigator.pop` |

### 5.4 Widgets

| Class | File | Role |
|-------|------|------|
| `GroceryItemCard` | `lib/widgets/item_card.dart` | Row: tap to select, checkbox to check, long-press to delete |
| `GroupQRCodeDialog` | `lib/widgets/group_qrcode.dart` | QR encoding join payload |
| `TextInputDialog` | `lib/widgets/textinput_dialog.dart` | Generic string prompt |
| `AqelCheckbox` | `lib/widgets/aqel_checkbox.dart` | Custom animated checkbox |
| `Tag` / `TagList` | `lib/widgets/tag.dart`, `tag_list.dart` | Editable tag chips |

### 5.5 Services

**`Auth`** (`lib/services/auth.dart`)

- `user` → `authStateChanges()`
- `createAccount` / `signIn` / `signOut`
- Returns `"Success"` or a Firebase error message string

**`Database`** (`lib/services/db.dart`)

| Method | Behavior |
|--------|----------|
| `streamGroups(uid)` | Resolve user’s `group_ref_array` to `List<GroupModel>` (one-shot Future despite the name) |
| `getLastGroup` / `setLastGroup` | Read/write `users/{uid}.last_group` |
| `streamItems(group, sortDirection)` | Realtime query on `items/{groupId}/items` ordered by `Name` |
| `updateGroupName` | Owner check on client, then update `groups/{id}.name` |
| `addItem` / `updateItem` / `deleteItem` | Writes to the items subcollection |

---

## 6. Domain model and Firestore schema

### 6.1 Entity relationships

```
User ──last_group──────────► Group
User ──group_ref_array─────► Group[]
Group.owner ───────────────► User.uid
Group.members[] ───────────► User.uid   (written by JoinGroup; not in Dart model)
Group 1──1 items/{groupId} (parent shell document)
         └── items/{groupId}/items/{itemId}
```

### 6.2 Collections

```
users/{uid}
  last_group: DocumentReference → groups/{groupId}
  group_ref_array: DocumentReference[] → groups

groups/{groupId}
  owner: string          # Firebase Auth UID
  name: string
  members?: string[]     # UIDs; set/updated by JoinGroup

items/{groupId}          # empty parent doc created on SignUp
  items/{itemId}
    Name: string
    Checked: bool
    Tags: string[]
```

**Naming note:** Item fields use PascalCase (`Name`, `Checked`, `Tags`). Group and user fields use lowercase / snake_case (`name`, `owner`, `last_group`, `group_ref_array`).

### 6.3 Dart models

**`GroupModel`** (`lib/models/group.dart`): `groupId`, `name`, `owner`. Equality by `groupId`. Server field `members` is not modeled in Dart.

**`GroceryItemModel`** (`lib/models/grocery_item.dart`): `itemId`, `name`, `checked`, `group`, `tags`. Built from `DocumentSnapshot` via factory constructors.

There is no dedicated Dart model for the user document.

---

## 7. Backend (Cloud Functions)

Source: `firebase_functions/functions/src/index.ts`.

| Export | Trigger | Behavior |
|--------|---------|----------|
| `SignUp` | `auth.user().onCreate` | Creates default group (`name: "Default Group"`), `users/{uid}` with `last_group` + `group_ref_array`, and empty `items/{groupId}` parent |
| `CreateGroup` | HTTPS callable | Auth required; creates group; appends ref to user’s `group_ref_array`; returns `{ text, id }` or `{ error }` |
| `JoinGroup` | HTTPS callable | Auth required; expects `data.Id` = group id; appends group to user; appends uid to `groups.members` when new |

Emulators (from `firebase_functions/firebase.json`): Auth `:9099`, Functions `:5001`, Firestore `:8081`, UI enabled.

**Security rules:** Config references `firestore.rules` / `firestore.indexes.json`, but those files are not present in the repository. Deployed rules (if any) live only in the Firebase project.

---

## 8. Key data flows

### 8.1 Auth and first-time provisioning

```
Login.createAccount / signIn
        ▼
Firebase Auth
        │  (new user)
        ▼
SignUp Cloud Function
  → groups/{id}  (owner, "Default Group")
  → users/{uid}  (last_group, group_ref_array)
  → items/{id}   (empty parent)
        ▼
Root → getLastGroup → Home
```

### 8.2 Shared list (realtime)

```
Home
  ├─ streamItems(groupId) ──snapshots──► ListView / GroceryItemCard
  ├─ addItem / updateItem / deleteItem ──► items/{g}/items/{id}
  │         ▲                                    │
  │         └──────── realtime listeners ────────┘
  └─ setState: selection, tags, filterChecked, header visibility
```

### 8.3 Group lifecycle

```
Signup     → SignUp CF
Create     → Home drawer → CreateGroup CF → append group_ref_array
Share      → GroupQRCodeDialog → QR JSON { "Id", "Action" }
Join       → QRCodeScanner → JoinGroup CF → user groups + group.members
Switch     → drawer → setLastGroup + local _group
Rename     → owner only → Database.updateGroupName
```

**QR join payload** (encoded by `GroupQRCodeDialog`):

```json
{ "Id": "<groupId>", "Action": "Join group <name>" }
```

---

## 9. Auth, sharing, and ownership

1. **Login:** Email + password via Firebase Auth. The login field is labeled “Username” but the value is treated as email.
2. **Join:** Any authenticated user who can scan (or otherwise obtain) the group id can call `JoinGroup`. The QR code is effectively a shared secret (group document id).
3. **Ownership:** `_isOwner = group.owner == currentUser.uid`. Rename is disabled for non-owners in the UI; `Database.updateGroupName` also no-ops if the caller is not the owner.
4. **Gaps:** No invite tokens or expiry; no in-repo Firestore security rules to verify; join authorization is not stronger than knowledge of the group id.

---

## 10. Platforms

| Platform | Scaffold | FlutterFire options |
|----------|----------|---------------------|
| Web | `web/` (PWA manifest, Firebase JS / jsQR in `index.html`) | Configured in `lib/firebase_options.dart` |
| Android | Full `android/` tree | Not configured — `DefaultFirebaseOptions.currentPlatform` throws |
| iOS | Full `ios/` tree | Not configured — same as Android |

Today the checked-in FlutterFire config supports **web only**. Native project folders exist as Flutter runners, but Firebase init will fail on Android/iOS until options are regenerated (e.g. via FlutterFire CLI).

---

## 11. Design patterns and conventions

- **Auth gate / composition root:** `Root` chooses Login vs Home from `authStateChanges`.
- **Service layer:** Thin Firebase wrappers with constructor injection.
- **Document factories:** Models map from `DocumentSnapshot`.
- **Callable Functions** for multi-document privileged writes; client writes for item CRUD.
- **Realtime sync** via Firestore snapshot listeners for the active group’s items.
- **Imperative navigation** and dialogs instead of a declarative router.

**State management:** Local `setState` + Firebase builders. `SortDirection` exists and is passed into `streamItems`, but Home keeps ascending sort with no UI to change it. `streamGroups` is a one-shot Future, so the drawer does not live-update after create/join without a rebuild.

---

## 12. Known limitations and roadmap hints

From code and `TODO.md`:

- More item fields, autocomplete, tag search, sort by fields other than name
- Separate registration UI from login
- UI polish (animations, colors, app icon)
- Automated tests for items, groups, sorting (current `test/widget_test.dart` still targets a counter `MyApp`)
- Firestore rules and indexes should be versioned in-repo
- Native (Android/iOS) Firebase options and camera permissions for QR scanning
- Client checks `result.data.err` for some callable responses while the server returns `error` / `text` — response-shape mismatch risk

---

## 13. Quick reference

| Concern | Location |
|---------|----------|
| Entry / auth gate | `lib/main.dart` |
| Login UI | `lib/screens/login.dart` |
| Main checklist UI | `lib/screens/home.dart` |
| QR scan | `lib/screens/qr_scanner.dart` |
| Auth service | `lib/services/auth.dart` |
| Firestore service | `lib/services/db.dart` |
| Models | `lib/models/group.dart`, `lib/models/grocery_item.dart` |
| Cloud Functions | `firebase_functions/functions/src/index.ts` |
| Firebase options | `lib/firebase_options.dart` |
