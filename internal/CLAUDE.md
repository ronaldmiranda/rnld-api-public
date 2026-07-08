# CLAUDE.md — rnld_api (resource FiveM/RedM)

Guia de instalação/integração deste resource em bases (frameworks) de clientes já existentes. Este arquivo é sobre **como plugar o `rnld_api` numa cidade**, não sobre a arquitetura do backend (isso está no `../../CLAUDE.md` do monorepo — o `rnld-api-go`/`rnld-api` que este script consome).

## O que este resource faz

- Valida whitelist/ban do player no `playerConnecting`, decide o card será apresentado.
- Sincroniza o apelido do Discord do player quando ele escolhe personagem (evento varia por framework — ver abaixo).
- Opcionalmente: Anti-Spoofer (fingerprint via NUI), sync de whitelist local (`LocalWhitelistSync`), auto-liberação de quem já tem WL na base do cliente (`ExistingWhitelist`), e integração com sistemas de fila (`ConnectUI.externalControl`).

## Requisitos obrigatórios (não-negociáveis)

- **Nome do resource precisa ser exatamente `rnld_api`** — `server.lua` checa `GetCurrentResourceName()` e recusa rodar (`server.lua:26-36`) com qualquer outro nome. Não renomeie a pasta ao entregar pro cliente.
- Lua 5.4 (`server.lua:21-24` já valida isso; `fxmanifest.lua` já declara `lua54 'yes'`).
- `config.lua` está em `escrow_ignore` (fxmanifest.lua:7-9) — é o único arquivo pensado para ser editado pelo cliente. **Nunca** peça pro cliente editar `server.lua`, `client.js` ou `nui/*` — esses são atualizados automaticamente pelo auto-updater (ver `update_artifacts` em `server.lua:239-244`).

## Passo a passo de instalação

1. Renomear a pasta do resource para `rnld_api` (se vier zipada com outro nome).
2. Em `config.lua`, preencher `Config.guildId` e `Config.appKey` (ou usar a convar `rnld_api_key`).
3. Escolher o framework em `Config.framework` — **o valor precisa bater exatamente** com uma das chaves abaixo (case-sensitive!). Ver seção "Frameworks suportados".
4. Descomentar, em `config.lua` (topo do arquivo) e em `rnld.getFirstLastName` / `rnld.registerPlayerIdResolver` (fim do arquivo), o bloco correspondente ao framework do cliente.
5. Ajustar `fxmanifest.lua`:
   - Se a base **não** usa vRP/Creative, remover a linha `'@vrp/lib/utils.lua'` de `server_scripts` (fxmanifest.lua:17) — senão o resource vai falhar ao iniciar (dependência inexistente).
   - Se usa vRP/Creative, confira o **case** do arquivo dentro do resource `vrp` do cliente: a maioria usa `utils.lua` minúsculo, mas algumas Creatives usam `Utils.lua` (maiúsculo) — já existe a linha alternativa comentada em `fxmanifest.lua:18`. Usar o case errado falha o boot só em sistemas de arquivo case-sensitive (Linux); em Windows passa despercebido no teste local e só quebra no servidor de produção.
   - Antes de descomentar `'@ox_lib/init.lua'` em `shared_scripts` (fxmanifest.lua:13), **confirme que a base realmente tem o resource `ox_lib` instalado** — não basta ser QBCore, muitas bases QBCore mais antigas não usam ox_lib. Procure na pasta `resources/` do servidor do cliente por uma pasta `ox_lib` e/ou por `ensure ox_lib` no `server.cfg` (`grep -rn "ox_lib" server.cfg`; `find . -maxdepth 2 -iname "ox_lib"`). Se não achar, deixe a linha comentada — descomentar sem o resource presente quebra o boot por dependência ausente, igual ao caso do `@vrp/lib/utils.lua`.
6. `ensure rnld_api` e observar o console: `[rnld-api] O script está em execução.` confirma boot; `Framework não suportado: <valor>` indica erro no passo 3.
7. Testar uma conexão com `Config.debug = true` antes de entregar — loga request/response de cada chamada à API (exceto `tokens/*`, que é sempre silenciado).

## Frameworks suportados (`Config.framework`)

⚠️ **Cuidado**: os valores aceitos são as chaves EXATAS da tabela `frameworkHandlers` em `server.lua` (~linha 2702). O comentário antigo em `config.lua:39` lista `creative-network` e `vorpcore` (minúsculo) — **esses dois não existem na tabela e vão cair no `else` silencioso** (`Framework não suportado`). Use sempre os valores desta tabela, não o comentário:

| `Config.framework` | Evento escutado | Framework real |
|---|---|---|
| `"vrp"` | `playerConnecting` | vRP clássico / vRPEX |
| `"creative"` | `CharacterChosen` | Creative Network |
| `"creative-mod"` | `ChosenCharacter` | variante de Creative com evento renomeado |
| `"qbcore"` | `QBCore:Server:PlayerLoaded` | QBCore |
| `"VorpCore"` | `vorp:SelectedCharacter` (+ `init:name`) | VORP (RedM) — **atenção ao camelCase, não é `"vorpcore"`** |
| `"custom"` | valor de `rnld.customEventName` | qualquer framework não listado |

