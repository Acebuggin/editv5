# RPEmotes Prop Persistence Feature Documentation

This document details all the changes made to implement prop persistence when aiming, putting hands up, and pointing.

## Overview

The prop persistence feature allows players to keep their prop attachments (like cigars, phones, etc.) when performing certain actions that would normally remove them.

## Configuration Options

In `rpemotes/config.lua`, the following options were added:

```lua
-- Prop Persistence Options
KeepPropsWhenAiming = true,    -- If true, props will not be removed when aiming a weapon
KeepPropsWhenHandsUp = true,   -- If true, props will not be removed when putting hands up
KeepPropsWhenPointing = true,  -- If true, props will not be removed when pointing

-- Debug Options
EnableDebugPrints = true,      -- Enable/disable debug prints for troubleshooting
```

## Files Modified

### 1. **rpemotes/config.lua**
- Added configuration options for prop persistence
- Added debug print option

### 2. **rpemotes/client/Emote.lua**
This is the main file with the most changes:

#### Key Changes:
- Added global variables for prop storage and tracking
- Created prop storage and recreation system
- Modified aiming detection to preserve props
- Added monitoring thread for automatic prop recreation
- Enhanced debug logging throughout

#### New Functions Added:
- `StorePropsInfo()` - Stores current prop information before it's lost
- `RecreateStoredProps()` - Recreates props from stored information

#### Modified Functions:
- `runAnimationThread()` - Added aiming detection with prop preservation
- `DestroyAllProps()` - Added checks to skip destruction when preserving props
- `OnEmotePlay()` - Added logic to preserve props when replaying emotes

#### Key Code Sections:

**Aiming Detection (around line 191):**
```lua
if IsPlayerAiming(pPed) then
    if Config.KeepPropsWhenAiming and #PlayerProps > 0 then
        -- Store props, clear animation, recreate props if needed
    else
        EmoteCancel()
    end
end
```

**Prop Monitoring Thread (around line 78):**
- Continuously monitors prop state
- Detects when props disappear and recreates them
- Special handling for hands up state changes

### 3. **rpemotes/client/Handsup.lua**

#### Key Changes:
- Added prop preservation during hands up/down cycle
- Extensive prop recreation logic after hands up animation
- Added detection for detached props
- Multiple fallback methods for prop recreation

#### Modified Sections:
- `Handsup()` function - Added prop storage and recreation logic
- Hands down sequence - Added preservation flag and debug logging

#### Key Code:
```lua
-- When putting hands up
if Config.KeepPropsWhenHandsUp then
    -- Store props before animation
    -- Play hands up animation
    -- Recreate props after animation starts
end

-- When putting hands down
if Config.KeepPropsWhenHandsUp then
    -- Set preservation flag
    -- Keep props during emote replay
end
```

### 4. **rpemotes/client/Pointing.lua**

#### Key Changes:
- Added config checks before destroying props
- Two locations modified where `DestroyAllProps()` was called

#### Modified Code:
```lua
-- Instead of always destroying props:
if not Config.KeepPropsWhenPointing then
    DestroyAllProps()
else
    DebugPrint("Keeping props while pointing")
end
```

### 5. **rpemotes/client/Utils.lua**

#### Key Changes:
- Modified `DebugPrint()` to also check `Config.EnableDebugPrints`
- Added timestamp to debug output

#### Modified Function:
```lua
function DebugPrint(...)
    if Config.DebugDisplay or Config.EnableDebugPrints then
        print("[" .. GetGameTimer() .. "]", ...)
    end
end
```

### 6. **rpemotes/client/Keybinds.lua**

#### Key Changes:
- Fixed cancel keybind to properly respect `EnableCancelKeybind` config
- Wrapped command registration in config check

## How It Works

### For Aiming:
1. When player aims, the system stores current prop information
2. Clears the animation (which may remove props)
3. Checks if props were actually removed
4. If removed, recreates them from stored information

### For Hands Up:
1. Stores prop information before hands up animation
2. Plays hands up animation (which forces prop removal)
3. Detects that props are detached from player
4. Destroys detached props and recreates them attached to player
5. When hands go down, preserves props during emote replay

### For Pointing:
1. Simple config check before destroying props
2. If config is true, skips the destruction entirely

## Technical Details

### Global Variables Added:
- `StoredPropsInfo` - Temporary storage for current prop info
- `LastValidPropInfo` - Persistent backup of last known good prop info
- `PreservingHandsUpProps` - Flag to prevent prop destruction during hands up
- `WasInHandsup` - Tracks hands up state changes

### Prop Recreation Process:
1. Props are stored with their model, position, rotation, and texture variation
2. When recreation is needed, the system:
   - Restores the stored animation options
   - Calls `addProps()` to recreate the prop
   - Restores original animation state

### Debug Output:
With `EnableDebugPrints = true`, you'll see:
- When props are stored/destroyed/recreated
- Prop counts and attachment status
- Stack traces for debugging
- Detailed state information during transitions

## Usage

1. Set the desired options to `true` in `config.lua`
2. Restart the resource
3. Props will now persist during the configured actions
4. Enable debug prints to troubleshoot any issues

## Notes

- Some props may briefly disappear (100-200ms) before being recreated
- The hands up animation forcefully removes props, so recreation is necessary
- Aiming and pointing typically don't force prop removal, just prevent it
- The monitoring thread provides a safety net for edge cases