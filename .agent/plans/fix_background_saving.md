# Implementation Plan - Fix Background Task Saving & Module Assignment

The objective is to fix the issue where AI-generated cards are being saved to the wrong module or not appearing in the user's feed after task completion.

## User Issues
1. Cards generated for "Reado Official Guide" (ID: `B`) appear in "STAR Interview" (ID: `A`).
2. New users don't see their custom modules updated correctly.
3. Cards only exist in `extraction_jobs` but not in the user's `custom_items`.

## Root Cause Analysis
- **Database Mismatch**: The Cloud Function was defaulting to the `(default)` Firestore database, while the application uses a named database `reado`.
- **Database Reference Locking**: Using `admin.firestore().settings({ databaseId: 'reado' })` is not the recommended way for Admin SDK v11+.
- **Missing User Document**: For new users, the `users/{uid}` document might not exist, causing batch writes to the subcollection to fail if the path is invalid or during specific query scenarios (though subcollections usually work regardless, it's safer to ensure the user doc exists).

## Tasks
- [x] Modify Cloud Function to use `getFirestore(admin.app(), 'reado')`.
- [x] Force `moduleId` on every generated card during the save process.
- [x] Ensure `users/{uid}` document exists before saving `custom_items`.
- [x] Add detailed logging to track `userId` and `moduleId` in production.
- [x] Successfully deploy the updated Cloud Function.
- [x] Fix Snackbar navigation bug in `AddMaterialModal`.
- [x] Improve Batch Import: Automatic background extraction when adding items.
- [x] Better JSON parsing and retry logic in Cloud Function.
- [ ] Verify fix by generating new content in a specific module.

## Status
- **Recent Deployment Status**: Failed with "Operation already in progress" or generic error. Retrying now.
