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

Msgs = {
  divergenceMsg = [[
  VOCÊ ESTÁ COM FALHA NA IDENTIFICAÇÃO DA CONTA,
  POR FAVOR, PRINTE ESTA TELA E ABRA UM TICKET EM NOSSO DISCORD.
  ]],

  bannedMsg = [[
  VOCÊ ESTÁ BANIDO DO SERVIDOR,
  SE ACHAR QUE FOI UM ENGANO, ABRA UM TICKET EM NOSSO DISCORD E COMPARTILHE SEU TOKEN.
  MOTIVO: %s
  ]]
}

Config = {
  guildId = "", -- id do seu servidor discord
  appKey = "",  -- Chave da API
  debug = false,
  -- MockedDiscordId = "", -- Defina um discord id menos privilegiado para que o sistema possa aplicar a mudança do apelido

  -- Esse resource tem a funcionalidade de acionar a API para renomear o player
  -- Você poderá habilitá-la, ou desabilitar basicamente escolhendo o framework "custom"
  -- Se colocar "custom" voce também deverá descomentar a linha 46 e colocar qualquer nome para o evento
  framework = "vrp", -- Framework utilizado ( vrp, creative, creative-network, qbcore, vorpcore)

  -- Ativa as funcionalidades da Whitelist Remota
  BaseMode = "discord", --Configura qual licença será exigida pelo script, discord, steam ou license
  Whitelist = true,     -- Ativa o modo de whitelist utilizando nossa API, será necessario desabilitar a whitelist da sua base.

  -- Configura como a mensagem de whitelist será apresentada ao player
  ConnectUI = {
    -- "card" para usar deferrals.presentCard (Adaptive Card)
    -- "text" para usar deferrals.done com mensagem em texto
    mode = "card",
    -- eventName = "", -- Faz o script acionar um evento retornando o token do player
    -- Somente quando mode = "card"
    attempts = 2,       -- Loop para apresentar o deferralscard
    intervalMs = 10000, -- intervalo entre presents (ms)
  }
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
