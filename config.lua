-- Com Config.framework = "auto" (padrão) NENHUM bloco abaixo é necessário:
-- o script detecta o framework e inicializa a interface sozinho.
-- Descomente apenas se for usar um framework manual (ver Config.framework).

-- caso use vRP com framework manual ("vrp", "creative", "creative-mod"), descomente
-- as linhas abaixo (e a linha '@vrp/lib/utils.lua' no fxmanifest.lua)
-- local Proxy = module("vrp", "lib/Proxy")
-- vRP = Proxy.getInterface("vRP")

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
  appKey = "",  -- Chave da API (ou use a convar rnld_api_key)
  debug = false,
  -- MockedDiscordId = "", -- junto com debug true, força o script a renomear um discord especifico, para facilitar os testes
  monitoring = true, -- Habilita/desabilita o envio de eventos de monitoramento (session_start, session_end, server_start, server_shutdown)
  vpnMode = "full",  -- full, alert (Significa que o player será barrado ao utilizar vpn, ou apenas alertado no canal)
  locale = "pt-br",  -- idioma das mensagens ao jogador: "pt-br" | "en-us" | "pt-pt"

  -- Framework da base. Com "auto" (padrão) o script detecta sozinho o framework
  -- (vRP/Creative, QBCore/Qbox, VorpCore), o evento de escolha de personagem e as
  -- funções de playerID/nome — sem precisar editar nada abaixo.
  -- Valores manuais (case-sensitive!): "vrp", "creative", "creative-mod", "qbcore",
  -- "VorpCore", "custom". Use "custom" + rnld.customEventName para frameworks não
  -- listados; nos manuais, descomente também o bloco do framework no topo deste
  -- arquivo e as funções da tabela rnld no fim.
  framework = "auto",

  -- Ativa as funcionalidades da Whitelist Remota
  BaseMode = "discord,steam",   --Configura qual licença será exigida pelo script, discord, steam ou license
  validarPresencaGuild = false, -- Quando true, impede a entrada de jogadores que não estejam presentes na guild do Discord.
  discordInviteUrl = "",        -- Link de convite do Discord exibido no card quando o player não está na guild (ex: "https://discord.gg/seuservidor")
  whitelistUrl = "",            -- Se definida, os modos card e styled exibem um botão "liberar token (<wl_id>)" que abre <url>?token=<wl_id> no navegador em vez do campo de texto do token.
  ConsiderRockstar = true,      -- Tira a validação da license e license2 da equação

  -- Configura como a mensagem de whitelist será apresentada ao player
  ConnectUI = {
    -- "styled" para usar deferrals.presentCard (Estilizado)
    -- "card" para usar deferrals.presentCard (Adaptive Card)
    -- "text" para usar deferrals.done com mensagem em texto
    mode = "styled",
    -- eventName = "", -- Faz o script acionar um evento retornando o token do player
    -- Somente quando mode = "card"
    attempts = 2,      -- Loop para apresentar o deferralscard
    intervalMs = 2000, -- intervalo entre presents (ms)

    -- Integração com sistemas de fila (queue): quando true, o resource defere a
    -- conexão mas só apresenta o card de whitelist quando a fila chamar
    -- exports['rnld_api']:presentDeferral(source) — normalmente quando o player
    -- chega ao fim da fila. Evita que os deferrals da fila e da whitelist
    -- concorram pela mesma tela. Nesse modo a fila NÃO deve chamar
    -- deferrals.done() para este fluxo (quem finaliza é o rnld_api). Padrão: false.
    externalControl = false,
    -- Tempo máx. (ms) aguardando presentDeferral antes de liberar sozinho
    -- (0 = espera indefinida). Use como válvula de segurança caso a fila esqueça
    -- de chamar presentDeferral/cancelDeferral. Ex.: 300000 = 5 min.
    -- externalControlTimeoutMs = 0,
  },

  -- Sincroniza players que já têm whitelist na sua base com o sistema RNLD.
  -- Quando enabled = true, checker é obrigatório (função do framework que retorna true se o player já tem whitelist).
  -- Se o checker retornar true, o script chamará o conversor de whitelist; O card de liberação será ignorado e o player será liberado automaticamente.
  ExistingWhitelist = {
    enabled = false,
    -- Obrigatório quando enabled = true. Função do framework: retorna true se o player já possui whitelist na sua base.
    -- Parâmetros: source (number), licenses (tabela com steam, discord, license, etc.)
    -- { licenses = { steam = "1234567890", discord = "1234567890", license = "1234567890", license2 = "1234567890", fivem = "1234567890", live = "1234567890" } }
    -- checker = function(source, licenses)
    --   whitelisted = <sua função para verificar se o player tem whitelist no seu banco de dados>
    --   return whitelisted
    -- end,
    -- Opcional: resolver discordId para enviar na conversão (padrão: licenses.discord)
    -- discordIdResolver = function(source, licenses)
    --   return licenses and licenses.discord or ""
    -- end
  },

  -- Sincroniza a whitelist da RNLD com o seu banco de dados local.
  -- Quando enabled = true e o player conecta com o token JÁ liberado, o script executa um
  -- UPDATE marcando a coluna especificada como `value` (padrão: true) na sua tabela.
  -- Como cada base usa uma lib de MySQL diferente (oxmysql, mysql-async, ghmattimysql...),
  -- VOCÊ fornece a função `query`; o script apenas monta o SQL parametrizado e a chama.
  -- Falhas na sincronização nunca barram a entrada do player (apenas logam o erro).
  LocalWhitelistSync = {
    enabled = false,
    table = "users",              -- tabela do seu banco
    column = "whitelisted",       -- coluna marcada quando o player é liberado
    value = true,                 -- valor aplicado na coluna (padrão: true)
    identifierColumn = "license", -- coluna do WHERE usada para localizar o player

    -- Opcional. Resolve o valor do identificador (WHERE identifierColumn = ?) a partir das licenses.
    -- Se omitido, o script usa licenses[identifierColumn] (ex: licenses.license).
    -- Parâmetros: source (number), licenses (steam, discord, license, license2, fivem, live), wlId (string)
    -- identifierResolver = function(source, licenses, wlId)
    --   return licenses.license
    -- end,

    -- Obrigatório quando enabled = true. Recebe (sql, params) e executa na lib do seu servidor.
    -- O `sql` já vem com placeholders (?) e `params` é a lista de valores na ordem.
    query = function(sql, params)
      -- oxmysql:      exports.oxmysql:execute(sql, params)
      -- mysql-async:  MySQL.Async.execute(sql, params)
      -- ghmattimysql: exports.ghmattimysql:execute(sql, params)
    end,
  },

  -- Mantém a coluna do ID do Discord sempre atualizada no seu banco local.
  -- Quando enabled = true, em TODA conexão (independente do resultado da whitelist)
  -- o script executa um UPDATE gravando o Discord ID atual do player na coluna
  -- especificada — útil quando o player troca de conta Discord entre sessões.
  -- Mesmo contrato do LocalWhitelistSync: VOCÊ fornece a função `query`.
  -- Falhas na sincronização nunca barram a entrada do player (apenas logam o erro).
  LocalDiscordIdSync = {
    enabled = false,
    table = "users",              -- tabela do seu banco
    column = "discord",           -- coluna que guarda o ID do Discord
    identifierColumn = "license", -- coluna do WHERE usada para localizar o player

    -- Opcional. Formata o valor gravado. Padrão: o ID puro (ex: "123456789012345678").
    -- Se a sua base guarda com prefixo, descomente:
    -- valueResolver = function(discordId, source, licenses)
    --   return "discord:" .. discordId
    -- end,

    -- Opcional. Resolve o valor do identificador (WHERE identifierColumn = ?) a partir das licenses.
    -- Se omitido, o script usa licenses[identifierColumn] (ex: licenses.license).
    -- identifierResolver = function(source, licenses)
    --   return licenses.license
    -- end,

    -- Obrigatório quando enabled = true. Recebe (sql, params) e executa na lib do seu servidor.
    query = function(sql, params)
      -- oxmysql:      exports.oxmysql:execute(sql, params)
      -- mysql-async:  MySQL.Async.execute(sql, params)
      -- ghmattimysql: exports.ghmattimysql:execute(sql, params)
    end,
  },

  -- Anti-Spoofer (coleta de fingerprint via NUI).
  -- Quando enabled = true, um client script abre uma NUI invisível no Chromium do
  -- FiveM que coleta sinais do navegador (WebGL/GPU, canvas+audio, fontes/telas,
  -- navigator) e os envia assinados (HMAC com nonce de sessão) para ampliar a
  -- detecção de spoofers (depende do wl_id da sessão).
  AntiSpoofer = {
    enabled = true,
    hbIntervalMs = 10000,
  }
}

