# Assignment: Flutter Chat System

## Project Overview

This is a chat application built with Flutter for an internship assignment. The application allows users to authenticate, find other users, and engage in real-time one-on-one conversations.

**Features:**
- User Authentication (Email & Password)
- Real-time one-to-one chat
- Message reactions
- User profile avatar customization

## How to Run

1.  **Clone the repository:**
    ```bash
    git clone <your-repository-url>
    cd <your-project-directory>
    ```

2.  **Set up Firebase:**
    Follow the Firebase setup instructions below.

3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

4.  **Run the application:**
    ```bash
    flutter run
    ```

## Firebase Setup

This project uses Firebase for its backend services.

1.  Create a new project on the [Firebase Console](https://console.firebase.google.com/).
2.  Add a Flutter app to your Firebase project and follow the on-screen instructions to configure it for Android, iOS, and Web. You will need to add the generated configuration file (`google-services.json` for Android, `GoogleService-Info.plist` for iOS) to your project.
3.  Enable the following services in the Firebase console:
    - **Authentication**: Enable the `Email/Password` sign-in provider.
    - **Cloud Firestore**: Create a new database in test mode or with the rules provided below.
    - **Firebase Storage**: Enable to support user avatar uploads.

## Firestore Rules (summary)

Security rules for Cloud Firestore are in the repo at `firestore_rules.txt`. These rules are stricter and more detailed than the simple example in the README — designed to restrict access by role and membership.

### General structure
- rules_version = '2' and `service cloud.firestore`.
- All rules live under `match /databases/{database}/documents`.
- Multiple helper functions are used to keep rules clean and reusable.

### Key helper functions
- `isSignedIn()`: checks `request.auth != null`.
- `userRole(uid)`: reads `/users/{uid}` to obtain the `role` field.
- `authIsTutor()`: checks whether the authenticated user has role `tutor`.

### users collection (/users/{userId})
- allow get: any signed-in user can read profiles.
- allow list: only tutors can list users.
- allow create: users may only create their own profile; input is strictly validated (only allowed fields).
- allow update: users may only update their own profile; some fields (email, role, createdAt) are treated as immutable.
- allow delete: not allowed.

### rooms collection (/rooms/{roomId})
- Read (get/list) access only for members, checked via `memberUids`.
- Create only for tutors; room data is validated (creator must be a member, minimum 2 members, validate `type: "trio"` if required, etc.).
- Update only for members; critical fields such as `memberUids` and `members` cannot be changed.
- Delete: not allowed.

### Sub-collection messages (/rooms/{roomId}/messages/{messageId})
- Membership checks for sub-collections explicitly read the parent document using `get()`.
- allow get/list: only room members may read messages.
- allow create: only members may send messages, and `author` must match `request.auth.uid`.
- allow update: only members may update messages (can be tightened to author-only edits).
- allow delete: not allowed.

### Important notes
- Using `get()` to read a parent document counts as a read operation.
- Rules follow least-privilege principles and strict input validation — suitable for more secure development but should be reviewed before production.

Reference: see the full rules at `firestore_rules.txt`.

## Test Accounts

You can use the following dummy accounts for testing purposes after creating them through the app's sign-up screen.

-   **Role**: `student`
-   **Email**: `student@example.com`
-   **Password**: `password123`

-   **Role**: `parent`
-   **Email**: `parent@example.com`
-   **Password**: `password123`

-   **Role**: `tutor`
-   **Email**: `tutor@example.com`
-   **Password**: `password123`

## Known Limitations

-   No group chat functionality.
-   Basic offline support; messages may not sync correctly if sent while offline for an extended period.
