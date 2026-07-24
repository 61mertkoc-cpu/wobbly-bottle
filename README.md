# Wobbly Bottle — Native Android

Native Java/Android Canvas implementation of the four supplied reference screens.

## Requirements

- Android 7.0 (API 24) or newer
- An active, validated internet connection (the complete UI is blocked while offline)
- Portrait orientation

## Included gameplay

- Empty player roster at first launch, six selectable neon player colors, 2-player minimum
- Five object cards with single-selection state
- Rewarded-video unlock flow for Chicken, Banana, and Slipper
- VIP lock for Golden Champagne and the +18 Spicy pack
- Symmetric 2×3 pack selection grid
- Random multi-frequency wobble/bend during every spin
- Questioner/answerer neon highlights and lasers
- In-game object/pack switching through the Profile drawer
- HOME and PROFILE navigation

## Demo integrations

This APK is a standalone demo build. The rewarded-video screen performs a real timed
unlock but does not use a third-party ad network. VIP activation is clearly marked as
demo and makes no payment. A production release needs Google Mobile Ads ad-unit IDs and
a Google Play Billing product configured in the publisher's own accounts.

## Build

```powershell
.\gradlew.bat :app:assembleDebug
```

The installable APK is generated at:

`app\build\outputs\apk\debug\app-debug.apk`
