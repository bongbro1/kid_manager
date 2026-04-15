import { onValueWritten } from "firebase-functions/v2/database";
import { admin, db } from "../../bootstrap";
import { RTDB_TRIGGER_REGION } from "../../config";
import { createGlobalNotificationRecord } from "../../services/globalNotifications";
import {
  BATTERY_EVENT_CATEGORY,
  BatteryAlertSeverity,
  buildBatteryNotificationRecord,
  deriveBatterySeverity,
  normalizeBatteryLevel,
  normalizeChargingState,
  shouldResetBatteryAlert,
} from "../../services/batteryNotifications";
import {
  listManagedAdultRecipientUids,
  resolveUserLanguage,
  toMillis,
} from "../../services/trackingLocationNotifications";

function readTrimmedString(
  data: Record<string, unknown>,
  field: string,
): string {
  const value = data[field];
  return typeof value === "string" ? value.trim() : "";
}

async function resolveChildName(params: {
  childUid: string;
  statusData: Record<string, unknown>;
}): Promise<string> {
  const existingName = readTrimmedString(params.statusData, "childName");
  if (existingName) {
    return existingName;
  }

  const childSnap = await db.doc(`users/${params.childUid}`).get();
  const childData = childSnap.exists
    ? (childSnap.data() as Record<string, unknown>)
    : {};

  return (
    readTrimmedString(childData, "displayName") ||
    readTrimmedString(childData, "name") ||
    "Con"
  );
}

export const onLiveBatteryStatusWritten = onValueWritten(
  {
    ref: "live_locations_by_family/{familyId}/{childUid}",
    region: RTDB_TRIGGER_REGION,
  },
  async (event) => {
    const familyId = String(event.params.familyId ?? "").trim();
    const childUid = String(event.params.childUid ?? "").trim();
    if (!familyId || !childUid || !event.data.after.exists()) {
      return;
    }

    const beforeRaw =
      event.data.before.exists() && event.data.before.val()
        ? (event.data.before.val() as Record<string, unknown>)
        : {};
    const afterRaw = event.data.after.val() as Record<string, unknown>;

    const previousLevel = normalizeBatteryLevel(beforeRaw.batteryLevel);
    const nextLevel = normalizeBatteryLevel(afterRaw.batteryLevel);
    const previousCharging = normalizeChargingState(beforeRaw.isCharging);
    const nextCharging = normalizeChargingState(afterRaw.isCharging);
    const previousSeverity = deriveBatterySeverity({
      batteryLevel: previousLevel,
      isCharging: previousCharging,
    });
    const nextSeverity = deriveBatterySeverity({
      batteryLevel: nextLevel,
      isCharging: nextCharging,
    });

    const batteryDidChange =
      previousLevel !== nextLevel ||
      previousCharging !== nextCharging ||
      previousSeverity !== nextSeverity;
    if (!batteryDidChange || nextLevel == null) {
      return;
    }

    const statusRef = db.doc(`families/${familyId}/trackingStatus/${childUid}`);
    const nowMs = Date.now();
    const transactionResult = await db.runTransaction(async (tx) => {
      const statusSnap = await tx.get(statusRef);
      const statusData = statusSnap.exists
        ? (statusSnap.data() as Record<string, unknown>)
        : {};
      const batteryData =
        statusData.battery && typeof statusData.battery === "object"
          ? (statusData.battery as Record<string, unknown>)
          : {};

      const storedLevel = normalizeBatteryLevel(batteryData.level);
      const storedCharging = normalizeChargingState(batteryData.isCharging);
      const storedSeverity = readTrimmedString(batteryData, "severity");
      const storedAlertSeverity = readTrimmedString(
        batteryData,
        "lastAlertSeverity",
      ) as BatteryAlertSeverity | "";
      const storedAlertAtMs =
        toMillis(batteryData.lastAlertAtMs) ?? toMillis(batteryData.lastAlertAt);

      const resetAlertState = shouldResetBatteryAlert({
        batteryLevel: nextLevel,
        isCharging: nextCharging,
        severity: nextSeverity,
      });

      let alertSeverityToSend: BatteryAlertSeverity | null = null;
      if (!resetAlertState) {
        if (nextSeverity === "low" && !storedAlertSeverity) {
          alertSeverityToSend = "low";
        } else if (
          nextSeverity === "critical" &&
          storedAlertSeverity !== "critical"
        ) {
          alertSeverityToSend = "critical";
        }
      }

      const nextAlertSeverity =
        resetAlertState
          ? null
          : alertSeverityToSend ?? (storedAlertSeverity || null);
      const nextAlertAtMs = resetAlertState
        ? null
        : alertSeverityToSend != null
        ? nowMs
        : storedAlertAtMs;

      const shouldWriteBatteryState =
        storedLevel !== nextLevel ||
        storedCharging !== nextCharging ||
        storedSeverity !== nextSeverity ||
        storedAlertSeverity !== (nextAlertSeverity ?? "") ||
        storedAlertAtMs !== nextAlertAtMs;

      if (!shouldWriteBatteryState && alertSeverityToSend == null) {
        return {
          alertSeverityToSend: null as BatteryAlertSeverity | null,
          childName: readTrimmedString(statusData, "childName"),
        };
      }

      const update: Record<string, unknown> = {
        "battery.level": nextLevel,
        "battery.isCharging": nextCharging ?? false,
        "battery.severity": nextSeverity,
        "battery.updatedAt": admin.firestore.FieldValue.serverTimestamp(),
      };

      if (resetAlertState) {
        update["battery.lastAlertSeverity"] = null;
        update["battery.lastAlertAt"] = null;
        update["battery.lastAlertAtMs"] = null;
      } else if (alertSeverityToSend != null) {
        update["battery.lastAlertSeverity"] = alertSeverityToSend;
        update["battery.lastAlertAt"] = admin.firestore.FieldValue.serverTimestamp();
        update["battery.lastAlertAtMs"] = nowMs;
      }

      if (!statusSnap.exists) {
        update.childId = childUid;
        update.familyId = familyId;
      }

      tx.set(statusRef, update, { merge: true });

      return {
        alertSeverityToSend,
        childName: readTrimmedString(statusData, "childName"),
      };
    });

    if (transactionResult.alertSeverityToSend == null) {
      return;
    }

    const childName = transactionResult.childName
      ? transactionResult.childName
      : await resolveChildName({
          childUid,
          statusData: {},
        });
    const receiverUids = await listManagedAdultRecipientUids({
      familyId,
      childUid,
    });
    if (receiverUids.length === 0) {
      return;
    }

    for (const receiverUid of receiverUids) {
      const locale = await resolveUserLanguage(receiverUid);
      const notification = buildBatteryNotificationRecord({
        locale,
        childUid,
        childName,
        familyId,
        batteryLevel: nextLevel,
        isCharging: nextCharging === true,
        severity: transactionResult.alertSeverityToSend,
        nowMs,
      });

      await createGlobalNotificationRecord({
        receiverId: receiverUid,
        senderId: "system",
        type: "BATTERY",
        title: notification.title,
        body: notification.body,
        eventKey: notification.eventKey,
        eventCategory: BATTERY_EVENT_CATEGORY,
        expiresAt: notification.expiresAt,
        data: notification.data,
        familyId,
      });
    }
  },
);
