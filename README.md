# Hood Legends — Phase 1 Build (Cross-Platform: PC + Android)

A 3D open-world action game inspired by GTA San Andreas. Built with Godot 4.
Runs on **Windows, Mac, Linux, AND Android** from the same project.

## What's in Phase 1

### Working features:
- 3D world with city streets, buildings, trees, and streetlights
- Two playable characters (Marcus + Maya) — switch between them like GTA V
- Third-person camera (mouse-look on PC, swipe-to-look on mobile)
- Walk, run, jump
- One drivable car (Porsche-style "Comet") with realistic physics
- Enter/exit vehicles with a button press
- Each character stays where you left them when you switch

### Cross-platform input:
- **PC:** WASD + mouse + Shift + Space + F + Tab
- **Mobile:** Virtual joystick (bottom-left) + swipe-to-look + on-screen buttons (Jump, Run, Enter/Exit, Switch, Fire)
- Godot auto-detects the platform and shows the right UI

### Coming in later phases:
- Bigger map (Los Santos, San Fierro, Las Venturas)
- More cars (supercars, muscles, bikes)
- Planes
- Guns and combat (FIRE button already wired up)
- Police + wanted system
- Story missions + NPCs
- Houses you can enter (sleep, watch TV, cook)
- Radio stations
- Homies that follow you
- Races, clubs, side activities

---

## What Is Godot? (Quick Explainer)

Godot is **not** a code editor like VSCode, and **not** an IDE like Android Studio.

Godot is a **full game engine** — like Unity or Unreal Engine. It includes:
- A 3D renderer (so the world actually appears on screen)
- A physics engine (gravity, collisions, vehicle wheels)
- An audio system
- An animation system
- Its own code editor (for GDScript)
- Export to **Windows, Mac, Linux, Android, iOS, Web** — all from one project

You **can** use VSCode to edit the GDScript files if you prefer (Godot supports external editors in `Editor Settings → Text Editor → External`). But for opening the project, running it, and exporting, you use Godot itself.

Android Studio is great for native Android apps (Java/Kotlin), but it's not designed for 3D games. We use Godot, which compiles your game to an APK using the Android SDK (which Android Studio already installed for you — perfect).

---

## How to Run This on PC

### Step 1: Install Godot 4 (free, 5 minutes)
1. Go to https://godotengine.org/download
2. Download **Godot 4.x Standard** (NOT .NET version)
3. Run it (no install needed on Windows — just open the .exe)

### Step 2: Open the Project
1. Unzip this folder somewhere permanent
2. In Godot, click **Import**
3. Select `project.godot`
4. Click **Import & Edit**

### Step 3: Play
- Press **F5**
- First time: select `scenes/main.tscn` as main scene

### PC Controls
| Action | Key |
|---|---|
| Move | WASD |
| Run | Shift (hold) |
| Jump | Space |
| Look around | Mouse |
| Switch character | Tab |
| Enter/Exit vehicle | F |
| Interact | E |
| Pause / Quit | Esc |

---

## How to Build for Android (APK)

**You already have Android Studio installed — that's perfect.** Godot uses the Android SDK that comes with Android Studio.

👉 **Follow the step-by-step guide in `ANDROID_SETUP.md`** (in this same folder).

Quick summary:
1. Tell Godot where your Android SDK is (`Editor Settings → Export → Android`)
2. Download Export Templates (`Editor → Manage Export Templates`)
3. `Project → Export → Add → Android → Export Project`
4. You get an `.apk` file
5. Install on your phone via USB or copy-paste

Total setup time: ~20 minutes (one-time). After that, every rebuild takes ~30 seconds.

### Mobile Controls
| Action | Touch |
|---|---|
| Move | Virtual joystick (bottom-left) |
| Look around | Swipe right half of screen |
| Jump | JUMP button (bottom-right) |
| Run | RUN button (hold) |
| Enter/Exit vehicle | ENTER/EXIT button (appears near car) |
| Switch character | SWITCH button (top-right) |
| Fire (placeholder) | FIRE button (right side) |

---

## Project Structure

```
gta-game/
├── project.godot           # Engine config + input mappings + Android export settings
├── icon.svg                # App icon
├── README.md               # This file
├── ANDROID_SETUP.md        # Step-by-step Android APK build guide
├── scenes/
│   ├── main.tscn           # Main game scene (PC UI + Mobile UI + World + Players + Car)
│   ├── player.tscn         # Player character scene
│   └── car.tscn            # Drivable car scene
├── scripts/
│   ├── player.gd           # Player movement (works for both keyboard + touch)
│   ├── player_manager.gd   # Switching between Marcus and Maya
│   ├── car.gd              # Vehicle physics + enter/exit
│   ├── world.gd            # Generates the city (roads, buildings, props)
│   ├── main.gd             # Game loop + platform detection + mobile UI control
│   ├── virtual_joystick.gd # Touch joystick logic
│   ├── mobile_button.gd    # Touch action buttons (auto-fires input events)
│   └── input_manager.gd    # Bridge between touch and keyboard input
└── assets/
    ├── models/             # (Empty - add real 3D models here later)
    ├── audio/              # (Empty - add sound effects + music here)
    └── textures/           # (Empty - add textures here)
```

---

## Car Brands (Fictional — GTA-style)

We use fictional names for all real cars to avoid trademark issues:

| Real car inspiration | In-game name (placeholder) |
|---|---|
| Porsche 911 | "Comet" (GTA's name) |
| Bugatti Veyron | "Adder" (GTA's name) |
| Lamborghini Aventador | "Vacca" |
| Ferrari 458 | "Turismo" |
| BMW M5 | "Oracle" |
| Koenigsegg | "Banshee 900R" |
| Ford Mustang (muscle) | "Dominic" |
| Dodge Charger (muscle) | "Buffalo" |

All renameable in code (`car_brand` property on each car instance).

---

## Built With

- **Godot 4.x** — Free, open-source game engine. Zero royalties, zero license fees.
- **GDScript** — Python-like scripting language.

All code is yours. Modify it, sell it, give it away — no restrictions.

---

## Phase 2 Roadmap (What We Build Next)

After you confirm Phase 1 runs on both PC and Android:

1. **Real 3D models** — Replace capsule + box with Mixamo characters and Kenney cars (free assets)
2. **Bigger map** — Expand `world.gd` to generate multiple districts (start of Los Santos style)
3. **More cars** — Multiple vehicles with different speeds/handling
4. **Building interiors** — Load interior scenes when entering certain buildings
5. **Save system** — Save player position, character, money to disk
6. **Day/night cycle** — Rotate sun, change sky color over time
7. **Gun system** — Pick up weapons, aim, shoot, reload
8. **Police + wanted stars** — AI cops that chase you, escalate with crimes
9. **Money + economy** — Earn from missions, spend on cars/weapons
10. **Story missions** — Meet NPCs (Woozie/Truth/Tenpenny-style characters), get missions, complete objectives
