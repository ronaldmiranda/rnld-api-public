fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
games { 'rdr3', 'gta5' }
lua54 'yes'
version '1.0.6'

escrow_ignore {
  'config.lua',
}

-- Caso utilize ox_lib ou utilize o framework qbcore, descomente a linha abaixo
shared_scripts {
  -- '@ox_lib/init.lua'
}

server_scripts {
  '@vrp/lib/utils.lua', -- caso não utilize vRP, remova essa linha
  'config.lua',
  'server.lua'
}
