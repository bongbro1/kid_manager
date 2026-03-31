export type InitialSosFanoutAction =
  | "skip"
  | "send_and_schedule"
  | "schedule_only";

export function decideInitialSosFanoutAction(params: {
  fanoutSentAt: unknown;
  reminderNextAttempt: unknown;
  reminderScheduleState: unknown;
  reminderStoppedAt: unknown;
}): InitialSosFanoutAction {
  const {
    fanoutSentAt,
    reminderNextAttempt,
    reminderScheduleState,
    reminderStoppedAt,
  } = params;

  if (reminderStoppedAt != null) {
    return "skip";
  }

  const hasSentInitialPush = fanoutSentAt != null;
  const nextAttempt = Number(reminderNextAttempt ?? 0);
  const hasScheduledReminder =
    nextAttempt >= 1 || reminderScheduleState === "scheduled";

  if (!hasSentInitialPush) {
    return "send_and_schedule";
  }

  if (!hasScheduledReminder) {
    return "schedule_only";
  }

  return "skip";
}
