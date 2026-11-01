# 🍲 Hotpot Timer

SwiftUI app for all-you-can-eat hotpot / yakiniku. iOS 17+.
Has a repeating 10-minute "order more on the tablet" timer with a Live Activity, plus a meat plate counter with history.

## Project layout

| Folder | Target | What's inside |
|---|---|---|
| `HotpotTimer/` | App | App entry, `TimerEngine` (notifications + Live Activity), SwiftData models, views |
| `HotpotWidget/` | Widget Extension | Live Activity UI (Lock Screen + Dynamic Island) |
| `Shared/` | Both | `HotpotActivityAttributes`, `RestartTimerIntent`, `Theme` |
| `Config/` | — | Info.plists (`NSSupportsLiveActivities = YES`) and entitlements (Time Sensitive) |

The project uses Xcode folder-synced groups, so files you drop into these folders are picked up automatically.

## Run it on your iPhone

1. **(One-time) point the command-line tools at Xcode.** Run this in Terminal (it asks for your password):
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```
2. **Open the project.** Double-click `HotpotTimer.xcodeproj`.
3. **Set your signing team for both targets:**
   - Click the blue **HotpotTimer** project at the top of the navigator.
   - Select the **HotpotTimer** target, then **Signing & Capabilities**. Keep **Automatically manage signing** on and pick your Apple ID under **Team**. If you haven't added your account yet: **Xcode → Settings → Accounts → +**.
   - Select the **HotpotWidgetExtension** target and pick the **same Team**.
   - If Xcode says the bundle ID is unavailable, change `com.nikhilmath.hotpottimer` to something unique in **both** targets. The widget's ID must stay the app's ID plus `.LiveActivity`.
   - **Time Sensitive Notifications** needs a paid Apple Developer Program account, because free Personal Teams can't sign it. So it's unlinked by default. If you join the program, go to the app target's **Build Settings** and set **Code Signing Entitlements** to `Config/HotpotTimer.entitlements` to turn it back on. Without it, alerts still fire with sound. To get them through a Focus, add Hotpot Timer to that Focus's allowed apps (see below).
4. **Connect your iPhone** with a cable (or use the same Wi-Fi after the first pairing). Unlock it and tap **Trust**.
5. **Turn on Developer Mode** on the phone: **Settings → Privacy & Security → Developer Mode → On**. The phone restarts.
6. In Xcode's toolbar, choose the **HotpotTimer** scheme and **your iPhone** as the destination, then press **⌘R**.
7. With a free Apple ID, the first launch is blocked as an untrusted developer. On the phone, go to **Settings → General → VPN & Device Management**, tap your Apple ID, then tap **Trust**. Launch the app again.
   (Apps signed with a free account expire after 7 days. Press ⌘R again to reinstall.)
8. On first launch, tap **Allow** when the app asks to send notifications.

## Settings to check on the iPhone

- **Settings → Notifications → Hotpot Timer**
  - **Allow Notifications**: on. Turn **Sounds** on and enable **Lock Screen**, **Notification Center** and **Banners**.
  - **Time Sensitive Notifications**: on. This lets the alerts break through Focus.
- **Settings → Hotpot Timer → Live Activities**: on. Also check **Settings → Face ID & Passcode → Allow Access When Locked → Live Activities**: on.
- **Focus**: on a free Personal Team, alerts only break through a Focus if you go to **Settings → Focus → (your Focus) → Apps** and add **Hotpot Timer** to the allowed apps. With a paid account and the entitlement turned on, allowing **Time Sensitive Notifications** in that Focus is enough.

## Settings for Apple Watch mirroring

iPhone notifications go to the Watch only when **the iPhone is locked or asleep** and **the Watch is on your wrist and unlocked**. If you're looking at the unlocked phone, the alert stays on the phone.

1. On the iPhone, open the **Watch** app, then **Notifications**, and scroll to **Mirror iPhone Alerts From:**. Turn on **Hotpot Timer**. It shows up after the app has asked for notification permission once.
2. In **Watch app → General → Wrist Detection**: on.
3. On the Watch, make sure **Silent Mode** is off (Control Center bell icon) if you want the sound. Haptics play either way.
4. If you use Focus, keep **Settings → Focus → Mirror on Apple Watch** on. Time Sensitive alerts get through Focus on both devices.

The **Restart** button appears on the Watch notification too. Tapping it restarts the timer on the phone without opening the app.

## How it works (and one limitation)

- Restart sets an "anchor" time. Every round ends at `anchor + n × 10 min`. Up to 48 rounds (8 hours) are scheduled at once as local notifications, so they fire even if the app is killed. iOS allows 64 pending notifications per app. The queue is topped up each time you open the app.
- The Live Activity counts down by itself with `Text(timerInterval:)`. It moves to the next round when the app is open, when you tap a notification or its Restart action, or when you use Restart on the Lock Screen / Dynamic Island.
- **Limitation:** if a round ends while the app is fully in the background *and you don't interact*, the Live Activity can't move itself to the next round. iOS gives local apps no way to wake up then; only a push server could. It stops at 0:00 and shows "Time's up — order more! 📲". The notifications keep firing on schedule regardless. Opening the app or tapping any notification snaps the Live Activity to the current round.
- Live Activities are ended by iOS after 8 hours (12 on the Lock Screen). Opening the app starts a fresh one if the timer is still running.

## Meat counter

- Big **+** / small **−** per meat, with haptics. Counts persist with SwiftData.
- **Add type** creates a custom meat. Long-press a custom row to delete it.
- **Save & Close Session** saves date, duration (from your first Start or first plate), total, and per-meat counts to **History** (🏆 button). Then it resets the counts and stops the timer, which cancels pending notifications and ends the Live Activity.
- History highlights your personal record. Swipe a row to delete it.

## Table display (landscape)

Turn the phone sideways to get a full-screen display for the table: a big next-order countdown on the left and the group plate total, people count and plates per person on the right. The screen stays awake while it's sideways. Rotate back to portrait to tap counters.
