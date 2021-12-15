fx_version 'bodacious'
game 'gta5'

author 'BR'
description 'A Full Featured FiveM Gang System'
repository 'https://github.com/BehnamRt/FiveM_GangSystem'

server_scripts {
    '@essentialmode/locale.lua',
    '@mysql-async/lib/MySQL.lua',
    'locales/en.lua',
    'config.lua',
    'server/main.lua'
}

client_scripts {
    '@essentialmode/locale.lua',
    'locales/en.lua',
    'config.lua',
    'client/main.lua'
}

dependencies {
    'essentialmode',
    'mysql-async'
}