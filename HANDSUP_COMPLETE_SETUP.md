# Complete Handsup Integration Setup for QB-Core

This guide ensures 100% compatibility between rpemotes handsup and QB-Core scripts (especially qb-radialmenu).

## Files Created:
1. `qb-smallresources-handsup-bridge.lua` - Complete bridge for qb-smallresources compatibility
2. Updated `rpemotes/client/Handsup.lua` - Added all necessary exports and state synchronization

## Setup Instructions:

### Step 1: Install the Bridge File
```bash
# Copy the bridge file to your qb-smallresources
cp qb-smallresources-handsup-bridge.lua [your-server]/resources/qb-smallresources/client/handsup-bridge.lua
```

### Step 2: Update qb-smallresources fxmanifest.lua
Open `[your-server]/resources/qb-smallresources/fxmanifest.lua` and add:

```lua
client_scripts {
    'config.lua',
    'client/*.lua', -- This will include your new bridge file
}
```

### Step 3: Remove Old Handsup File (if exists)
If you have the old handsup.lua in qb-smallresources:
```bash
rm [your-server]/resources/qb-smallresources/client/handsup.lua
```

### Step 4: Update Server Start Order
In your `server.cfg`, ensure this order:
```
ensure qb-core
ensure rpemotes
ensure qb-smallresources  
ensure qb-radialmenu
```

### Step 5: Clear Cache and Restart
1. Clear your server cache
2. Restart the server
3. Clear your FiveM client cache

## What This Setup Provides:

1. **Full Export Compatibility** - All these exports work:
   - `exports['qb-smallresources']:getHandsup()`
   - `exports['qb-smallresources']:handsup()`
   - `exports['qb-smallresources']:isHandsup()`
   - `exports['qb-smallresources']:IsPlayerInHandsUp()`

2. **Statebag Synchronization** - `LocalPlayer.state.handsup` is synchronized

3. **Global Variable Support** - The `handsUp` global variable is maintained for older scripts

4. **Event Support** - Triggers `qb-smallresources:client:handsup:changed` event

5. **Real-time Updates** - State changes are detected and synchronized within 50-100ms

## Testing:

1. Put your hands up (default key: X)
2. Have another player approach you
3. They should see the "Rob" option in their radial menu
4. The robbery should work as expected

## Troubleshooting:

### If the rob option doesn't appear:

1. **Check Console for Errors**
   - Look for any export errors
   - Check if the bridge loaded (you should see "Handsup bridge loaded" message)

2. **Verify Export is Working**
   - Run this command in F8 console:
   ```lua
   print(exports['qb-smallresources']:getHandsup())
   ```
   - Should print `true` when hands are up, `false` when down

3. **Check qb-radialmenu Code**
   - Some versions might use different export names
   - Search for `handsup` in qb-radialmenu files
   - Update the export call if needed

### Alternative: Direct Modification

If the bridge doesn't work, you can modify qb-radialmenu directly:

1. Find this line in qb-radialmenu (usually in `client/main.lua`):
   ```lua
   if exports['qb-smallresources']:getHandsup() then
   ```

2. Replace with:
   ```lua
   if exports['rpemotes']:getHandsup() then
   ```

## Debug Mode:

To enable debug messages, set in your rpemotes config:
```lua
DebugDisplay = true
```

This will show when hands go up/down and help diagnose issues.