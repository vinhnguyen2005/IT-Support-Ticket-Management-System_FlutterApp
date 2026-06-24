# IT Support Ticket Management System - Flutter App

Flutter Android application for an IT support ticket management system.

## Team Git Workflow

This project uses a pull request workflow. The `master` branch is the protected/shared branch. Do not code directly on `master`.

## First-Time Setup

Clone the repository:

```bash
git clone https://github.com/vinhnguyen2005/IT-Support-Ticket-Management-System_FlutterApp.git
cd IT-Support-Ticket-Management-System_FlutterApp
```

Install Flutter dependencies:

```bash
flutter pub get
```

Check your current branch:

```bash
git branch
```

You should start from:

```text
master
```

## Daily Workflow

Before writing code every day, update your local `master`:

```bash
git checkout master
git pull origin master
```

Then create a new branch from the latest `master`:

```bash
git checkout -b feature/ticket-list
```

Do your work on that branch, not on `master`.

## Branch Naming

Use clear branch names:

```text
feature/auth-login
feature/ticket-create
feature/admin-dashboard
feature/feedback-form
fix/ticket-status-update
refactor/sqlite-datasource
docs/git-workflow
```

Recommended format:

```text
type/short-task-name
```

Common types:

```text
feature  new function
fix      bug fix
refactor code cleanup without behavior change
docs     documentation only
test     tests only
```

## Commit Rules

Commit small, meaningful changes.

Good commit messages:

```text
Add ticket creation local datasource
Implement login view model
Fix ticket status update query
Create admin dashboard scaffold
```

Avoid vague messages:

```text
update
fix
done
code
final
```

Basic commit flow:

```bash
git status
git add .
git commit -m "Add ticket creation local datasource"
```

## Keep Your Branch Updated

Before pushing or opening a pull request, update your branch with latest `master`:

```bash
git checkout master
git pull origin master
git checkout feature/your-branch-name
git merge master
```

If there are conflicts, resolve them in VS Code or Android Studio, then:

```bash
git status
git add .
git commit
```

After that, run the app again.

## Push Your Branch

Push your branch to GitHub:

```bash
git push -u origin feature/your-branch-name
```

After the first push, later pushes can use:

```bash
git push
```

## Pull Request Rules

Open a pull request from your branch into `master`.

PR title should be clear:

```text
Add ticket creation flow
Implement staff assignment screen
Create feedback SQLite datasource
```

PR description should include:

```text
What changed?
How did you test it?
Any known issues?
Screenshots if UI changed.
```

Example:

```text
What changed:
- Added Ticket entity and DTO
- Implemented local SQLite insert/read
- Built CreateTicketPage UI

Tested:
- Ran flutter pub get
- Ran app on Android emulator
- Created one ticket and checked SQLite table

Known issues:
- UI styling is basic and needs polish later
```

## Review Rules

At least one teammate should review before merging.

Reviewers should check:

```text
Does the app still run?
Is the code in the correct MVVM layer?
Is SQLite only used in datasource files?
Are file names and class names clear?
Is there duplicate logic?
Does the PR only include related changes?
```

## Merge Rules

Only merge when:

```text
PR is reviewed
No unresolved conflicts
App runs locally
Code is pushed to the correct branch
PR targets master
```

After your PR is merged, update your local repo:

```bash
git checkout master
git pull origin master
```

Then create a new branch for the next task.

## Important Safety Rules

Never force push to `master`:

```bash
git push --force origin master
```

Never reset shared work unless the team agrees:

```bash
git reset --hard
```

Never commit generated build folders:

```text
build/
.dart_tool/
.idea/
android/app/debug/
android/app/profile/
android/app/release/
```

These are already ignored by `.gitignore`.

## If You Accidentally Code On Master

Do not panic. Create a branch from your current work:

```bash
git checkout -b feature/my-work
```

Then push that branch:

```bash
git push -u origin feature/my-work
```

Open a PR from that branch.

## If Git Says You Have Local Changes

Check what changed:

```bash
git status
```

If the changes are yours, commit them.

If you are not ready to commit, save them temporarily:

```bash
git stash
git checkout master
git pull origin master
git checkout your-branch-name
git stash pop
```

## Recommended Team Habit

Every morning:

```bash
git checkout master
git pull origin master
```

Before coding:

```bash
git checkout -b feature/your-task
```

Before opening PR:

```bash
git checkout master
git pull origin master
git checkout feature/your-task
git merge master
flutter pub get
flutter run
```

Then push and create the PR.
