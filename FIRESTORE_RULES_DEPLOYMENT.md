# Firestore Rules Deployment Guide

## Option 1: Deploy via Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy the contents of `firestore.rules` file
5. Paste into the rules editor
6. Click **Publish**

## Option 2: Deploy via Firebase CLI

1. Install Firebase CLI (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase in your project (if not already done):
   ```bash
   firebase init firestore
   ```
   - Select your Firebase project
   - Accept the default firestore.rules file

4. Deploy the rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

## Rules Summary

The firestore.rules file includes:
- **Users Collection**: 
  - Read: All authenticated users
  - Write: Only own document
  - Notifications subcollection: Any authenticated user can create, only owner can read/update/delete
  
- **Hospitals Collection**:
  - Read: All authenticated users
  - Write: All authenticated users

## Testing

After deployment, test the notification feature:
1. Search for blood donors/banks
2. Click the "Notify" button
3. Notifications will be stored in: `/users/{userId}/notifications/`
