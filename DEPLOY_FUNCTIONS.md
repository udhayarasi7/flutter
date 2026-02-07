# Deploy Cloud Functions for Push Notifications

## Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
```

## Step 2: Login to Firebase
```bash
firebase login
```

## Step 3: Initialize Firebase (if not done)
```bash
firebase init
```
- Select "Functions"
- Choose your Firebase project
- Select JavaScript
- Do NOT overwrite existing files

## Step 4: Install Dependencies
```bash
cd functions
npm install
cd ..
```

## Step 5: Deploy Functions
```bash
firebase deploy --only functions
```

## Verify Deployment
1. Go to Firebase Console → Functions
2. You should see `sendNotification` function listed
3. Test by sending a notification from the app

## Troubleshooting
- If deployment fails, check Firebase billing (Blaze plan required for Cloud Functions)
- Check logs: `firebase functions:log`
