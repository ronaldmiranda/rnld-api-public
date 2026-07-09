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
3. **Deixar `Config.framework = "auto"` (padrão)** — o script detecta sozinho o framework (vRP/Creative, QBCore/Qbox, VorpCore) via `GetResourceState`, carrega a lib do vRP em runtime (sem tocar no `fxmanifest.lua`, inclusive resolvendo o case `utils.lua`/`Utils.lua`), descobre por tentativa as funções de playerID (Passport → getUserId) e de nome (FullName → getUserIdentity → userIdentity → Identity — os nomes variam por fork, inclusive entre bases Creative) e registra os eventos de personagem conhecidos (`CharacterChosen` **e** `ChosenCharacter`, com dedupe). O formato do apelido no modo auto é customizável via `rnld.nameFormat` no `config.lua` (tokens `{nome}`, `{sobrenome}`, `{nomecompleto}`, `{id}` em qualquer ordem, ex.: `"#{id} - {nome}"`; padrão `"{nomecompleto} | {id}"`). O truncamento para o limite de 32 caracteres do Discord é feito no próprio script (descarta sobrenome → encurta nome, preservando o `{id}` e o layout), então o truncamento por separador do backend — que exige o id no final e só vale para o `getFirstLastName` manual — nunca chega a rodar no modo auto. Só configure manualmente (passos 3m-5m abaixo) se a base for um framework não listado ou uma base editada que renomeou as funções do core.
4. Passos manuais — **apenas quando `"auto"` não cobrir a base**:
   - 3m. Escolher o framework em `Config.framework` — **o valor precisa bater exatamente** com uma das chaves da seção "Frameworks suportados" (case-sensitive!).
   - 4m. Descomentar, em `config.lua` (topo do arquivo) e em `rnld.getFirstLastName` / `rnld.registerPlayerIdResolver` (fim do arquivo), o bloco correspondente ao framework do cliente. Essas funções, quando descomentadas, **sempre têm prioridade** sobre a auto-detecção — servem também como override pontual mantendo `framework = "auto"`.
   - 5m. Ajustar `fxmanifest.lua` (só no modo manual com vRP/Creative): descomentar `'@vrp/lib/utils.lua'` em `server_scripts`, conferindo o **case** do arquivo dentro do resource `vrp` do cliente (a maioria usa `utils.lua` minúsculo; algumas Creatives usam `Utils.lua` — linha alternativa já comentada). Usar o case errado falha o boot só em Linux (case-sensitive); em Windows passa despercebido no teste local.
   - Antes de descomentar `'@ox_lib/init.lua'` em `shared_scripts`, **confirme que a base realmente tem o resource `ox_lib` instalado** — não basta ser QBCore, muitas bases QBCore mais antigas não usam ox_lib. Procure na pasta `resources/` do servidor do cliente por uma pasta `ox_lib` e/ou por `ensure ox_lib` no `server.cfg` (`grep -rn "ox_lib" server.cfg`; `find . -maxdepth 2 -iname "ox_lib"`). Se não achar, deixe a linha comentada — descomentar sem o resource presente quebra o boot por dependência ausente.
5. `ensure rnld_api` e observar o console: `[rnld-api] O script está em execução.` confirma boot. No modo auto, aguarde a linha `Auto-detecção: framework '<x>' detectado (resource '<y>')` (a detecção espera o core da base subir por até 60s); se aparecer `Auto-detecção: nenhum framework conhecido encontrado`, a base precisa de configuração manual. No modo manual, `Framework não suportado: <valor>` indica erro no passo 3m.
6. Testar uma conexão com `Config.debug = true` antes de entregar — loga request/response de cada chamada à API (exceto `tokens/*`, que é sempre silenciado) e, no modo auto, loga qual probe resolveu playerID/nome (`Auto-detecção: playerID resolvido via vRP.Passport`), o que confirma que a detecção acertou o framework.

## Frameworks suportados (`Config.framework`)

⚠️ **Cuidado**: nos valores manuais, o que vale são as chaves EXATAS da tabela `frameworkHandlers` em `server.lua` (case-sensitive!). Use sempre os valores desta tabela:

| `Config.framework` | Evento escutado | Framework real |
|---|---|---|
| `"auto"` (padrão) | detectados em runtime | vRP/Creative, QBCore/Qbox e VORP — detecção + resolvers automáticos |
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
- Modo auto em base cujo core demora mais de 60s pra subir (ou com `ensure rnld_api` antes do core no `server.cfg`) → detecção desiste com aviso no console; a whitelist continua funcionando, mas nickname sync/playerID ficam desativados até um restart do resource. Garanta o `ensure` do core antes do `rnld_api`.
- Modo auto em base editada que renomeou as funções do core (ex.: fork de vRP sem `getUserId`/`Passport`) → whitelist funciona, mas nenhum probe responde e o nickname sync fica mudo. Com `Config.debug = true` não aparece nenhuma linha `Auto-detecção: ... resolvido via ...` — configure os overrides `rnld.registerPlayerIdResolver`/`rnld.getFirstLastName` no `config.lua`.
- (Modo manual) `Config.framework` com valor fora da tabela (`creative-network`, `vorpcore` minúsculo) → nickname sync e cache de playerID/token simplesmente não funcionam, mas a whitelist (`playerConnecting`) continua funcionando normalmente — erro fácil de passar despercebido em teste rápido. Prefira `"auto"`.
- (Modo manual) Descomentar `'@vrp/lib/utils.lua'` no `fxmanifest.lua` em base sem vRP → resource falha ao iniciar por dependência ausente. No modo auto a linha fica comentada e o script carrega a lib em runtime.
- (Modo manual) Usar o case errado (`utils.lua` vs `Utils.lua`) para o arquivo do vRP do cliente → funciona em dev (Windows/macOS, case-insensitive) e falha só ao subir em produção (Linux, case-sensitive) — sempre confira o nome real do arquivo dentro do resource `vrp` da base. No modo auto os dois cases são tentados automaticamente.
- (Modo manual) Esquecer de comentar/descomentar o Proxy certo em `config.lua` → `vRP`/`QBCore`/`VorpCore` fica `nil` e qualquer handler que o referencia quebra com erro no console ao escolher personagem.
- Habilitar `LocalWhitelistSync`/`ExistingWhitelist` sem fornecer `query`/`checker` → o script apenas loga aviso e ignora a feature (não trava o player), mas a integração combinada com o cliente não vai funcionar até isso ser corrigido.
- No `framework = "custom"`, apontar `rnld.customEventName` para um evento que dispara `(source, id)` em vez de `(id, source)` → `Passport`/`source` ficam trocados dentro do handler fixo, o cache de playerID/token grava valores errados e o `processChangeNickname` roda com o ID no lugar da source (sem erro visível no console — só o comportamento errado).
