import AppIntents

/// Restart button on the Lock Screen / expanded Dynamic Island.
///
/// This file is compiled into both targets so the widget can reference the intent,
/// but as a `LiveActivityIntent` the system always runs `perform()` inside the app's process.
struct RestartTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Restart Hotpot Timer"
    static var description = IntentDescription("Restarts the 10-minute countdown from now.")

    init() {}

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await TimerEngine.shared.restart()
        #endif
        return .result()
    }
}
