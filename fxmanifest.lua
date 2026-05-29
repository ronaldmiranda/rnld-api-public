fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
games { 'rdr3', 'gta5' }
lua54 'yes'
version '1.0.7'

escrow_ignore {
  'config.lua',
}

-- Caso utilize ox_lib ou utilize o framework qbcore, descomente a linha abaixo
shared_scripts {
  -- '@ox_lib/init.lua'
}

server_scripts {
  '@vrp/lib/utils.lua', -- caso não utilize vRP, remova essa linha
  -- '@vrp/lib/Utils.lua', -- Algumas Creatives usam Utils ao invés de utils
  'config.lua',
  'server.lua'
}

-- Anti-Spoofer: client script (JS) + NUI invisível que coleta o fingerprint do
-- Chromium embutido. Ativado por Config.AntiSpoofer.enabled (config.lua).
-- Em JS pra unificar a ofuscação com nui/app.js (um único ofuscador JS).
client_scripts {
  'client.js'
}

ui_page 'nui/index.html'

files {
  'nui/index.html',
  'nui/app.js'
}
