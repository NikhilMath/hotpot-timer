# 🍲 Hotpot Timer

SwiftUI app for all-you-can-eat hotpot / yakiniku. iOS 17+.
Has a repeating 10-minute "order up again" timer for the restaurant's ordering tablet, with a Live Activity and a StandBy widget, plus a group plate counter with history.

## Project layout

| Folder | Target | What's inside |
|---|---|---|
| `HotpotTimer/` | App | App entry, `TimerEngine` (notifications + Live Activity), SwiftData models, views |
| `HotpotWidget/` | Widget Extension | Live Activity UI (Lock Screen + Dynamic Island) and the StandBy / Home Screen widget |
| `Shared/` | Both | `HotpotActivityAttributes`, `RestartTimerIntent`, `OrderTimerCore` (restart logic usable from the widget), `SharedStore` (App Group data), `Theme` |
| `Config/` | — | Info.plists (`NSSupportsLiveActivities = YES`) and entitlements (App Group `group.com.nikhilmath.hotpottimer`; `HotpotTimer-Paid.entitlements` adds Time Sensitive) |

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
   - If Xcode says the bundle ID is unavailable, change `com.nikhilmath.hotpottimer` to something unique in **both** targets. The widget's ID must stay the app's ID plus `.LiveActivity`. Also change the App Group name to match: it's in the three `Config/*.entitlements` files and in `SharedStore.appGroup`.
   - **Time Sensitive Notifications** needs a paid Apple Developer Program account, because free Personal Teams can't sign it. So it's off by default. If you join the program, go to the app target's **Build Settings** and change **Code Signing Entitlements** to `Config/HotpotTimer-Paid.entitlements` to turn it on. Without it, alerts still fire with sound. To get them through a Focus, add Hotpot Timer to that Focus's allowed apps (see below).
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

## Plate counter

- One shared counter for the table: a big **+ 1 plate** button and a smaller **−**, with haptics. Which meat you ordered doesn't matter.
- **人数 People** sets how many are eating. The total becomes the group total and shows plates per person.
- The count is saved in the App Group, so it survives closing the app, and the widget and Live Activity show it.
- **Save & Close Session** saves the date, duration (from your first Start or first plate), group total and people count to **History** (🏆 button). Then it resets the counter and stops the timer, which cancels pending notifications and ends the Live Activity.
- History highlights your personal record (記録). Swipe a row to delete it.

## Table display (landscape)

Turn the phone sideways to get a full-screen display for the table: an "order up again" countdown with a **Restart** button on one side, and the group total with **+ 1 plate** / **−** on the other. The screen stays awake while it's sideways.

To avoid OLED burn-in, the two halves swap sides every 3 minutes and the layout drifts slightly. Rotate back to portrait for People, History and Save & Close.

## Look

Japanese izakaya style: sumi-ink black, 朱 vermilion lacquer, gold-leaf hairlines and washi-paper text, with a faint 青海波 seigaiha wave pattern behind. Labels use Hiragino Mincho kanji: 注文 order, 合計 total, 人数 people, 記録 record, 食べ放題 all-you-can-eat. All colors and fonts live in `Shared/Theme.swift`.

## StandBy widget

StandBy is the clock-style screen an iPhone shows when it's charging, locked and turned on its side.

- **Live Activity:** while the timer runs, its countdown already shows in StandBy. Tap it to make it full-screen.
- **Order Timer widget:** add it so the countdown and plate count are always on the StandBy screen:
  1. Put the phone on a charger, lock it, and turn it sideways. If StandBy doesn't start, turn it on in **Settings → StandBy**.
  2. Touch and hold the left or right widget stack, then unlock if asked.
  3. Tap **+**, search for **Hotpot Timer**, choose **Order Timer**, and tap **Add Widget**. Then tap **Done**.

  The widget shows the "order up" countdown, the group total and plates per person. It has a ▶ / ↻ button that starts or restarts the timer. Every future round is scheduled into the widget ahead of time, so it moves to the next round by itself even when the app is closed. The same widget also works on the Home Screen.
