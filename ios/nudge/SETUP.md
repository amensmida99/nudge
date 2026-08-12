# Nudge — Xcode Setup Guide

The **main app builds and runs as-is**. Two capabilities require a few manual
Xcode steps because they can't be safely added by editing files alone: the
**App Group** and the **Share Extension target**. This guide walks through both.

The `group.nudge.shared` identifier appears in three places and they must all
match:
- `nudge/Utilities/AppConstants.swift` → `AppConstants.appGroupID`
- `nudge/nudge.entitlements`
- `NudgeShareExtension/NudgeShareExtension.entitlements`

---

## 1. App Group (main app)

1. Open `nudge.xcodeproj`.
2. Select the project → **nudge** target → **Signing & Capabilities**.
3. Click **+ Capability** and add **App Groups**.
4. Add a group named exactly `group.nudge.shared` (or your own — then update the
   three locations above to match).
5. Confirm **Build Settings → Code Signing Entitlements** points to
   `nudge/nudge.entitlements` (Xcode usually sets this automatically).

> Without the App Group, `SharedStore` silently falls back to standard
> `UserDefaults`, so the app still runs but Share-Sheet captures won't reach it.

---

## 2. Notification permission

No configuration needed — `UNUserNotificationCenter` requests authorization at
runtime (during onboarding and from Settings). iOS auto-generates the usage
prompt. Test on a device or simulator and accept the prompt.

---

## 3. Share Extension target

The extension's **source lives in `NudgeShareExtension/`** but is not yet part
of the project. Add the target:

1. **File → New → Target… → Share Extension**. Name it `NudgeShareExtension`.
   - If Xcode generates its own `ShareViewController.swift`, `Info.plist`, and
     `MainInterface.storyboard`, **delete the generated Swift file and
     storyboard** and instead add the ones in `NudgeShareExtension/`.
2. Add the provided files to the new target (drag into the project navigator
   under the extension group, or set **Target Membership** in the File
   Inspector):
   - `NudgeShareExtension/ShareViewController.swift`
   - `NudgeShareExtension/Info.plist` (set as the target's Info.plist in
     **Build Settings → Packaging → Info.plist File**)
   - `NudgeShareExtension/NudgeShareExtension.entitlements` (set as
     **Code Signing Entitlements** for the extension target)
3. **Share these app files with the extension** — select each in the navigator
   and, in the **Target Membership** panel, also check `NudgeShareExtension`:
   - `nudge/Models/PendingSharedItem.swift`
   - `nudge/Services/SharedStore.swift`
   - `nudge/Utilities/AppConstants.swift`
   - `nudge/Models/Enums.swift`
4. Add the **App Groups** capability to the extension target too, with the same
   `group.nudge.shared` group.
5. If you removed the storyboard, make sure `Info.plist` uses
   `NSExtensionPrincipalClass = $(PRODUCT_MODULE_NAME).ShareViewController`
   (already set in the provided plist) and there is **no**
   `NSExtensionMainStoryboard` key.

### How the flow works
- The extension writes a small `PendingSharedItem` (Codable JSON) into the App
  Group `UserDefaults` via `SharedStore.enqueue`.
- On `.active` scene phase, the app calls `ShareImportService.importPending`,
  which drains the queue and inserts new `InboxItem`s into SwiftData.
- Duplicates are prevented by the item's stable `UUID` (`@Attribute(.unique)`),
  and the queue is drained atomically so items import exactly once.

---

## 4. Deployment target

The project targets a recent iOS SDK. The code uses iOS 17+ APIs (SwiftData,
`@Observable`, `@Entry`, the new `Tab` API). Lower the deployment target to 17.0
in Build Settings if you need broader device support (the `Tab` initializer and
`@Entry` require iOS 17+, which is satisfied).

---

## 5. Architecture overview

```
nudge/
  Models/        InboxItem, DailyDigest (SwiftData) + PendingSharedItem, Enums
  Services/      APIClient (+MockAPIClient), ClassificationService (+mock),
                 NotificationService, SharedStore, ItemRanker, DigestService,
                 ItemMutator, ShareImportService
  ViewModels/    Today, Inbox, AddItem, ItemDetail, Forgotten, Settings
  Views/         Onboarding, Today, Inbox, AddItem, Detail, Forgotten,
                 Settings, Components, RootView, MainTabView
  Utilities/     AppConstants, AppEnvironment, DateFormatting, SampleData
NudgeShareExtension/
  ShareViewController, Info.plist, entitlements
```

- **MVVM**: Views own `@Query`/state; view models hold derivation + actions.
- **Swift concurrency** throughout; no Combine.
- **Swappable backend**: everything talks to the `APIClient` protocol. Replace
  `MockAPIClient` with an AWS implementation in `AppEnvironment` — no UI changes.
