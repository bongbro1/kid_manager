import { CloudTasksClient } from "@google-cloud/tasks";
import { REGION } from "../config";

const client = new CloudTasksClient();

// Đổi các biến này theo project của bạn
const PROJECT_ID = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || "";
const QUEUE_ID = process.env.SOS_REMINDER_QUEUE_ID || "sos-reminder-queue";
const WORKER_URL = process.env.SOS_REMINDER_WORKER_URL || "";
const TASK_CALLER_SA =
process.env.SOS_TASK_CALLER_SA || ""; // vd: firebase-adminsdk-xxx@project-id.iam.gserviceaccount.com

export function getReminderDelaySec(attempt: number): number | null {
  // attempt = 1 là lần nhắc đầu tiên sau push ban đầu
  switch (attempt) {
    case 1:
      return 45;
    case 2:
      return 120;
    case 3:
      return 300;
    case 4:
    case 5:
    case 6:
      return 600;
    default:
      return null;
  }
}

export async function enqueueSosReminder(params: {
  familyId: string;
  sosId: string;
  createdAtMs: number;
  attempt: number;
}) {
  const { familyId, sosId, createdAtMs, attempt } = params;

  const delaySec = getReminderDelaySec(attempt);
  if (delaySec == null) {
    return { enqueued: false, reason: "max-attempt-reached" };
  }

  if (!PROJECT_ID) {
    throw new Error("Missing PROJECT_ID");
  }
  if (!WORKER_URL) {
    throw new Error("Missing SOS_REMINDER_WORKER_URL");
  }
  if (!TASK_CALLER_SA) {
    throw new Error("Missing SOS_TASK_CALLER_SA");
  }

  const parent = client.queuePath(PROJECT_ID, REGION, QUEUE_ID);

  const scheduleSeconds = Math.floor(Date.now() / 1000) + delaySec;

  const payload = {
    familyId,
    sosId,
    createdAtMs,
    attempt,
  };

  const task = {
    httpRequest: {
      httpMethod: "POST" as const,
      url: WORKER_URL,
      headers: {
        "Content-Type": "application/json",
      },
      oidcToken: {
        serviceAccountEmail: TASK_CALLER_SA,
      },
      body: Buffer.from(JSON.stringify(payload)).toString("base64"),
    },
    scheduleTime: {
      seconds: scheduleSeconds,
    },
  };

  const [resp] = await client.createTask({
    parent,
    task,
  });

  return {
    enqueued: true,
    taskName: resp.name ?? null,
    delaySec,
    attempt,
  };
}