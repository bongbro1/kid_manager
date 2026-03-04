import { CloudTasksClient } from "@google-cloud/tasks";
import { SOS_REMINDER_WORKER_URL, TASK_LOCATION, TASK_QUEUE, REMIND_INTERVAL_SEC } from "../config";
import { getProjectId } from "../helpers";

const tasksClient = new CloudTasksClient();

export async function enqueueSosReminder(params: { familyId: string; sosId: string; createdAtMs: number }) {
  const project = getProjectId();
  if (!project) throw new Error("Missing GCLOUD_PROJECT");

  const parent = tasksClient.queuePath(project, TASK_LOCATION, TASK_QUEUE);

  const workerUrl = SOS_REMINDER_WORKER_URL.value();
  if (!workerUrl) throw new Error("Missing SOS_REMINDER_WORKER_URL env");

  const scheduleTime = { seconds: Math.floor(Date.now() / 1000) + REMIND_INTERVAL_SEC };

  const payload = Buffer.from(
    JSON.stringify({ familyId: params.familyId, sosId: params.sosId, createdAtMs: params.createdAtMs })
  ).toString("base64");

  const task = {
    httpRequest: {
      httpMethod: "POST" as const,
      url: workerUrl,
      headers: { "Content-Type": "application/json" },
      body: payload,
      oidcToken: { serviceAccountEmail: `${project}@appspot.gserviceaccount.com` },
    },
    scheduleTime,
  };

  await tasksClient.createTask({ parent, task });
}