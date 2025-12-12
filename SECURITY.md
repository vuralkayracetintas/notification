# Security Guidelines

## 🔒 Sensitive Files (NEVER COMMIT TO GIT)

### ❌ Do NOT commit these files:
1. **`service_account.json`** - Firebase Admin SDK credentials
2. **`google-services.json`** - Android Firebase config
3. **`GoogleService-Info.plist`** - iOS Firebase config
4. **`.env`** - Environment variables
5. **`backend_test/service_account.json`** - Backend Firebase credentials

### ✅ Already Protected (in .gitignore):
- `service_account.json`
- `**/google-services.json`
- `**/GoogleService-Info.plist`
- `get_access_token.js`
- `get_access_token.py`
- `node_modules/`
- `.env`

## 🔑 Firebase Keys in Code

### `lib/firebase_options.dart`
- Contains **public** API keys (safe to commit)
- These are client-side keys and are meant to be public
- Firebase security rules protect your backend

### What's Safe:
- ✅ `apiKey` in `firebase_options.dart` (public)
- ✅ `projectId` (public)
- ✅ `appId` (public)

### What's NOT Safe:
- ❌ Private keys from `service_account.json`
- ❌ OAuth tokens
- ❌ Database passwords

## 🛡️ Setup for New Developers

1. Get `service_account.json` from project admin (via secure channel)
2. Place in project root:
   ```
   notification_example/
   ├── service_account.json  (NOT in git)
   └── backend_test/
       └── service_account.json  (NOT in git)
   ```

3. Never commit these files!

## 📝 Note

The API keys visible in `firebase_options.dart` are **safe to be public**. They identify your Firebase project but don't grant admin access. Actual security is enforced by:
- Firebase Security Rules
- App verification (App Check)
- Backend authentication