rnld = {
  -- Com framework = "auto" TUDO nesta tabela é opcional: o script resolve o
  -- playerID e o nome do personagem sozinho. Descomente apenas para sobrescrever
  -- a detecção (ex.: base editada que renomeou as funções do framework) ou
  -- quando usar framework = "custom".

  -- customEventName = "CharacterChosen", -- evento chamado quando o jogador seleciona seu personagem (framework = "custom")

  -- (framework = "auto") formato do apelido enviado ao Discord.
  -- Tokens: {nome}, {sobrenome}, {nomecompleto}, {id} — em qualquer ordem
  -- (ex.: "#{id} - {nome} {sobrenome}"). Apelidos acima de 32 caracteres
  -- (limite do Discord) são truncados pelo próprio script preservando o {id}
  -- e o layout: primeiro descarta o {sobrenome}, depois encurta o {nome}.
  -- Padrão quando não definido: "{nomecompleto} | {id}"
  -- nameFormat = "{nome} {sobrenome} | {id}",

  -- função do framework para resolver playerID por source
  -- Esse parametro vai permitir o uso dos exports: rnld_api:getPlayerIdByToken e rnld_api:getTokenByPlayerId
  -- registerPlayerIdResolver = function(source)
  --   return vRP.getUserId(source)
  --   -- return vRP.Passport(source)
  --   -- return QBCore.Functions.GetPlayer(source).PlayerData.citizenid
  --   -- return VorpCore.getUser(source).getUsedCharacter.source
  -- end,

  -- essa função necessita retornar o nome completo do personagem e o ID no final,
  -- separados por " | " (o backend usa esse separador para truncar apelidos > 32 caracteres)
  -- getFirstLastName = function(source)
  --   local user_id = vRP.getUserId(source)
  --   local identity = vRP.getUserIdentity(user_id)
  --   local fullName = string.format("%s %s | %s", identity.nome, identity.sobrenome, user_id)
  --   return fullName
  -- end,

  -- em bases CREATIVE
  -- getFirstLastName = function(source)
  --   local user_id = vRP.Passport(source)
  --   local fullName = string.format("%s | %s", vRP.FullName(user_id), user_id)
  --   return fullName
  -- end,


  -- em bases QBCORE
  -- getFirstLastName = function(source)
  --   local user = QBCore.Functions.GetPlayer(source)
  --   local fullName = string.format("%s %s | %s", user.PlayerData.charinfo.firstname, user.PlayerData.charinfo.lastname, user.PlayerData.citizenid)
  --   return fullName
  -- end,

  -- em bases VorpCore
  -- getFirstLastName = function(source)
  --   local user = VorpCore.getUser(source)
  --   local Character = user.getUsedCharacter
  --   local fullName = string.format("%s %s | %s", Character.firstname, Character.lastname, user.source)
  --   return fullName
  -- end,
}
