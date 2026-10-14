# AI Study Planner — Mobile Application
**COMP826 Mobile Systems Development | Assignment 2 (A2) Project Documentation**

---

## 1. Executive Summary & Project Overview

The **AI Study Planner** is a cross-platform mobile application developed with **Flutter (Dart)** engineered specifically for tertiary students. While standard to-do applications (e.g., Todoist, Apple Reminders) merely record passive deadlines, and general calendar utilities lack academic context, this system synthesizes **weekly lecture/lab commitments**, **graded assignment and exam deadlines**, and **individual study capacity** into an actionable, conflict-free study schedule powered by **Google Gemini Generative AI**.

### Core Value Propositions
* **Proactive Workload Distribution**: Alleviates cramming and academic procrastination by decomposing high-workload assessments into achievable daily study sessions.
* **Offline-First Architecture**: Core timetable records and academic tasks are persistently stored in a local **SQLite** database, guaranteeing full CRUD availability during network dropouts, with automatic background synchronization to **Cloud Firestore**.
* **Zero-PII Privacy Protection**: Adheres to strict data-minimization principles — no student name, student ID, or email address is ever transmitted to the external AI API.
* **3-Tap Usability Guarantee**: Allows students to log an assessment or exam in 3 taps or fewer using streamlined inputs and intelligent quick presets.
* **Automated Notification Alarms**: Schedules precise device-level alarms for upcoming study sessions and sends proactive warnings **24 hours prior** to assessment deadlines.
* **Mobile-First Experience**: Features a persistent Material 3 **Bottom Navigation Bar** connecting all primary views, complete with an adaptive mobile viewport frame for demonstration on desktop and web environments.

---

## 2. System Architecture & Layered Design

The system implements a strict **Layered Architecture (MVVM Pattern)** to enforce decoupling between the user interface, business logic, persistence layer, and external cloud services:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                             │
│  - Mobile Viewport Frame        - Bottom Navigation Bar (5 Tabs)         │
│  - Splash Screen                - Authentication & Registration Screen   │
│  - Home Dashboard Screen        - Weekly Timetable Screen (CRUD)         │
│  - Tasks & Exams Screen         - Quick-Add Task Sheet (3-Tap Flow)      │
│  - AI Study Plan Screen         - Settings & Preferences Screen          │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │ (Provider / ChangeNotifier Listeners)
┌────────────────────────────────────▼─────────────────────────────────────┐
│                        APPLICATION / LOGIC LAYER                         │
│  - AuthController               - TimetableController                    │
│  - TaskController               - StudyPlanController                    │
│  - SettingsController                                                    │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │ (Repository Abstractions)
┌────────────────────────────────────▼─────────────────────────────────────┐
│                                DATA LAYER                                │
│  - AuthRepository               - TimetableRepository                    │
│  - TaskRepository               - StudyPlanRepository                    │
│  - SQLiteHelper (Local DB)      - FirestoreSyncService (Cloud Sync)      │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │ (Network & Device APIs)
┌────────────────────────────────────▼─────────────────────────────────────┐
│                         EXTERNAL SERVICES LAYER                          │
│  - Google Gemini 1.5 Flash API  - Firebase Authentication / Firestore    │
│  - Flutter Local Notifications  - Device Timezone Engine (tz_datetime)   │
└──────────────────────────────────────────────────────────────────────────┘
```

### Architectural Separation Rules
1. **Zero Direct Network / DB Calls in UI**: Presentation widgets never communicate directly with SQLite, Firestore, or HTTP endpoints. All state transformations flow through Logic Controllers.
2. **Offline-First Repositories**: Writes are committed to the local SQLite database first before initiating asynchronous cloud syncing.
3. **Graceful Service Degradation**: If network connectivity drops or no external Gemini API key is configured, an onboard heuristic scheduling engine generates valid study allocations without throwing exceptions.

---

## 3. Database Entities & Data Models

| Entity | Primary Attributes | Description |
| :--- | :--- | :--- |
| **`User`** | `userId`, `email`, `preferences` (Map), `availableStudyHours` (int) | Authenticated student profile and daily study capacity ceiling. |
| **`TimetableEntry`** | `entryId`, `subject`, `day`, `startTime`, `endTime`, `location` | Static recurring university commitments (lectures, labs, tutorials). |
| **`AcademicTask`** | `taskId`, `subject`, `title`, `type` (`Assignment` \| `Exam`), `dueDate`, `priority` (`High` \| `Medium` \| `Low`), `estWorkload` (hours), `status` (`Pending` \| `Complete`) | Graded assessments tracked with countdown timers. |
| **`StudySession`** | `sessionId`, `taskId`, `date`, `startTime`, `duration` (mins), `status` (`Pending` \| `Complete`), `subject`, `taskTitle` | Conflict-free scheduled study blocks generated by AI. |
| **`StudyPlan`** | `planId`, `createdAt`, `status` (`Active` \| `Archived`), `sessions` (List) | Enclosing planning container for active horizon study sessions. |

### SQLite Relational Schema (`ai_study_planner.db`)
```sql
CREATE TABLE users (
  userId TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  preferences TEXT,
  availableStudyHours INTEGER NOT NULL DEFAULT 4
);

CREATE TABLE timetable_entries (
  entryId TEXT PRIMARY KEY,
  subject TEXT NOT NULL,
  day TEXT NOT NULL,
  startTime TEXT NOT NULL,
  endTime TEXT NOT NULL,
  location TEXT
);

CREATE TABLE academic_tasks (
  taskId TEXT PRIMARY KEY,
  subject TEXT NOT NULL,
  title TEXT NOT NULL,
  type TEXT NOT NULL,
  dueDate TEXT NOT NULL,
  priority TEXT NOT NULL,
  estWorkload INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'Pending'
);

CREATE TABLE study_sessions (
  sessionId TEXT PRIMARY KEY,
  taskId TEXT NOT NULL,
  date TEXT NOT NULL,
  startTime TEXT NOT NULL,
  duration INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'Pending',
  subject TEXT,
  taskTitle TEXT
);

CREATE TABLE study_plans (
  planId TEXT PRIMARY KEY,
  createdAt TEXT NOT NULL,
  status TEXT NOT NULL,
  sessionsJson TEXT
);
```

---

## 4. Usability Engineering & Navigation Flow

### 1. Persistent Bottom Navigation Bar
The application provides a persistent Material 3 bottom navigation bar across all five primary screens:
* 🏠 **Dashboard**: High-level academic progress overview, next upcoming study session, and quick action cards.
* 📅 **Timetable**: Weekly class schedule organized by day chips (Mon–Sun) with full CRUD support.
* 📝 **Tasks**: Filterable list of assignments and examinations with swipe-to-delete and instant status toggling.
* ✨ **AI Plan**: Interactive study plan generator displaying allocated sessions with date filter chips.
* ⚙️ **Settings**: Daily study hours slider (1–10 hrs), notification toggles, Gemini API key manager, and logout.

### 2. The 3-Tap Usability Constraint
To meet Milestone 1 Usability Target **U-01** (*"A user can add an assignment in 3 taps or fewer"*):
1. **Tap 1**: Tap the extended Floating Action Button (`+ New Task`) on the Tasks screen.
2. **Tap 2**: Tap a quick preset chip (e.g., `⚡ COMP826 Lab Report` or select custom title).
3. **Tap 3**: Tap `Save Academic Task`.

---

## 5. AI Integration & Privacy-First Prompt Engineering

### Zero-PII Sanitization
Before dispatching any HTTP request to the Google Gemini endpoint, the client executes `JsonSanitizer.buildSanitizedAiPayload()`. This strips all student identifiers:
```json
{
  "metadata": {
    "planningHorizonDays": 7,
    "availableDailyStudyHours": 4,
    "startDate": "2026-10-11"
  },
  "tasks": [
    {
      "taskId": "task-uuid-01",
      "subject": "COMP826",
      "title": "Assignment 2 - Flutter Mobile App",
      "type": "Assignment",
      "dueDate": "2026-10-15",
      "priority": "High",
      "estWorkloadHours": 8
    }
  ],
  "staticTimetableCommitments": [
    {
      "day": "Monday",
      "startTime": "10:00",
      "endTime": "12:00",
      "subject": "COMP826 Mobile Systems Dev"
    }
  ]
}
```

### Prompt Constraints
1. **No Clash Policy**: AI strictly avoids scheduling study sessions during static timetable commitment hours.
2. **Daily Capacity Ceiling**: Sum of session durations on any single calendar date must not exceed `availableDailyStudyHours`.
3. **Deadlines & Priority First**: High-priority tasks and impending due dates are scheduled earlier in the horizon.
4. **Strict JSON Schema**: AI output is restricted to a structured JSON array without markdown wrapping or conversational commentary.

---

## 6. Notification System

Implemented using `flutter_local_notifications` and the `timezone` database:
* **Study Session Alarms**: Automatically schedules an exact-time device alarm for the start time of every generated study session.
* **24-Hour Assessment Alerts**: Computes `dueDate - 24 hours` for every pending assignment/exam and triggers a high-priority heads-up reminder.
* **Web/Desktop Fallback**: Gracefully detects `kIsWeb` to ensure web demonstration runs smoothly without missing-plugin exceptions.

---

## 7. Directory Structure

```
code/
├── pubspec.yaml                                    # Project manifest & dependencies
├── analysis_options.yaml                           # Dart analyzer & linter rules
├── README.md                                       # Comprehensive technical documentation
├── lib/
│   ├── main.dart                                   # App entry point, MultiProvider & viewport frame
│   ├── core/
│   │   ├── constants/app_constants.dart            # Storage keys, SQLite schema & defaults
│   │   ├── theme/app_theme.dart                    # Material 3 light & dark themes (Inter font)
│   │   └── utils/
│   │       ├── date_time_utils.dart                # Relative countdowns & ISO date formatting
│   │       └── json_sanitizer.dart                 # Zero-PII sanitization logic
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart                     # Student user entity
│   │   │   ├── timetable_entry_model.dart          # Class timetable entity
│   │   │   ├── academic_task_model.dart            # Assignment & exam entity
│   │   │   ├── study_session_model.dart            # Scheduled study block entity
│   │   │   └── study_plan_model.dart               # Complete study plan container
│   │   ├── local/
│   │   │   └── sqlite_helper.dart                  # Offline-first SQLite database CRUD
│   │   ├── remote/
│   │   │   ├── firebase_auth_service.dart          # Firebase Auth with simulated fallback
│   │   │   ├── firestore_sync_service.dart         # Cloud Firestore syncing queue
│   │   │   └── gemini_ai_service.dart              # Gemini REST API + heuristic scheduler
│   │   └── repositories/
│   │       ├── auth_repository.dart                # Authentication data repository
│   │       ├── timetable_repository.dart           # Offline-first timetable repository
│   │       ├── task_repository.dart                # Offline-first task repository
│   │       └── study_plan_repository.dart          # AI study plan repository
│   ├── services/
│   │   └── notification_service.dart               # Device notifications & 24h deadline alerts
│   ├── logic/
│   │   ├── auth_controller.dart                    # Authentication state management
│   │   ├── timetable_controller.dart               # Timetable CRUD state & day filters
│   │   ├── task_controller.dart                    # Task management & filter chips
│   │   ├── study_plan_controller.dart              # AI generation & session status tracking
│   │   └── settings_controller.dart                # User study preferences & API key state
│   └── presentation/
│       ├── screens/
│       │   ├── main_shell_screen.dart              # Persistent Bottom Navigation Bar shell
│       │   ├── splash_screen.dart                  # Auth check & cold-start routing
│       │   ├── auth/login_screen.dart              # Student login & account creation
│       │   ├── dashboard/home_dashboard_screen.dart# Central hub, progress overview & 1-tap nav
│       │   ├── timetable/
│       │   │   ├── timetable_screen.dart           # Weekly calendar view (Mon–Sun)
│       │   │   └── add_timetable_dialog.dart       # Timetable entry create/edit dialog
│       │   ├── tasks/
│       │   │   ├── tasks_screen.dart               # Task list with swipe-to-delete
│       │   │   └── quick_add_task_sheet.dart       # 3-Tap Rapid Task Creation Sheet
│       │   ├── study_plan/study_plan_screen.dart   # Interactive AI schedule generation
│       │   └── settings/settings_screen.dart       # Study hours slider, alert toggles & logout
│       └── widgets/
│           ├── mobile_viewport_wrapper.dart        # Smartphone frame for web/desktop viewing
│           ├── progress_card.dart                  # Progress indicator & task summary chips
│           ├── quick_nav_grid.dart                 # 1-tap navigation grid cards
│           ├── session_card.dart                   # Study session tile with complete toggle
│           └── task_card.dart                      # Academic task card with priority badge
└── test/
    └── widget_test.dart                            # Comprehensive unit & model tests
