# HEIGHTS-oxyV1 & HEIGHTS-selldrugs Integration

This document explains the integration between HEIGHTS-oxyV1 and HEIGHTS-selldrugs that prevents players from selling drugs to oxy delivery peds.

## Overview

The integration ensures that peds used for oxy deliveries in HEIGHTS-oxyV1 cannot be targeted for drug sales in HEIGHTS-selldrugs. This prevents conflicts and maintains immersion by keeping the two systems separate.

## How It Works

### HEIGHTS-oxyV1 Exports

Three new exports have been added to HEIGHTS-oxyV1:

1. **GetOxyDeliveryPed()**
   - Returns the current oxy delivery ped entity
   - Returns `nil` if no delivery is active

2. **IsOxyDeliveryPed(ped)**
   - Checks if a specific ped is the current oxy delivery ped
   - Parameters: `ped` - The ped entity to check
   - Returns: `boolean` - true if the ped is an oxy delivery ped

3. **GetOxyDeliveryData()**
   - Returns comprehensive data about the current oxy delivery
   - Returns a table with:
     - `isActive` - Whether an oxy run is currently active
     - `hasPed` - Whether a delivery ped exists
     - `ped` - The ped entity (or nil)
     - `madeDeal` - Whether the deal has been completed

### HEIGHTS-selldrugs Modifications

The drug selling script now checks if a ped is an oxy delivery ped before allowing sales:

1. **Ped Scanning** - When scanning for potential customers, oxy delivery peds are excluded
2. **Sale Attempt** - Double-checks when attempting to sell, showing "This person is busy with another transaction" if it's an oxy ped

## Implementation Details

### Export Usage Example

```lua
-- Check if a ped is an oxy delivery ped
local isOxyPed = exports['HEIGHTS-oxyV1']:IsOxyDeliveryPed(ped)
if isOxyPed then
    -- Don't allow drug sales to this ped
    return
end
```

### Resource State Check

The integration includes resource state checking to prevent errors:

```lua
if GetResourceState('HEIGHTS-oxyV1') == 'started' then
    -- Safe to use exports
end
```

## Testing

A test script is included (`test_oxy_selldrugs_integration.lua`) that can be used to verify the integration:

1. Run the command `/testoxysell` in-game
2. The script will test all exports and show their status
3. To fully test the integration:
   - Start an oxy delivery run
   - Approach the delivery ped
   - Attempt to sell drugs - you should see "This person is busy with another transaction"

## Troubleshooting

### Common Issues

1. **"attempt to call a nil value" error**
   - Ensure HEIGHTS-oxyV1 is started before HEIGHTS-selldrugs
   - The resource state check should prevent this

2. **Can still sell to oxy peds**
   - Verify both scripts are the updated versions
   - Check that exports are properly defined in HEIGHTS-oxyV1
   - Ensure no other scripts are interfering

3. **Performance concerns**
   - The export calls are lightweight and only check entity comparison
   - Resource state is checked to avoid unnecessary export calls

## Benefits

- **No Conflicts** - Players can't accidentally sell drugs to their oxy customers
- **Better Immersion** - Keeps the two criminal activities separate
- **Clean Implementation** - Uses FiveM's native export system
- **Error Handling** - Includes resource state checking to prevent errors
- **User Feedback** - Clear message when attempting to sell to oxy peds