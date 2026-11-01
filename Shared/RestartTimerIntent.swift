import AppIntents

/// Restart button on the Lock Screen, expanded Dynamic Island and StandBy widget.
///
/// Compiled into both targets. iOS may run `perform()` in the app or in the widget
/// extension, so both paths do a full restart.
struct RestartTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Restart Hotpot Timer"
    static var description = IntentDescription("Restarts the 10-minute countdown from now.")
    static var openAppWhenRun = false

    init() {}

    func perform() async throws -> some IntentResult {
        #if WIDGET_EXTENSION
        await OrderTimerCore.restart()
        #else
        // Also refreshes the app's in-memory state and can start a Live Activity if none is running.
        await TimerEngine.shared.restart()
        #endif
        return .result()
    }
}
