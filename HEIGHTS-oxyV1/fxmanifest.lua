fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'HEIGHTS'
description 'HEIGHTS-oxyV1 - Advanced Oxy Delivery System'
version '1.0.0'

dependencies {
	'PolyZone',
	'ox_lib',
	'qb-core',
	'qb-vehiclekeys'
}

shared_scripts {
	'@ox_lib/init.lua',
	'shared/sh_config.lua'
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/CircleZone.lua',
	'client/cl_main.lua'
}

server_script 'server/sv_main.lua'