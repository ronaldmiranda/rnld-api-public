-- caso use vRP, descomente as linhas abaixo
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")

-- caso use VorpCore, descomente as linhas abaixo
-- VorpCore = {}
-- TriggerEvent("getCore", function(core)
--   VorpCore = core
-- end)

-- caso use qbcore, descomente as linhas abaixo
-- local QBCore = exports['qb-core']:GetCoreObject()

Config = {
  guildId = "",          -- id do seu servidor discord
  discordIdMock = false, -- Se true, irá usar um ID de Discord fictício
  fakeDiscordId = "",    -- ID de Discord fictício
  appKey = "",           -- Chave da API
  framework = "vrp",     -- Framework utilizado ( vrp, creative, creative-network, qbcore, vorpcore)

  -- Ativa as funcionalidades da Whitelist Remota
  BaseMode = "discord", --Configura qual licença será exigida pelo script, discord, steam ou license
  Whitelist = true      -- Ativa o modo de whitelist utilizando nossa API, será necessario desabilitar a whitelist da sua base.
}

rnld = {
  -- frameworks como vRP e Creative não são padronizadas no mercado, então para dar um maior suporte à diferentes bases
  -- será necessario que você busque o evento que é chamado quando o jogador seleciona seu personagem.
  -- caso sua cidade nao tenha multichar, basta utilizar o framework vrp
  -- para utilizar os parametros abaixo, certifique-se que o framework na linha 18 seja custom

  -- customEventName = "CharacterChosen", -- evento chamado quando o jogador seleciona seu personagem

  -- essa função necessita retornar o nome completo do personagem e o ID.
  getFirstLastName = function(source)
    local user_id = vRP.getUserId(source)
    local identity = vRP.getUserIdentity(user_id)
    local fullName = identity.nome .. " " .. identity.sobrenome .. " | " .. user_id
    return fullName
  end,

  -- em bases CREATIVE
  -- getFirstLastName = function(source)
  --   local user_id = vRP.Passport(source)
  --   local fullName = vRP.FullName(user_id) .. " | " .. user_id
  --   return fullName
  -- end,


  -- em bases QBCORE
  -- getFirstLastName = function(source)
  --   local user = QBCore.Functions.GetPlayer(source)
  --   local fullName = user.PlayerData.charinfo.firstname .. " " .. user.PlayerData.charinfo.lastname .. " | " .. user.PlayerData.citizenid
  --   return fullName
  -- end,

  -- em bases VorpCore
  -- getFirstLastName = function(source)
  --   local user = VorpCore.getUser(source)
  --   local Character = user.getUsedCharacter
  --   local fullName = Character.firstname .. " " .. Character.lastname .. " | " .. user.source
  --   return fullName
  -- end,
}