Se o framework do cliente não estiver aqui, use `"custom"` (passo abaixo) em vez de tentar forçar um dos nomes existentes.

### vRP / vRPEX (`framework = "vrp"`)

```lua
-- config.lua, topo do arquivo (já vem descomentado por padrão):
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")
```

- Usa o evento nativo `playerConnecting` diretamente — não precisa de handler extra.
- `registerPlayerIdResolver` e `getFirstLastName` já vêm configurados para vRP clássico (`vRP.getUserId`, `vRP.getUserIdentity`) por padrão em `config.lua`.
- Se for **Creative** (não vRPEX clássico), trocar para as versões comentadas que usam `vRP.Passport` / `vRP.FullName` (ver comentários em `config.lua:150,164-168`).

### Creative Network (`framework = "creative"` ou `"creative-mod"`)

- Mesma inicialização de Proxy do vRP (Creative usa a mesma lib `vrp/lib/Proxy`).
- `registerPlayerIdResolver`: `return vRP.Passport(source)`.
- `getFirstLastName`: usar o bloco comentado em `config.lua:164-168` (`vRP.FullName`).
- Se a base dispara `CharacterChosen`, use `"creative"`; se a variante renomeou o evento para `ChosenCharacter`, use `"creative-mod"`. Confirme com o cliente/dono da base qual evento ela realmente dispara (`grep -r "ChosenCharacter\|CharacterChosen"` nos resources da base).

### QBCore (`framework = "qbcore"`)

```lua
-- config.lua, topo do arquivo:
local QBCore = exports['qb-core']:GetCoreObject()
```

- `registerPlayerIdResolver`: `return QBCore.Functions.GetPlayer(source).PlayerData.citizenid`.
- `getFirstLastName`: usar o bloco comentado em `config.lua:172-176` (`PlayerData.charinfo`).
- Handler já espera `Player.PlayerData.source` — nenhum ajuste extra necessário além do Proxy acima.
- Adicionar `'@ox_lib/init.lua'` em `shared_scripts` no `fxmanifest.lua` se a base depender de `ox_lib` (comum em QBCore moderno).

### VorpCore / RedM (`framework = "VorpCore"`)

```lua
-- config.lua, topo do arquivo:
VorpCore = {}
TriggerEvent("getCore", function(core)
  VorpCore = core
end)
```

- `registerPlayerIdResolver`: `return VorpCore.getUser(source).getUsedCharacter.source`.
- `getFirstLastName`: usar o bloco comentado em `config.lua:179-184`.
- **Case sensível**: escreva `Config.framework = "VorpCore"` — `"vorpcore"` em minúsculo não bate com a chave da tabela e o handler nunca é registrado.
- `fxmanifest.lua` já declara `games { 'rdr3', 'gta5' }`, então RedM funciona sem alteração no manifest.

### Framework não listado (`framework = "custom"`)

Use quando a base não é nenhuma das anteriores:

```lua
-- config.lua:
rnld.customEventName = "SeuEventoDeCharacterSelect" -- evento disparado quando o player escolhe o personagem
```

#### 1. Encontre as funções de ID e nome do personagem no framework do cliente

`registerPlayerIdResolver` e `getFirstLastName` não têm como ser genéricos — cada framework guarda o ID do personagem e o nome em lugares diferentes. Antes de escrever essas duas funções, procure no core do framework do cliente (não no `rnld_api`) por algo equivalente a:

- **ID do personagem**: procure por termos como `GetPlayer`, `PlayerData`, `Character`, `Identity`, `citizenid`, `getUser`, `Passport` dentro dos resources do "core" da base (`grep -rEn "citizenid|PlayerData|getUsedCharacter|Passport|GetCharacter" <core do framework>/*.lua`). É o valor que os outros frameworks já usam (`vRP.getUserId`, `vRP.Passport`, `PlayerData.citizenid`, `getUsedCharacter.source`) — o equivalente de "chave primária do personagem", não da conexão (`source`).
- **Nome completo**: procure a tabela/objeto de identidade do personagem (normalmente tem `firstname`/`lastname`, `nome`/`sobrenome`, ou `charinfo`) e monte a string como os outros blocos já fazem: `string.format("%s %s | %s", nome, sobrenome, id)`.
  - **Importante**: o backend (`memberService.atualizarApelidoMembro`, no `rnld-api` Node) trunca apelidos com mais de 32 caracteres procurando um separador `#`, `|` ou `-` na string e mantendo só o primeiro nome + separador + id. Ou seja, `getFirstLastName` **precisa** devolver o ID no final, separado por um desses três caracteres (`|` é o padrão usado pelos outros frameworks), senão o truncamento quebra em nomes longos.
- Copie um dos blocos já comentados em `config.lua` (linhas 148-184) como esqueleto e apenas troque as chamadas do framework — a estrutura da função (parâmetro `source`, retorno de string/valor) já está certa.

