
name "legends-pelts"
author "LEGENDS - CODE101"
description "Legends Pelts"


game 'rdr3'
fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 "yes"

escrow_ignore {
    'shared/config.lua',
    'languages/*.lua'
}

client_scripts {
    'client/c-main.lua',
    'client/menu.lua',
}

server_scripts {
    'server/s-main.lua',
}

shared_scripts {
    'shared/config.lua',
    'locale.lua',
    'languages/*.lua'
}

dependency {
    'vorp_core',
    'vorp_utils',
    'vorp_inventory',
    'feather-menu',
    'feather-progressbar',
}

version '1.0.2'
vorp_checker 'yes'
vorp_name '^4Resource version Check^3'