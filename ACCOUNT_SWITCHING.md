# Account Switching Feature

## Overview
The QMail app now supports switching between different Gmail accounts without needing to fully reinstall or clear app data.

## How It Works

### For Users:
1. **Switching Accounts**:
   - Open the app drawer (hamburger menu)
   - Tap "Switch Account"
   - Confirm the action in the dialog
   - Select a different Google account from the picker

2. **What Happens**:
   - Current session is signed out
   - All cached email data is cleared
   - Google account picker is shown
   - After selecting account, emails are fetched fresh

### For Developers:

#### Key Components:
1. **AuthProvider.switchAccount()**: Handles the account switching flow
2. **EmailProvider.clearAllData()**: Clears all cached emails and state
3. **CacheService.clearAllCache()**: Removes cached data from local storage

#### Flow:
```dart
// 1. User taps "Switch Account"
// 2. Confirmation dialog appears
// 3. If confirmed:
//    - Clear all email data
//    - Sign out current user
//    - Force Google account picker
//    - Sign in with new account
//    - Fetch fresh emails
```

#### Technical Implementation:
- Uses `GoogleSignIn.signOut()` before new sign-in
- Forces account picker with `forceAccountPicker: true`
- Clears Hive cache and provider state
- Handles async state properly with mounted checks

## Benefits:
- ✅ No app restart required
- ✅ Clean account separation
- ✅ Proper data isolation
- ✅ User-friendly interface
- ✅ Error handling and feedback

## Error Handling:
- Network failures show appropriate messages
- User cancellation is handled gracefully
- Invalid account states are recovered
- UI remains responsive during switching