---
trigger: always_on
---

# Flutter & Firebase Stability Rules

## 1. Error Handling (Crucial)
- NEVER perform a Firebase operation (Firestore, Auth, Storage) without a `try-catch` block.
- ALWAYS catch `FirebaseException` specifically to handle service-related errors.
- Use `.timeout(Duration(seconds: 10))` on all network calls to avoid hanging the app.

## 2. Data Validation (Preventing 500 Errors)
- Before calling `.update()` or `.add()`, verify that no values are `null`, `NaN`, or `Infinity`.
- If a value is missing, provide a default value (e.g., `data ?? 0.0`) instead of letting the server reject it.

## 3. Firestore Performance
- Use `WriteBatch` if updating more than two documents at once.
- NEVER write to the same document more than once per second (avoid "Hotspotting").

## 4. Connection Management
- Use the `connectivity_plus` check before attempting any Firebase write.
- Ensure `persistenceEnabled: true` is set in Firestore settings to handle spotty internet gracefully.

## 5. Security Rules Sync
- If you create a new collection, remind me to check the `firestore.rules` file to ensure the 'write' permissions are allowed for the current user.