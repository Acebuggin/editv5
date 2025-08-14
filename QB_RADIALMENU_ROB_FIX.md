# QB-Radialmenu Rob Function Fix

## The Problem
The "Rob" option in qb-radialmenu wasn't appearing because it was looking for the handsup state from qb-smallresources, which you removed.

## The Solution
I've modified the qb-radialmenu config to check for hands up in multiple ways:

1. **Player State Check** - Checks `Player.state.handsup` (set by rpemotes)
2. **Animation Check** - Checks if the target is playing the hands up animation
3. **Distance Check** - Ensures you're close enough to the target

## What Was Changed

### In `qb-radialmenu/config.lua`:
Added a `canOpen` function to the rob option that:
- Gets the closest player within 2.5 units
- Checks if they have their hands up using state or animation
- Only shows the rob option if they do

## Testing Instructions

1. **Restart qb-radialmenu**:
   ```
   ensure qb-radialmenu
   ```

2. **Test with two players**:
   - Player 1: Press X to put hands up
   - Player 2: Get close and open radial menu
   - The "Rob" option should now appear under the people menu

3. **Debug Commands**:
   Use the test script to verify exports:
   ```
   /testhandsup
   ```

## If It Still Doesn't Work

1. **Check F8 Console** for any errors when opening the radial menu

2. **Verify State Sync**:
   In F8 console while hands are up:
   ```lua
   print(LocalPlayer.state.handsup)
   ```
   Should print `true`

3. **Check Animation**:
   The hands up animation dict is `random@mugging3` and anim is `handsup_standing_base`

4. **Alternative Fix**:
   If the state isn't syncing properly, you can modify the canOpen function to only use animation check:
   ```lua
   canOpen = function(itemData)
       local player, distance = QBCore.Functions.GetClosestPlayer()
       if player ~= -1 and distance < 2.5 then
           local playerPed = GetPlayerPed(player)
           return IsEntityPlayingAnim(playerPed, "random@mugging3", "handsup_standing_base", 3)
       end
       return false
   end
   ```

## How It Works Now

1. When a player puts their hands up, rpemotes sets `LocalPlayer.state.handsup = true`
2. This state is networked to other players
3. When another player opens their radial menu near someone with hands up
4. The `canOpen` function checks the state and/or animation
5. If hands are up, the rob option appears

## Additional Notes

- The rob event `police:client:RobPlayer` is handled by qb-policejob or similar resource
- Make sure that resource is also running for the actual rob functionality to work
- The state sync happens in real-time, so the rob option should appear/disappear dynamically