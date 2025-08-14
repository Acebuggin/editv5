fx_version 'cerulean'
game 'gta5'

description 'Ace Drug script'
author 'ACEBEENBUGGIN'
version '2.0.0'

shared_script '@ox_lib/init.lua'
shared_script 'config.lua'

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_inventory',
    'qb-core',
    'ox_lib'
}
