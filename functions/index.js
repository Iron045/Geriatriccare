const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

exports.sendSosToLinkedChildren = onDocumentCreated(
  {
    document: "sos_alerts/{alertId}",
    region: "asia-southeast1",
  },
  async (event) => {
    const alert = event.data?.data();
    if (!alert || alert.status !== "active" || !alert.elderUserId) return;

    const db = getFirestore();
    const relationships = await db
      .collection("care_relationships")
      .where("elderId", "==", alert.elderUserId)
      .get();

    const childIds = [...new Set(
      relationships.docs
        .map((doc) => doc.data())
        .filter((relationship) => relationship.status === "accepted")
        .map((relationship) => relationship.childId)
        .filter(Boolean),
    )];
    if (childIds.length === 0) {
      await event.data.ref.update({
        notificationStatus: "no_linked_child",
        notificationProcessedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const tokenDocs = [];
    for (let index = 0; index < childIds.length; index += 30) {
      const snapshot = await db
        .collection("fcm_tokens")
        .where("userId", "in", childIds.slice(index, index + 30))
        .get();
      tokenDocs.push(...snapshot.docs);
    }

    const uniqueTokens = [...new Set(
      tokenDocs.map((doc) => doc.data().token).filter(Boolean),
    )];
    if (uniqueTokens.length === 0) {
      await event.data.ref.update({
        notificationStatus: "no_registered_device",
        notificationProcessedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    let successCount = 0;
    let failureCount = 0;
    const invalidTokens = [];
    for (let index = 0; index < uniqueTokens.length; index += 500) {
      const tokens = uniqueTokens.slice(index, index + 500);
      const response = await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "CẢNH BÁO SOS KHẨN CẤP",
          body: "Người thân của bạn đang cần được hỗ trợ. Hãy liên hệ ngay!",
        },
        data: {
          type: "sos",
          alertId: event.params.alertId,
          elderId: alert.elderUserId,
        },
        android: {
          priority: "high",
          notification: {
            priority: "max",
            sound: "default",
            visibility: "public",
          },
        },
        apns: {
          payload: {aps: {sound: "default"}},
        },
        webpush: {
          notification: {requireInteraction: true},
        },
      });
      successCount += response.successCount;
      failureCount += response.failureCount;
      response.responses.forEach((result, responseIndex) => {
        const code = result.error?.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          invalidTokens.push(tokens[responseIndex]);
        }
      });
    }

    if (invalidTokens.length > 0) {
      const invalidSet = new Set(invalidTokens);
      const batch = db.batch();
      tokenDocs.forEach((doc) => {
        if (invalidSet.has(doc.data().token)) batch.delete(doc.ref);
      });
      await batch.commit();
    }

    await event.data.ref.update({
      notificationStatus: successCount > 0 ? "sent" : "failed",
      notificationSuccessCount: successCount,
      notificationFailureCount: failureCount,
      notificationProcessedAt: FieldValue.serverTimestamp(),
    });
    logger.info("SOS push notification processed", {
      alertId: event.params.alertId,
      successCount,
      failureCount,
    });
  },
);
