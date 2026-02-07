# Push Notifications Setup Guide

## Step 1: Install Dependencies

Run the following command to install the new package:
```bash
flutter pub get
```

## Step 2: Configure Firebase Cloud Messaging (FCM)

### For Android:

1. **No additional configuration needed** - FCM is automatically configured with Firebase

### For iOS:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Enable Push Notifications capability
3. Add APNs key in Firebase Console:
   - Go to Project Settings → Cloud Messaging
   - Upload your APNs Authentication Key

## Step 3: Deploy Firestore Rules

Deploy the updated `firestore.rules` file:

### Option 1: Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy contents of `firestore.rules`
5. Paste and click **Publish**

### Option 2: Firebase CLI
```bash
firebase deploy --only firestore:rules
```

## Step 4: Set Up Cloud Functions (Required for Push Notifications)

Push notifications require a backend to send FCM messages. Create a Cloud Function:

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Initialize Cloud Functions:
```bash
firebase init functions
```

3. Create `functions/index.js`:
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    const message = {
      token: notification.to,
      notification: {
        title: notification.notification.title,
        body: notification.notification.body,
      },
      data: notification.data,
    };

    try {
      await admin.messaging().send(message);
      console.log('Notification sent successfully');
      await snap.ref.delete();
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });
```

4. Deploy Cloud Functions:
```bash
firebase deploy --only functions
```

## Step 5: Test the Notification System

1. Run the app: `flutter run`
2. Login with a user account
3. Search for blood donors/banks
4. Click the "Notify" button
5. Recipients should receive push notifications

## How It Works

1. **Token Registration**: When users login, their FCM token is saved to Firestore (`users/{userId}/fcmToken`)
2. **Send Notification**: When "Notify" button is clicked:
   - Gets sender's name and blood group
   - Creates notification documents in Firestore
   - Cloud Function triggers and sends FCM messages
   - Updates sender's document with `notificationsSent` count
3. **Receive Notification**: Recipients receive push notifications on their devices
4. **Storage**: Notifications are also stored in `users/{userId}/notifications/` subcollection

## Firestore Structure

```
users/
  {userId}/
    - name: "John Doe"
    - bloodGroup: "A+"
    - fcmToken: "device_token_here"
    - notificationsSent: 5
    - lastNotificationSent: timestamp
    
    notifications/
      {notificationId}/
        - message: "John wants your A+ blood group"
        - senderName: "John"
        - senderBloodGroup: "A+"
        - timestamp: timestamp
        - read: false

notifications/ (temporary, deleted after sending)
  {notificationId}/
    - to: "fcm_token"
    - notification: {...}
    - data: {...}
```

## Troubleshooting

1. **Notifications not received**: 
   - Check if FCM token is saved in Firestore
   - Verify Cloud Functions are deployed
   - Check Firebase Console logs

2. **Permission denied**:
   - Ensure Firestore rules are deployed
   - Check user authentication

3. **iOS notifications not working**:
   - Verify APNs key is uploaded
   - Check Push Notifications capability is enabled
