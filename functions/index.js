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
      data: notification.data || {},
      android: {
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
      console.log('Notification sent successfully');
      await snap.ref.delete();
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });
