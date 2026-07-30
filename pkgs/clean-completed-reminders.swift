import EventKit
import Foundation

let eventStore = EKEventStore()

extension EKEventStore {
  func requestReminderAccess() async throws -> Bool {
    if #available(macOS 14.0, *) {
      return try await requestFullAccessToReminders()
    }
    return await withCheckedContinuation { continuation in
      requestAccess(to: .reminder) { granted, _ in
        continuation.resume(returning: granted)
      }
    }
  }

  func fetchReminders(matching predicate: NSPredicate) async throws -> [EKReminder] {
    try await withCheckedThrowingContinuation { continuation in
      fetchReminders(matching: predicate) { reminders in
        continuation.resume(with: .success(reminders ?? []))
      }
    }
  }
}

extension EKReminder {
  var safeTitle: String {
    title ?? "(Untitled)"
  }
}

func main() async throws {
  let granted = try await eventStore.requestReminderAccess()
  guard granted else {
    fputs("error: reminders access not granted\n", stderr)
    exit(1)
  }

  let reminderLists = eventStore.calendars(for: .reminder)
  let reminders = try await eventStore.fetchReminders(
    matching: eventStore.predicateForReminders(in: reminderLists))

  var removedCount = 0
  for reminder in reminders {
    if !reminder.isCompleted {
      continue
    }
    try eventStore.remove(reminder, commit: false)
    removedCount += 1
  }

  if removedCount > 0 {
    try eventStore.commit()
    fputs("Cleared \(removedCount) reminders\n", stderr)
  }
}

Task {
  do {
    try await main()
    exit(0)
  } catch {
    fputs("error: \(error)\n", stderr)
    exit(1)
  }
}

RunLoop.main.run()
