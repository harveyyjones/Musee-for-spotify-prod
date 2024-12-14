const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");
const {getFirestore} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin
initializeApp();

// Get Firestore instance
const db = getFirestore();

// Export the notification function
exports.sendChatNotification = onDocumentCreated(
    "message_notifications/{notificationId}",
    async (event) => {
      try {
        const notification = event.data.data();
        logger.info("Processing notification", notification);

        const recipientDoc = await db
            .collection("users")
            .doc(notification.recipientId)
            .get();

        const recipientData = recipientDoc.data();
        const recipientToken = recipientData ? recipientData.fcmToken : null;

        if (!recipientToken) {
          logger.warn("No FCM token found for recipient");
          return null;
        }

        const senderDoc = await db
            .collection("users")
            .doc(notification.senderId)
            .get();

        const senderData = senderDoc.data();
        const senderName = senderData && senderData.name ?
                senderData.name : "Someone";

        const message = {
          token: recipientToken,
          notification: {
            title: `New message from ${senderName}`,
            body: notification.message || "New message received",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "chat_messages",
              priority: "high",
              visibility: "public",
              sound: "default",
              icon: "@mipmap/ic_launcher",
              clickAction: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: `New message from ${senderName}`,
                  body: notification.message || "New message received",
                },
                sound: "default",
              },
            },
          },
          // Add data payload for background handling
          data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            sender_id: notification.senderId,
            sender_name: senderName,
            message: notification.message || "New message received",
            notification_type: "chat_message",
          },
        };

        logger.info("Sending message:", message);
        await getMessaging().send(message);
        logger.info("Message sent successfully");

        await event.data.ref.delete();
        return null;
      } catch (error) {
        logger.error("Error sending notification", error);
        return null;
      }
    },
);
