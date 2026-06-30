# IT Support Ticket Management System

A Flutter Android application for managing internal IT support tickets. The app is designed for a small organization where users can report technical issues, support staff can handle assigned tickets, and administrators can manage accounts and review system information.

## Project Overview

This project follows a feature-based MVVM structure with SQLite as the local database. Each feature is separated into presentation, application, domain, and data layers so that the team can work on different modules with fewer conflicts.

Main goals:

- Allow employees to create and track IT support tickets.
- Allow support staff to view assigned tickets and update progress.
- Allow administrators to manage user accounts.
- Store app data locally using SQLite during development.
- Keep the codebase organized for team collaboration.

## Tech Stack

- Flutter
- Dart
- SQLite with `sqflite`
- MVVM architecture
- Repository and data source pattern

## Main Features

### Authentication

- Sign in with username and password.
- Passwords are stored as hashes.
- Disabled accounts cannot sign in.
- New users can be required to change their temporary password on first login.
- Tracks the latest successful login time.

### User Management

- Admin can create user accounts.
- Admin can update user profile information and role.
- Admin can disable or reactivate accounts.
- Admin can reset a user's temporary password.

### Ticket Management

- Users can create support tickets.
- Tickets include title, description, issue type, priority, status, and ownership fields.
- The database is prepared for departments, categories, priorities, assignments, comments, attachments, status history, and feedback.

### Assignment

- Support staff can view tickets assigned to them.
- Staff can add progress updates.
- Staff can update ticket status.
- Assignment data tracks the ticket, assigned staff, assigner, assignment time, and active state.

### Reports and Feedback

- The project structure includes report and feedback modules.
- These modules are prepared for future dashboard, performance, and user satisfaction features.

## User Roles

The current role model uses the `users.role` field:

- `admin`: manages accounts and administrative screens.
- `staff`: handles assigned tickets and updates progress.
- `user`: creates tickets and follows ticket status.

## Local Database

The app uses SQLite through `sqflite`. The database file is named:

```text
it_support.db
```

Main tables:

- `users`
- `departments`
- `categories`
- `priorities`
- `tickets`
- `ticket_assignments`
- `progress_updates`
- `ticket_comments`
- `ticket_attachments`
- `ticket_status_histories`
- `feedback`

Seed accounts for development:

```text
Admin
Username: admin
Password: Admin@123

Staff
Username: staff
Password: Staff@123
```

Both seeded accounts may require a password change on first login.

## Project Structure

```text
lib/
├── app/
├── core/
│   ├── database/
│   ├── di/
│   ├── errors/
│   └── security/
└── features/
    ├── auth/
    ├── user_management/
    ├── tickets/
    ├── assignment/
    ├── feedback/
    └── reports/
```

Each feature follows this structure:

```text
feature_name/
├── application/
├── data/
├── domain/
└── presentation/
```

## Run The App

Install dependencies:

```bash
flutter pub get
```

Run on Android emulator or device:

```bash
flutter run
```

If the local SQLite schema changes during development and the emulator already has an old database, uninstall the app once and run again:

```bash
adb uninstall com.example.it_ticket_support_management
flutter run
```

If `adb` is not available in the terminal, uninstall the app manually from the emulator/device.

## Useful Checks

Format code:

```bash
dart format lib
```

Analyze code:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

## Notes For The Team

- Keep SQLite queries inside data source classes.
- Keep business validation inside service classes.
- Keep UI state inside view models.
- Do not put feature-specific logic directly into shared core files.
- Create new screens inside the related feature folder.
- Use pull requests for merging work into `master`.
