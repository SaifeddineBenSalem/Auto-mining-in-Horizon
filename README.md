# ⛏️ StartDJob

> **Automated mining-route assistant for SA-MP using MoonLoader Lua**

StartDJob is a lightweight Lua automation script designed for **SA-MP (San Andreas Multiplayer)** environments running through **MoonLoader**.

The script automates a predefined mining route by navigating the player between configured coordinates, controlling forward movement and sprinting, detecting when the player becomes stuck, performing recovery actions, and executing the `/mine` command at designated mining locations.

---

## 📸 Overview

StartDJob is designed around a simple automated workflow:

```text
┌──────────────────────┐
│      /startdjob      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Validate Player    │
│   State / SA-MP      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Navigate to Mining   │
│      Location        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│      /mine           │
│    Wait 12 Seconds   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Follow Route Points  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Return to Mining     │
│      Location        │
└──────────┬───────────┘
           │
           └──────────────► Repeat
```

The navigation system uses the player's position and camera orientation to continuously steer toward the next destination.

---

# ✨ Features

## 🤖 Automated Mining Route

StartDJob automatically follows a predefined sequence of coordinates.

Each route point can optionally be marked as a mining location:

```lua
{x = 2747.5422, y = -2077.5195, z = 13.2797, mine = true}
```

When the script reaches a point containing:

```lua
mine = true
```

it automatically executes:

```text
/mine
```

and waits for the configured mining duration.

---

## 🧭 Camera-Based Navigation

The script does not use strafe controls to navigate.

Instead, it:

1. Calculates the direction toward the destination.
2. Reads the current camera yaw.
3. Calculates the angular difference.
4. Gradually rotates the camera.
5. Starts moving forward once the camera is sufficiently aligned.

This is handled by:

```lua
steerCameraToward()
```

and:

```lua
driveMovement()
```

The gradual camera rotation helps prevent abrupt turning.

---

## 🏃 Automatic Running

Once the player is facing sufficiently close to the destination, the script automatically holds:

* Forward movement
* Sprint

The relevant controls are:

```lua
setGameKeyState(KEY_FORWARD_BACK, 128)
setGameKeyState(KEY_SPRINT, 255)
```

The script intentionally avoids strafing because strafing-based navigation can cause circular movement.

---

# 🛠️ Stuck Detection & Recovery

StartDJob includes an automatic stuck detector.

The script periodically compares the player's current position against their previous position.

If movement falls below:

```lua
STUCK_MOVE_MIN
```

for a sufficient number of consecutive checks:

```lua
STUCK_TICKS
```

the script considers the player stuck.

### Recovery sequence

The recovery system:

1. Releases movement controls.
2. Waits briefly.
3. Performs a jump.
4. Moves backward.
5. Stops movement.
6. Resumes navigation.

The recovery logic is implemented in:

```lua
doStuckRecovery()
```

This makes the route more resilient to minor environmental obstacles.

---

# 🎯 Arrival Detection

A destination is considered reached when the player's 2D distance from the target is within:

```lua
ARRIVAL_THRESHOLD = 1.5
```

The script uses:

```lua
getDistanceBetweenCoords2d()
```

rather than requiring an exact coordinate match.

This is important because the player's actual position will rarely be exactly identical to the configured route coordinate.

---

# ⛏️ Mining Automation

When a route point is marked:

```lua
mine = true
```

the navigation system stops and the script sends:

```text
/mine
```

The default mining delay is:

```lua
MINE_WAIT_MS = 12000
```

which equals:

```text
12 seconds
```

The mining procedure also checks whether a SA-MP dialog is currently active before sending the command.

---

# 🗺️ Current Route

The configured route currently contains the following points:

|  # |         X |          Y |       Z | Action   |
| -: | --------: | ---------: | ------: | -------- |
|  1 | 2747.5422 | -2077.5195 | 13.2797 | ⛏️ Mine  |
|  2 | 2785.6809 | -2060.8982 | 11.8509 | Navigate |
|  3 | 2787.5459 | -2069.8757 | 11.7665 | Navigate |
|  4 | 2794.3298 | -2071.0779 | 11.5810 | Navigate |
|  5 | 2786.2874 | -2070.1436 | 11.7928 | Navigate |
|  6 | 2785.2290 | -2063.8965 | 11.8567 | Navigate |
|  7 | 2747.8608 | -2077.3699 | 12.9241 | Return   |