```

---

## 8. Installation, Execution & Testing Guide

### Prerequisites
* Flutter SDK (Version `>=3.19.0`)
* Dart SDK (Version `>=3.3.0`)
* Google Chrome, Microsoft Edge, or Android Emulator / Physical Device

### 1. Install Dependencies
```bash
cd "code"
flutter pub get
```

### 2. Run Automated Test Suite
Execute the unit tests verifying model serialization, date parsing, and Zero-PII sanitization:
```bash
flutter test
```
*Result: 5/5 tests passing with 0 failures.*

### 3. Run Application in Mobile View (Web/Chrome)
To preview the application inside the mobile device frame:
```bash
flutter run -d chrome --web-port 8085
```
Once loaded, open `http://localhost:8085` in your browser.

### 4. Run on Android Device / Emulator
```bash
flutter run -d android
```

---

## 9. Requirement Traceability Matrix (Milestone 1 MSD Alignment)

| Req ID | Specification (Milestone 1 MSD) | Implementation in Code | Verification Status |
| :--- | :--- | :--- | :--- |
| **REQ-01** | User authentication with individual planning data | `FirebaseAuthService` & `AuthController` | ✅ Verified |
| **REQ-02** | Timetable CRUD with weekly day filters | `TimetableScreen`, `SQLiteHelper` | ✅ Verified |
| **REQ-03** | Assignment & examination tracking with workloads | `TasksScreen`, `AcademicTask` model | ✅ Verified |
| **REQ-04** | AI Study Planning subtracting class clashes | `GeminiAIService`, `StudyPlanController` | ✅ Verified |
| **REQ-05** | Offline-First caching with SQLite | `SQLiteHelper.instance`, `ai_study_planner.db` | ✅ Verified |
| **REQ-06** | Session & 24h assessment deadline notifications | `NotificationService` (`zonedSchedule`) | ✅ Verified |
| **REQ-07** | 3-Tap Usability Guarantee for task creation | `QuickAddTaskSheet` with 1-tap presets | ✅ Verified |
| **REQ-08** | Zero Personally Identifiable Information to AI | `JsonSanitizer.buildSanitizedAiPayload` | ✅ Verified |
| **REQ-09** | Bottom Navigation Bar & Mobile-First Form Factor | `MainShellScreen`, `MobileViewportWrapper` | ✅ Verified |
