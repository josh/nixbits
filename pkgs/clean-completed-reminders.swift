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

  eventStore.reset()

  // Subscribed or shared read-only lists reject remove(); one throw before
  // commit() would abort the batch and delete nothing at all.
  let reminderLists = eventStore.calendars(for: .reminder)
    .filter(\.allowsContentModifications)

  // An empty array is not the "all calendars" nil sentinel; nothing to clean.
  guard !reminderLists.isEmpty else {
    return
  }

  let reminders = try await eventStore.fetchReminders(
    matching: eventStore.predicateForReminders(in: reminderLists))

  var removedCount = 0
  for reminder in reminders {
    if !reminder.isCompleted {
      continue
    }
    do {
      try eventStore.remove(reminder, commit: false)
      removedCount += 1
    } catch {
      fputs("warn: could not remove '\(reminder.safeTitle)': \(error)\n", stderr)
    }
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