The route can be modified directly inside the `ROUTE` table.

---

# ⚙️ Configuration

All major navigation parameters are defined near the beginning of the script.

```lua
local ARRIVAL_THRESHOLD = 1.5
local MINE_WAIT_MS = 12000
local STUCK_MOVE_MIN = 0.08
local STUCK_TICKS = 60
local CAMERA_TURN_STEP = 0.04
local CAMERA_YAW_OFFSET = 0.04253
local RUN_ANGLE_LIMIT = 0.30
```

## `ARRIVAL_THRESHOLD`

Controls how close the player needs to be to a destination before it is considered reached.

Default:

```lua
1.5
```

Smaller values require more precise positioning.

---

## `MINE_WAIT_MS`

Controls how long the script waits after executing `/mine`.

Default:

```lua
12000
```

Equivalent to:

```text
12 seconds
```

---

## `STUCK_MOVE_MIN`

Minimum amount of movement required to avoid being considered stationary.

Default:

```lua
0.08
```

---

## `STUCK_TICKS`

Number of consecutive low-movement checks required before recovery is triggered.

Default:

```lua
60
```

The navigation loop checks approximately every:

```lua
50 ms
```

Therefore, the theoretical detection period is roughly:

```text
60 × 50 ms ≈ 3 seconds
```

---

## `CAMERA_TURN_STEP`

Controls how quickly the camera rotates toward the target.

Default:

```lua
0.04
```

Higher values produce faster camera rotation.

---

## `CAMERA_YAW_OFFSET`

Compensates for the relationship between the calculated world direction and the game's camera orientation.

Default:

```lua
0.04253
```

This value is intentionally kept separate from the main navigation logic so it can be tuned independently.

---

## `RUN_ANGLE_LIMIT`

Determines how closely the camera must be aligned before forward movement begins.

Default:

```lua
0.30
```

The player only starts running when:

```text
absolute(angle error) ≤ 0.30
```

---

# 🎮 Commands

## Start the automation

```text
/startdjob
```

Starts the mining route.

The script displays:

```text
[StartDJob] Mining route started.
```

If the job is already running, another instance is not created.

---

## Stop the automation

```text
/stopdjob
```

Immediately requests the route to stop.

The script:

* Stops navigation.
* Releases movement controls.
* Releases sprint.
* Releases jump.
* Stops the worker loop.

---

# 🧠 Architecture

The script is divided into several logical systems.

```text
StartDJob
│
├── Initialization
│   └── main()
│
├── Job Control
│   ├── startdjob()
│   └── stopdjob()
│
├── Worker
│   └── djobWorker()
│
├── Player Validation
│   └── isPlayerReady()
│
├── Navigation
│   ├── runToPosition()
│   ├── steerCameraToward()
│   └── driveMovement()
│
├── Camera System
│   ├── getCameraYawPitch()
│   └── normalizeAngleRad()
│
├── Recovery
│   └── doStuckRecovery()
│
└── Mining
    └── sendMineCommand()
```

---

# 🔄 Execution Flow

When MoonLoader loads the script:

```text
MoonLoader
    │
    ▼
main()
    │
    ├── Wait for SA-MP
    │
    ├── Register commands
    │
    └── Start main control loop
```

When `/startdjob` is executed:

```text
/startdjob
    │
    ▼
jobRunning = true
    │
    ▼
Create dj​obWorker thread
    │
    ▼
Read ROUTE
    │
    ▼
runToPosition()
    │
    ├── Check player
    ├── Calculate distance
    ├── Detect stuck state
    ├── Rotate camera
    └── Move forward
    │
    ▼
Destination reached
    │
    ▼
Is this a mining point?
    │
    ├── No → Continue
    │
    └── Yes
          │
          ▼
       /mine
          │
          ▼
      Wait 12 sec
          │
          ▼
     Continue route
```

