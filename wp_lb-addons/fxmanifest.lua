fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Web-portal'
dependency 'lb-phone'

files {
    'ui/donate-overlay.js'
}

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}
