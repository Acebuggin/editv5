# QB-Radialmenu Integration with RPEmotes Hands Up

## Overview
This guide explains how to make qb-radialmenu's rob feature work with rpemotes hands up system.

## What Was Added

### State Bags
RPEmotes now sets these state bags when hands are up:
- `LocalPlayer.state.currentEmote = 'handsup'` (original)
- `LocalPlayer.state.handsup = true` (QB compatibility)

### Exports Available
You can check if a player has their hands up using any of these methods:

```lua
-- Method 1: Using state bags (recommended for QB)
local hasHandsUp = LocalPlayer.state.handsup

-- Method 2: Using rpemotes export
local hasHandsUp = exports['rpemotes']:IsPlayerInHandsUp()

-- Method 3: Using QB-style export
local hasHandsUp = exports['rpemotes']:handsup()

-- Method 4: Alternative export
local hasHandsUp = exports['rpemotes']:isHandsup()
```

## Modifying qb-radialmenu

If your qb-radialmenu still doesn't detect hands up, you may need to modify it. Look for the rob feature in qb-radialmenu and find where it checks for hands up. It might look something like:

```lua
-- Old QB check (might not work)
if IsEntityPlayingAnim(ped, "missminuteman_1ig_2", "handsup_enter", 3) then
    -- allow rob
end
```

Replace it with:

```lua
-- New check using rpemotes
if LocalPlayer.state.handsup or exports['rpemotes']:IsPlayerInHandsUp() then
    -- allow rob
end
```

## For Server-Side Checks

If you need to check another player's hands up state server-side:

```lua
-- Server-side check
local targetPlayer = GetPlayerPed(targetSource)
local targetState = Player(targetSource).state

if targetState.handsup or targetState.currentEmote == 'handsup' then
    -- Player has hands up, allow rob
end
```

## Common QB-Radialmenu Files to Check

1. `qb-radialmenu/client/main.lua` - Look for the rob option
2. `qb-radialmenu/config.lua` - Check if there's a hands up animation defined
3. Any robbery-related scripts that interact with the radial menu

## Testing

1. Have Player A do `/handsup` or press the hands up key (Y by default)
2. Have Player B open radial menu and try to rob
3. The rob option should now be available

## Troubleshooting

If it still doesn't work:
1. Enable debug prints in rpemotes config
2. Check F8 console for the hands up state
3. Make sure both resources are started in correct order (rpemotes before qb-radialmenu)
4. Check if qb-radialmenu has been modified from default

## Animation Names

RPEmotes uses this animation for hands up:
- Dict: `random@mugging3`
- Anim: `handsup_standing_base`

If qb-radialmenu is checking for specific animations, it needs to check for these.