---

# 🧵 Threading

The main MoonLoader thread remains responsive while the mining route executes in a separate Lua thread.

The worker is started using:

```lua
lua_thread.create(djobWorker)
```

This allows the route logic to yield using:

```lua
wait()
```

without blocking the primary script loop.

The main loop remains responsible for applying movement controls while navigation is active.

---

# 🔐 State Management

The script uses several state variables.

### `jobRunning`

Determines whether the mining job is currently active.

```lua
local jobRunning = false
```

---

### `stopRequested`

Signals that the current job should terminate.

```lua
local stopRequested = false
```

---

### `keysHeld`

Tracks whether movement controls are currently being applied.

```lua
local keysHeld = false
```

This prevents unnecessary repeated release operations.

---

### `nav`

Stores the currently active navigation destination:

```lua
local nav = {
    active = false,
    tx = 0.0,
    ty = 0.0,
    tz = 0.0,
}
```

This separates navigation state from the route worker.

---

# 🛡️ Player Safety Checks

Before movement is applied, the script verifies that:

* SA-MP is loaded.
* SA-MP is available.
* The player character exists.
* The player is alive.
* The player is currently on foot.

Implemented by:

```lua
isPlayerReady()
```

This prevents movement commands from being continuously applied when the player is not in an appropriate state.

---

# 📁 Installation

## Requirements

You need:

* GTA: San Andreas
* SA-MP
* MoonLoader
* Lua script support through MoonLoader

The script is intended to run as a MoonLoader `.lua` script.

---

## Installation Steps

### 1. Locate your MoonLoader folder

Typically:

```text
GTA San Andreas/
└── moonloader/
```

### 2. Create the script

Save the script as:

```text
StartDJob.lua
```

### 3. Place it inside:

```text
GTA San Andreas/moonloader/
```

Your structure should look similar to:

```text
GTA San Andreas/
│
├── moonloader/
│   ├── StartDJob.lua
│   └── ...
│
└── ...
```

### 4. Start GTA: San Andreas

Launch SA-MP normally.

Once SA-MP becomes available, the script should display:

```text
[StartDJob] Loaded - use /startdjob | stop with /stopdjob
```

---

# 🚀 Usage

After joining the relevant SA-MP environment:

### Start

```text
/startdjob
```

The script will begin following the configured route.

### Stop

```text
/stopdjob
```

The script will immediately request navigation shutdown and release movement controls.

---

# 🧩 Customizing the Route

The easiest way to create another route is to modify:

```lua
local ROUTE = {
    ...
}
```

Each point follows this format:

```lua
{
    x = 1000.0,
    y = 2000.0,
    z = 10.0
}
```

A mining point can be created with:

```lua
{
    x = 1000.0,
    y = 2000.0,
    z = 10.0,
    mine = true
}
```

For example:

```lua
local ROUTE = {
    {x = 1000.0, y = 2000.0, z = 10.0, mine = true},
    {x = 1010.0, y = 2010.0, z = 10.0},
    {x = 1020.0, y = 2020.0, z = 10.0},
    {x = 1000.0, y = 2000.0, z = 10.0},
}
```

---

# 🧪 Technical Details

## Coordinate System

The navigation system operates using GTA world coordinates:

```text
X
Y
Z
```

For horizontal navigation, the script primarily uses:

```text
X + Y
```

The Z coordinate is stored and passed through the navigation system, while arrival detection currently uses 2D distance.

---

## Angle Calculation

The destination direction is calculated using:

```lua
math.atan2(dy, dx)
```

The resulting target angle is compared against the camera yaw.

The difference is normalized using:

```lua
normalizeAngleRad()
```

This ensures the angle remains inside:

```text
[-π, π]
```

preventing unnecessary long rotations around the camera.

---

# 📐 Navigation Algorithm

The simplified navigation algorithm is:

