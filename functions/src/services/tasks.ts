import { CloudTasksClient } from "@google-cloud/tasks";
import { TASK_LOCATION, getSosReminderRuntimeConfig } from "../config";

const client = new CloudTasksClient();

export function getReminderDelaySec(attempt: number): number | null {
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

  const runtimeConfig = getSosReminderRuntimeConfig();

  if (!runtimeConfig.projectId) {
    throw new Error("Missing PROJECT_ID");
  }
  if (!runtimeConfig.workerUrl) {
    throw new Error("Missing SOS_REMINDER_WORKER_URL");
  }
  if (!runtimeConfig.taskCallerServiceAccount) {
    throw new Error("Missing SOS_TASK_CALLER_SA");
  }

  const parent = client.queuePath(
    runtimeConfig.projectId,
    TASK_LOCATION,
    runtimeConfig.queueId,
  );

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
      url: runtimeConfig.workerUrl,
      headers: {
        "Content-Type": "application/json",
      },
      oidcToken: {
        serviceAccountEmail: runtimeConfig.taskCallerServiceAccount,
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
