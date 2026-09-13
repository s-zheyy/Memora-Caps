# Memora Caps — Flutter + Firebase

A full implementation of the 9 modules from the "Memora Caps" UI mockups
(Siador, Fritzie C. — BSIT 3B), built with Flutter and Firebase
(Authentication + Cloud Firestore). Every screen is wired to live data —
no mock/static UI.

## Modules implemented (all functional)

| Module | Screen file | What it does |
|---|---|---|
| Splash Screen | `lib/screens/splash_screen.dart` | Shows logo, then auto-routes to Login or the Dashboard based on Firebase Auth state |
| Login | `lib/screens/login_screen.dart` | Firebase Auth email/password sign-in + "Forgot Password" reset email |
| Registration | `lib/screens/register_screen.dart` | Creates a Firebase Auth account **and** a Firestore `users/{uid}` profile document |
| Dashboard | `lib/screens/dashboard_screen.dart` | Live stats (total/locked/opened/streak), AI-style insight banner, recent capsules |
| Capsules List | `lib/screens/capsules_list_screen.dart` | Search + All/Locked/Opened filters, live Firestore stream, edit/delete per capsule |
| Create/Edit Capsule | `lib/screens/create_edit_capsule_screen.dart` | One screen handles both **Create** and **Update** (Firestore CRUD) |
| Capsule Details | `lib/screens/capsule_details_screen.dart` | Full capsule view, locked/opened state, AI growth analysis, edit/delete |
| Add Reflection | `lib/screens/add_reflection_screen.dart` | Updates `currentReflection` / `lessonsLearned` fields on the capsule doc |
| Growth Dashboard | `lib/screens/growth_dashboard_screen.dart` | Real bar chart (fl_chart) of monthly reflection activity, computed streak |
| Profile | `lib/screens/profile_screen.dart` | Shows/edits course & year level, Logout (Firebase `signOut`) |

## Architecture

```
lib/
  main.dart                 # Firebase.initializeApp() + MaterialApp
  firebase_options.dart     # PLACEHOLDER — replaced by `flutterfire configure`
  theme.dart                 # Colors/typography matching the mockups
  models/
    capsule.dart             # Capsule data model + Firestore (de)serialization
    user_profile.dart        # User profile data model
  services/
    auth_service.dart        # FirebaseAuth wrapper (login/register/logout/reset)
    capsule_service.dart     # Firestore CRUD for capsules (Create/Read/Update/Delete)
    insight_service.dart     # Generates the "AI Insight" text from real data (no API key needed)
  screens/                   # One file per module (see table above)
  widgets/
    main_shell.dart          # Bottom navigation bar hosting Home/Capsules/Growth/Profile
```

### Firestore data model

```
users (collection)
  {uid} (document)                 <- fullName, studentId, course, yearLevel, email, photoUrl
    capsules (subcollection)
      {capsuleId} (document)       <- title, category, goal, originalReflection, mood,
                                       createdAt, unlockDate, currentReflection,
                                       lessonsLearned, reflectionUpdatedAt
```

Storing capsules as a **subcollection of the user** means the security
rules (see `firestore.rules`) can restrict every read/write to
`request.auth.uid == userId` with no extra query filtering — a user can
never see another user's capsules.

### CRUD mapping

- **Create** → `CapsuleService.createCapsule()` — used by the "New Capsule" screen and the `+` FAB on Dashboard/Capsules List.
- **Read** → `CapsuleService.watchCapsules()` / `watchCapsule(id)` — live `Stream`s power every list and detail screen (no manual refresh needed; edits/deletes reflect instantly).
- **Update** → `CapsuleService.updateCapsule()` (full edit) and `addReflection()` (partial update just for the reflection fields).
- **Delete** → `CapsuleService.deleteCapsule()` — available from the list's `⋮` menu and the Capsule Details app bar, with a confirmation dialog.

The "locked / opened" state isn't a stored boolean — it's computed live
by comparing `unlockDate` to `DateTime.now()` (`Capsule.isLocked` getter),
so a capsule automatically flips to "Opened" the moment its date passes.

## Setup instructions (Android Studio / VS Code)

### 1. Install prerequisites
- Flutter SDK (stable channel) — `flutter doctor` should show no blockers.
- A Firebase project at https://console.firebase.google.com.
- Node.js (for the Firebase CLI) and the FlutterFire CLI:
  ```bash
  npm install -g firebase-tools
  dart pub global activate flutterfire_cli
  ```

### 2. Get the project running
```bash
cd memora_caps
flutter pub get
```

### 3. Connect Firebase
```bash
firebase login
flutterfire configure
```
Pick (or create) your Firebase project and select the platforms you need
(Android/iOS/Web). This **overwrites `lib/firebase_options.dart`** with
your real project keys — that's expected, the file in this repo is a
placeholder.

### 4. Enable Firebase services
In the Firebase console:
1. **Authentication** → Sign-in method → enable **Email/Password**.
2. **Firestore Database** → Create database (production mode is fine).
3. Go to **Firestore → Rules** and paste the contents of `firestore.rules`
   from this project, then **Publish**. This locks each user to only
   their own data.

### 5. Run the app
Open the folder in Android Studio (or VS Code) with the Flutter plugin
installed, select a device/emulator, and run `lib/main.dart` — or from
the terminal:
```bash
flutter run
```

### 6. Test the full flow
1. Register a new account (Registration module) → writes `users/{uid}`.
2. You're taken straight to the Dashboard.
3. Tap the **+** button → create a capsule with a future unlock date →
   see it appear instantly in Capsules List and Dashboard, marked **Locked**.
4. Create another capsule with **today's date or earlier** as the unlock
   date → it shows as **Opened** immediately.
5. Open an **Opened** capsule → tap **Add Reflection** → save → see the
   "Latest Reflection" card and updated AI Growth Analysis on the
   Details screen.
6. Check the **Growth** tab — the bar chart and streak update based on
   your real capsule data.
7. Edit or delete a capsule from the list's `⋮` menu, or from the
   Details screen's app bar icons — changes sync everywhere instantly.
8. Edit your course/year on **Profile**, then **Logout** — you're
   returned to Login, and signing back in restores everything from
   Firestore.

## Notes on the "AI" insight text

The mockups show an "AI Academic Insight" / "AI Growth Analysis" /
"AI Growth Summary" banner. To keep this project runnable without any
paid API key, `insight_service.dart` generates that text **locally**
from the user's real Firestore data (streaks, unlock dates, categories,
reflections). If you want to swap this for a real LLM call (e.g. the
Anthropic API), replace the method bodies in `insight_service.dart` with
an HTTP call to your model of choice — the rest of the app (UI, state,
CRUD) doesn't need to change.

## Extending further

- **Profile photo upload**: add `firebase_storage` and an `image_picker`
  flow that writes the download URL into `users/{uid}.photoUrl`.
- **Push reminders** when a capsule unlocks: add `firebase_messaging` +
  a scheduled Cloud Function that checks `unlockDate`.
- **Offline support**: Firestore's local cache is enabled by default in
  this setup, so the app already works offline for reads and queues
  writes until reconnected.