```text
Get player position
        │
        ▼
Calculate dx / dy
        │
        ▼
Calculate target yaw
        │
        ▼
Read camera yaw
        │
        ▼
Calculate normalized angle difference
        │
        ▼
Rotate camera gradually
        │
        ▼
Is angle within allowed range?
        │
   ┌────┴────┐
   │         │
  NO        YES
   │         │
   ▼         ▼
Continue    Run
turning     forward
```

This approach avoids constantly moving forward while the player is facing the wrong direction.

---

# 🔧 Performance

The main control loop uses:

```lua
wait(0)
```

while navigation checks use:

```lua
wait(50)
```

This provides responsive movement control while avoiding unnecessary high-frequency route calculations.

The script is intentionally lightweight and does not continuously perform expensive operations.

---

# 🐛 Troubleshooting

## Script does not load

Verify that:

```text
StartDJob.lua
```

is located inside:

```text
moonloader/
```

Also verify that MoonLoader is correctly installed.

---

## `/startdjob` does nothing

Check whether SA-MP is fully loaded and the player is in a valid state.

The script requires:

```lua
isSampLoaded()
isSampAvailable()
doesCharExist(PLAYER_PED)
not isCharDead(PLAYER_PED)
isCharOnFoot(PLAYER_PED)
```

---

## Player gets stuck

The script has automatic recovery.

If the default recovery is insufficient for a particular route, the following values can be tuned:

```lua
STUCK_MOVE_MIN
STUCK_TICKS
```

You can also modify:

```lua
doStuckRecovery()
```

to implement a different recovery sequence.

---

## Player turns incorrectly

The camera behavior can be tuned using:

```lua
CAMERA_TURN_STEP
CAMERA_YAW_OFFSET
RUN_ANGLE_LIMIT
```

The most important value for compensating directional alignment is:

```lua
CAMERA_YAW_OFFSET
```

---

## Player starts running before properly facing the destination

Decrease:

```lua
RUN_ANGLE_LIMIT
```

For example:

```lua
local RUN_ANGLE_LIMIT = 0.20
```

This makes the script require tighter camera alignment before running.

---

# 📌 Important Limitations

StartDJob uses a **predefined coordinate route**.

It is not a full pathfinding system.

Therefore, it does not dynamically understand:

* Buildings
* Walls
* Dynamic obstacles
* Other players
* Vehicles
* Terrain changes
* Server-specific navigation restrictions

Its reliability depends heavily on the quality and stability of the configured route.

---

# ⚠️ Server Compatibility

This script is designed around a specific mining workflow and assumes that:

```text
/mine
```

is the appropriate command for the target environment.

Different SA-MP servers may use different:

* Commands
* Mining mechanics
* Coordinate systems
* Anti-cheat systems
* Movement restrictions
* Job mechanics
* Interaction requirements

Consequently, the route and command behavior may require adaptation for another server.

Always comply with the rules of the SA-MP server on which the script is used.

---

# 🔒 Multiplayer / Anti-Cheat Considerations

StartDJob is a client-side MoonLoader script that controls the local player's movement and sends the configured chat command.

Server environments can have their own rules and anti-cheat systems concerning automation.

Before using automation on a multiplayer server, verify that the server permits this type of script.

---

# 📜 Script Metadata

| Property                  | Value                                       |
| ------------------------- | ------------------------------------------- |
| **Script Name**           | StartDJob                                   |
| **Description**           | Automated mining route with on-foot running |
| **Version**               | 1.4                                         |
| **Author**                | StartDJob                                   |
| **Language**              | Lua                                         |
| **Platform**              | MoonLoader                                  |
| **Game**                  | GTA: San Andreas                            |
| **Multiplayer Framework** | SA-MP                                       |
| **Dependencies**          | MoonLoader / SA-MP environment              |

---

# 📂 Recommended Repository Structure

```text
StartDJob/
│
├── StartDJob.lua
├── README.md
├── LICENSE
│
└── screenshots/
    ├── loaded.png
    ├── route.png
    ├── mining.png
    └── terminal.png
```

For a polished GitHub repository, screenshots can be added to this README.

Example:

