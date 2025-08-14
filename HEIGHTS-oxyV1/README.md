# HEIGHTS-oxyV1

Advanced Oxy Delivery System for QBCore Framework

## Features

- **Unlimited Deliveries**: Players can complete as many deliveries as they want until they decide to return the vehicle
- **Vehicle Registration System**: Each run assigns a specific vehicle that only the player can use for deliveries
- **Random Vehicle Selection**: Different vehicle models are randomly selected for each run
- **ox_lib Integration**: Uses ox_lib's textui system for clean interactions
- **Markedbills Rewards**: Players receive 1000-10000 markedbills per delivery
- **Vehicle Return System**: Players can end their run by returning the vehicle to the spawn location

## Dependencies

- QBCore Framework
- ox_lib
- PolyZone
- qb-vehiclekeys

## Installation

1. Download the script and place it in your resources folder
2. Ensure you have all dependencies installed
3. Add `ensure HEIGHTS-oxyV1` to your server.cfg
4. Restart your server

## Configuration

Edit `shared/sh_config.lua` to customize:

- `Config.StartLocation` - Where players start the oxy runs
- `Config.StartOxyPayment` - Initial payment required to start
- `Config.VehicleModels` - List of random vehicle models
- `Config.MarkedBillsMin/Max` - Markedbills reward range
- `Config.OxyChance` - Chance to receive oxy item
- `Config.Locations` - Delivery locations

## How It Works

1. Players go to the start location and press [E] to begin
2. They pay the initial fee and receive a random vehicle
3. Only when in the registered vehicle will delivery locations appear
4. Players complete deliveries to receive markedbills and possibly oxy
5. To end the run, they return the vehicle to the spawn location

## Credits

Created by HEIGHTS