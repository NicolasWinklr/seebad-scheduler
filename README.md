# SeebadScheduler

A Flutter Web application for scheduling staff at Strandbad Bregenz swimming pool. Built with Firebase, Riverpod, and go_router.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 🌊 Features

### Scheduling
- **2-Week Planning Grid**: Visual drag-and-drop schedule with 9 shift templates
- **Constraint-Based Solver**: Automatic assignment with hard/soft constraints
- **Violation Detection**: Real-time conflict highlighting (German UI)
- **Period Lifecycle**: DRAFT → OPTIMIZED → REVIEW → PUBLISHED → ARCHIVED

### Shift Templates
| Code | Label | Bereich | Zeiten |
|------|-------|---------|--------|
| S-Früh | Sauna Früh | Sauna | 06:00–14:00 |
| S-Spät | Sauna Spät | Sauna | 14:00–22:00 |
| Mili | Mili | Mili | 09:00–19:00 |
| B-Früh | Hallenbad Früh | Hallenbad/Strandbad | 06:00–14:00 |
| B-Mitte | Hallenbad Mitte | Hallenbad/Strandbad | 10:00–18:00 |
| B-Spät | Hallenbad Spät | Hallenbad/Strandbad | 14:00–22:00 |
| SB-Mitte | Strandbad Mitte | Strandbad | 10:00–18:00 |
| VM-SB | Strandbad Vormittags | Strandbad | 06:00–14:00 |
| NM-SB | Strandbad Nachmittags | Strandbad | 14:00–20:00 |

### Employee Management
- Contract types: Fixangestellt, Teilzeit, Ferialer
- Work patterns: Unbeschränkt, nur Wochenende, nur unter der Woche
- Time restrictions: nur vormittags, nur nachmittags
- Absences: Vacation ranges, short unavailability

### Exports
- **PDF**: Printable 2-week schedule with legend
- **Excel**: 3 sheets (Dienstplan, Legende, Zusammenfassung)

## 🚀 Setup

### Prerequisites
- Flutter SDK 3.0+
- Node.js (for Firebase CLI)
- Firebase account

### 1. Clone and Install Dependencies
```bash
cd seebad_scheduler
flutter pub get
```

### 2. Configure Firebase

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or use existing
3. Add a **Web app**
4. Enable **Authentication** → Email/Password
5. Enable **Cloud Firestore**

Update `lib/firebase_options.dart` with your config:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

### 3. Set Up Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users can read/write
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 4. Seed Initial Data (Optional)

After configuring Firebase, you can seed test data:

```dart
// In your app, call:
await SeedDataService().seedAll();
```

## 💻 Development

### Run Locally
```bash
flutter run -d chrome
```

### Build for Production
```bash
flutter build web --release
```

### Analyze Code
```bash
flutter analyze
```

### Run Tests
```bash
flutter test
```

## 📁 Project Structure

```
lib/
├── main.dart               # App entry point
├── firebase_options.dart   # Firebase configuration
├── models/                 # Data models
│   ├── employee.dart
│   ├── shift_template.dart
│   ├── period.dart
│   ├── assignment.dart
│   ├── demand.dart
│   └── solver_config.dart
├── services/               # Business logic & Firebase
│   ├── auth_service.dart
│   ├── employee_repository.dart
│   ├── shift_template_repository.dart
│   ├── period_repository.dart
│   ├── settings_repository.dart
│   ├── solver_service.dart
│   ├── demand_resolver.dart
│   ├── pdf_export_service.dart
│   └── excel_export_service.dart
├── providers/              # Riverpod providers
│   ├── providers.dart
│   └── solver_provider.dart
├── screens/                # UI screens
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── dienstplan_screen.dart
│   ├── mitarbeiter_screen.dart
│   ├── schicht_einstellungen_screen.dart
│   ├── regeln_screen.dart
│   └── konflikte_screen.dart
├── widgets/                # Reusable widgets
│   └── app_shell.dart
└── utils/                  # Utilities
    ├── theme.dart
    └── router.dart
```

## 🔧 Solver Constraints

### Hard Constraints (Always Enforced)
- Area permissions (employee must have area access)
- Contract work pattern (weekend/weekday restrictions)
- Vacation and unavailability
- Time restrictions (morning/afternoon only)
- Late-to-early prevention (no PM → AM next day)
- Max shifts per day per employee

### Soft Constraints (Optimized)
- Coverage targets (min/ideal staffing)
- Hours deviation (balance across employees)
- Block planning (consecutive work days)
- Sunday fairness (distribute Sunday shifts)
- Soft preferences (kein Wochenende, etc.)

## 🎨 Theme

The app uses the **Seebad Bregenz** brand colors:
- Primary: `#005DA9` (deep aquatic blue)
- Typography: Outfit (Google Fonts)
- Style: Premium coastal/lakeside aesthetic

## 📝 License

MIT License - See LICENSE file for details.

---

Made with 💙 for Strandbad Bregenz