```markdown
## 📸 Screenshots

![Script Loaded](screenshots/loaded.png)

![Mining Route](screenshots/route.png)

![Mining](screenshots/mining.png)
```

---

# 🖼️ Suggested Screenshot Collection

For a professional GitHub presentation, consider capturing:

### 1. Script loaded

Show:

```text
[StartDJob] Loaded
```

### 2. Starting the job

Show:

```text
/startdjob
```

and the confirmation message.

### 3. Navigation

Capture the player while moving between route points.

### 4. Mining

Capture the mining location while `/mine` is being executed.

### 5. Route overview

If possible, provide an image showing the complete route.

### 6. Stuck recovery

A screenshot demonstrating the script recovering from an obstacle can also document the recovery system.

---

# 🗺️ Route Visualization

A future enhancement could provide a visual route map such as:

```text
                    Point 4
                      ●
                     /
              ●─────●
           Point 3  Point 5
              │
              │
Point 2 ●─────┘
        │
        │
        ● Point 1
       ⛏️
        │
        └───────────────● Point 7
                         ↩
```

This would make route configuration significantly easier for contributors.

---

# 🔮 Possible Future Improvements

Potential future enhancements include:

* [ ] Multiple configurable routes
* [ ] Route selection through SA-MP commands
* [ ] In-game route editor
* [ ] Automatic coordinate recording
* [ ] Route import/export
* [ ] Dynamic obstacle recovery
* [ ] Better path correction
* [ ] More advanced stuck detection
* [ ] Automatic route recalculation
* [ ] Configurable mining commands
* [ ] Configurable mining delays
* [ ] Multiple mining locations
* [ ] Route statistics
* [ ] Distance traveled tracking
* [ ] Runtime status display
* [ ] Automatic route pause/resume
* [ ] Configuration file support
* [ ] GUI configuration
* [ ] Route visualization
* [ ] More sophisticated navigation

---

# 🧑‍💻 Development

The project is intentionally structured into independent functions so individual systems can be modified without rewriting the entire script.

For example:

### Navigation

```lua
runToPosition()
steerCameraToward()
driveMovement()
```

### Recovery

```lua
doStuckRecovery()
```

### Mining

```lua
sendMineCommand()
```

### Job control

```lua
startdjob()
stopdjob()
djobWorker()
```

This modular structure makes future improvements easier to implement.

---

# 🤝 Contributing

Contributions and improvements are welcome.

When modifying the script:

1. Keep navigation logic separated from job logic.
2. Avoid unnecessary global variables.
3. Preserve the `/startdjob` and `/stopdjob` command behavior unless intentionally changing the API.
4. Test route modifications in-game.
5. Document new configuration values.
6. Avoid introducing unnecessary dependencies.
7. Keep recovery behavior safe and predictable.
8. Clearly document server-specific requirements.

---

# 📄 License

By Saifeddine Ben Salem **all rights reserved**.

---

# ⭐ Credits

**StartDJob**

Automated mining route and navigation system for SA-MP / MoonLoader.

```text
Version 1.4
Lua
MoonLoader
SA-MP
GTA: San Andreas
```

---

## 📊 Project Summary

StartDJob combines:

```text
┌───────────────────────────────────────────┐
│               StartDJob                   │
├───────────────────────────────────────────┤
│                                           │
│  🗺️ Predefined Route                     │
│            │                              │
│            ▼                              │
│  🧭 Camera-Based Navigation               │
│            │                              │
│            ▼                              │
│  🏃 Forward + Sprint Movement             │
│            │                              │
│            ▼                              │
│  📍 Arrival Detection                     │
│            │                              │
│            ▼                              │
│  ⛏️ Automated /mine Command               │
│            │                              │
│            ▼                              │
│  ⏱️ Mining Delay                          │
│            │                              │
│            ▼                              │
│  🛠️ Stuck Detection + Recovery            │
│            │                              │
│            └──────────► Repeat             │
│                                           │
└───────────────────────────────────────────┘
```

**StartDJob provides a compact, configurable route-automation framework built around MoonLoader's Lua scripting environment and GTA: San Andreas movement controls.**
