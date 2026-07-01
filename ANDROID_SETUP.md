# Android Build Setup Guide

This guide shows you how to build the Hood Legends project into an installable `.apk` file you can put on your phone. Since you already have Android Studio installed, you already have most of what you need.

---

## Step 1: Install the Android Build Template (one-time)

Godot needs the **Android SDK** + **Keystore** to build APKs. Android Studio installs the SDK, but you also need to point Godot at it.

### 1.1 Locate your Android SDK path

If you installed Android Studio with default settings, the SDK is at:

- **Windows:** `C:\Users\<YourName>\AppData\Local\Android\Sdk`
- **Mac:** `~/Library/Android/sdk`
- **Linux:** `~/Android/Sdk`

Open Android Studio → **SDK Manager** (gear icon or `Tools > SDK Manager`) → **SDK Tools** tab → make sure these are checked and installed:
- ✅ Android SDK Build-Tools
- ✅ Android SDK Command-line Tools (latest)
- ✅ Android SDK Platform-Tools

Note down the path to your SDK folder.

### 1.2 Tell Godot where the SDK is

1. Open Godot, open the Hood Legends project
2. Menu → **Editor → Editor Settings**
3. Scroll down to **Export > Android**
4. Set these paths:
   - **Android SDK Path:** `<your SDK path>` (e.g. `C:\Users\YourName\AppData\Local\Android\Sdk`)
   - **Debug Keystore:** leave default (`~/.android/debug.keystore`) — Godot will auto-generate it if it doesn't exist
   - **Debug Keystore User:** `androiddebugkey`
   - **Debug Keystore Password:** `android`
5. Close Editor Settings

### 1.3 Download Export Templates

1. Menu → **Editor → Manage Export Templates**
2. Click **Download from mirror** (about 600MB, one-time download)
3. Wait — once installed, you never have to do this again

---

## Step 2: Create the Android Export Preset

1. Menu → **Project → Export**
2. Click **Add...** → select **Android**
3. In the right panel, make sure:
   - **Package Name:** `com.hoodlegends.game`
   - **Name:** `Hood Legends`
   - **Min SDK Version:** 21 (Android 5.0+)
   - **Target SDK Version:** 33 (Android 13)
   - **Architectures:** check `arm64-v8a` (modern phones) — also `armeabi-v7a` if you want older phones
4. Click **Export Project...**
5. Choose a location → save as `hood-legends.apk`
6. Wait ~30 seconds for the build

You now have a `.apk` file you can install on your phone.

---

## Step 3: Install on Your Phone

### Option A: USB cable (recommended)

1. On your phone: **Settings → About phone → tap Build Number 7 times** to enable Developer Mode
2. **Settings → Developer Options → enable USB Debugging**
3. Connect phone to PC via USB
4. On PC, open a terminal/command prompt:
   ```bash
   cd "C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools"
   adb install "C:\path\to\hood-legends.apk"
   ```
5. The game appears in your app drawer

### Option B: Copy the APK file manually

1. Copy `hood-legends.apk` to your phone (USB transfer, Google Drive, WhatsApp to yourself, whatever)
2. On phone: **Settings → Security → enable "Unknown Sources"** (or tap the file and allow when prompted)
3. Open file manager → tap the APK → install
4. App appears in app drawer

---

## Step 4: Test It

Open "Hood Legends" on your phone. You should see:
- Virtual joystick on the **bottom-left** — drag to walk
- Right half of screen = swipe to **look around** (camera)
- Buttons on the **bottom-right**: JUMP, RUN
- Button on the **middle**: ENTER/EXIT vehicle (appears when near a car)
- Button on the **top-right**: SWITCH character (Marcus ↔ Maya)
- Button on the **right**: FIRE (placeholder for now, no gun yet)

If something doesn't show or doesn't work, tell me what you see and I'll fix it.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| "JDK not found" | Install Java JDK 17 (Android Studio usually bundles it — point Godot to `C:\Program Files\Android\Android Studio\jbr`) |
| "SDK path invalid" | Re-check the path in Editor Settings — must point to the folder containing `platform-tools` |
| APK won't install on phone | Enable "Unknown sources" in phone security settings |
| Game crashes on launch | Make sure your phone is Android 5.0+ (API 21+) |
| Game lags on phone | In project.godot, change `Forward Plus` rendering to `Mobile` for better phone performance (I'll handle this in Phase 2 optimization) |

---

## What's Next

Once you've successfully built and installed the APK on your phone, we can move to **Phase 2**:
- Replace capsule/box shapes with real 3D character and car models
- Bigger map (start of Los Santos-style city)
- More cars (different brands/models)
- Enter buildings
- Gun system (touch FIRE button to shoot)
- Police + wanted stars
- Save/load system

Just confirm the APK works on your phone and tell me what feels broken or missing — we'll iterate from there.
