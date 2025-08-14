# Handsup Bridge Setup for QB-Radialmenu Compatibility

Since you removed the handsup functionality from qb-smallresources and are now using rpemotes for handsup, you need to set up a bridge so qb-radialmenu can still detect when players have their hands up.

## Setup Instructions:

1. **Copy the bridge file to qb-smallresources:**
   ```bash
   cp bridge_handsup.lua [your-server]/resources/qb-smallresources/client/
   ```

2. **Add the bridge file to qb-smallresources fxmanifest.lua:**
   
   Open `qb-smallresources/fxmanifest.lua` and add this line to the client scripts:
   ```lua
   client_scripts {
       -- ... other client scripts ...
       'client/bridge_handsup.lua',
   }
   ```

3. **Ensure rpemotes starts before qb-radialmenu:**
   
   In your server.cfg, make sure the start order is:
   ```
   ensure rpemotes
   ensure qb-smallresources
   ensure qb-radialmenu
   ```

## How it works:

- The bridge file creates the `qb-smallresources:getHandsup` export that qb-radialmenu expects
- It redirects all handsup checks to rpemotes
- This way, qb-radialmenu can detect when a player has their hands up without any modifications

## Testing:

1. Restart your server
2. Use the handsup keybind (X by default)
3. Have another player try to rob you using the radial menu
4. The rob option should now appear when you have your hands up

## Alternative Solution:

If you prefer not to use the bridge, you can modify qb-radialmenu directly to check rpemotes instead of qb-smallresources. Look for this line in qb-radialmenu:
```lua
exports['qb-smallresources']:getHandsup()
```

And replace it with:
```lua
exports['rpemotes']:getHandsup()
```