#### 2. Preste atenção à ordem dos parâmetros do evento

O handler do `"custom"` já vem fixo em `server.lua` (não editável — é sobrescrito pelo auto-updater) e espera exatamente esta assinatura:

```lua
-- server.lua (frameworkHandlers.custom.handler) — não mexa aqui, é só referência:
handler = function(Passport, source)
  processChangeNickname(source)
  syncPlayerIdTokenCache(source, nil, Passport)
end
```

Ou seja: **1º parâmetro = ID do personagem (o mesmo valor que `registerPlayerIdResolver` retorna), 2º parâmetro = `source`**. Essa ordem não é universal entre frameworks — repare que os handlers nativos já cadastrados divergem entre si:

| Framework | Assinatura do handler | Ordem |
|---|---|---|
| `creative` / `creative-mod` / `custom` | `function(Passport, source)` | **ID primeiro, source depois** |
| `qbcore` | `function(Player)` | objeto único, `source` vem de dentro (`Player.PlayerData.source`) |
| `VorpCore` | `function(source, character)` | **source primeiro, ID depois** (invertido em relação ao `custom`!) |

Se o evento nativo do framework do cliente dispara na mesma ordem do `custom` (`id, source`), basta apontar `rnld.customEventName` pra ele. Se ele dispara na ordem contrária (como o `VorpCore`) ou com uma assinatura diferente (como o `qbcore`, um único objeto), **não dá pra reaproveitar o evento nativo direto** — como `server.lua` não deve ser editado, crie um evento-ponte num resource separado do cliente (nunca dentro do `rnld_api`, senão o auto-update apaga) que escuta o evento real do framework e retransmite na ordem certa:

```lua
-- em outro resource do cliente, NÃO dentro do rnld_api:
AddEventHandler('eventoRealDoFramework', function(source, characterData)
  local Passport = characterData.id -- ou o campo equivalente
  TriggerEvent('SeuEventoDeCharacterSelect', Passport, source) -- ordem exigida pelo custom
end)
```

- Se a base não tem multichar, pode-se usar `framework = "vrp"` mesmo sem vRP real, desde que `playerConnecting` seja o gatilho correto — mas prefira `custom` para não confundir o Proxy do vRP com um framework que não o usa.

## Integrações opcionais (perguntar ao cliente antes de habilitar)

- **`Config.LocalWhitelistSync`** — grava a liberação também na tabela local do cliente. `enabled = true` exige a função `query(sql, params)` escrita para a lib de MySQL da base (`oxmysql`, `mysql-async`, `ghmattimysql`...). Falha na sync nunca bloqueia o player (só loga).
- **`Config.ExistingWhitelist`** — auto-libera quem já tem WL na base do cliente. `enabled = true` exige a função `checker(source, licenses)` (deve consultar o banco/sistema de WL já existente da base e retornar `true`/`false`).
- **`Config.ConnectUI.externalControl`** — para bases com sistema de fila (queue) próprio. Quando `true`, a fila deve chamar `exports['rnld_api']:presentDeferral(source)` no momento de liberar o player (nunca `deferrals.done()` direto), e pode chamar `exports['rnld_api']:cancelDeferral(source)` se remover o player da fila antes disso.
- **`Config.AntiSpoofer`** — independe de framework; liga/desliga coleta de fingerprint via NUI. Não precisa de nenhuma integração além de `enabled = true`.

## Erros comuns de instalação

- Resource com nome diferente de `rnld_api` → resource nem inicia (silencioso, só print no console).
- `Config.framework` com valor da lista antiga do comentário (`creative-network`, `vorpcore` minúsculo) → nickname sync e cache de playerID/token simplesmente não funcionam, mas a whitelist (`playerConnecting`) continua funcionando normalmente — erro fácil de passar despercebido em teste rápido.
- Deixar `'@vrp/lib/utils.lua'` no `fxmanifest.lua` em base sem vRP → resource falha ao iniciar por dependência ausente.
- Usar o case errado (`utils.lua` vs `Utils.lua`) para o arquivo do vRP do cliente → funciona em dev (Windows/macOS, case-insensitive) e falha só ao subir em produção (Linux, case-sensitive) — sempre confira o nome real do arquivo dentro do resource `vrp` da base.
- Esquecer de comentar/descomentar o Proxy certo em `config.lua` → `vRP`/`QBCore`/`VorpCore` fica `nil` e qualquer handler que o referencia quebra com erro no console ao escolher personagem.
- Habilitar `LocalWhitelistSync`/`ExistingWhitelist` sem fornecer `query`/`checker` → o script apenas loga aviso e ignora a feature (não trava o player), mas a integração combinada com o cliente não vai funcionar até isso ser corrigido.
- No `framework = "custom"`, apontar `rnld.customEventName` para um evento que dispara `(source, id)` em vez de `(id, source)` → `Passport`/`source` ficam trocados dentro do handler fixo, o cache de playerID/token grava valores errados e o `processChangeNickname` roda com o ID no lugar da source (sem erro visível no console — só o comportamento errado).
