# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is the **public distribution repo** for `rnld_api`, a FiveM/RedM server resource. It is not application source code — it's the artifact that gets zipped and released for clients to drop into their FiveM/RedM server. The real backend this resource talks to (`rnld-api-go` / `rnld-api`) lives in a separate monorepo; this repo only ships the client-facing Lua/JS resource.

## Key files

- `server.lua`, `client.js`, `nui/app.js` — **pre-obfuscated build artifacts** (Luraph-obfuscated Lua, minified/obfuscated JS). These are generated elsewhere and committed as-is; do not attempt to read, edit, or "fix" them directly — they are not human-authored source in this repo. They are also excluded from the client's editable surface: end users must never be told to edit these (they're overwritten by the resource's auto-updater).
- `config.lua` — the **only** file meant to be hand-edited, by whoever installs the resource on a client's server. Holds `Config` (API key, guild id, whitelist behavior, framework selection, optional integrations) and `rnld` (framework-specific resolver functions: `registerPlayerIdResolver`, `getFirstLastName`, optional `customEventName`). It is listed in `escrow_ignore` in `fxmanifest.lua` for this reason.
- `fxmanifest.lua` — FiveM resource manifest. Declares `lua54`, supports both `gta5` and `rdr3` (RedM), and conditionally includes `@vrp/lib/utils.lua` / `@ox_lib/init.lua` depending on the target framework (these lines get commented/uncommented per-installation, not per-codebase).
- `nui/index.html`, `nui/app.js` — invisible NUI page used by the Anti-Spoofer feature to collect a browser/Chromium fingerprint from the client.
- `internal/CLAUDE.md` — **the actual detailed operating manual** for this resource: framework support matrix (`vrp`, `creative`, `creative-mod`, `qbcore`, `VorpCore`, `custom`), step-by-step client installation, event handler signatures per framework, and common installation failure modes. Read it before doing any framework-integration or client-onboarding work — don't duplicate its content here, it's kept in sync separately and copied into every release zip (see below).

## Release process

`.github/workflows/build.yaml` runs on every push to `main` and publishes a GitHub Release:

- Bundles a full fresh-install zip (`rnld_api.zip`): `config.lua`, `fxmanifest.lua`, `server.lua`, `client.js`, `internal/CLAUDE.md`, and `nui/`.
- Also publishes individual files with `.sha1` hashes for the resource's **multi-file auto-updater** (`server.lua`, `client.js`, and the NUI files flattened to `nui_app.js` / `nui_index.html` since release assets can't contain `/`). These filenames must stay in sync with `update_artifacts` inside `server.lua` — if you ever regenerate `server.lua` with a different artifact-naming scheme, update the workflow's `cp`/`sha1of` calls to match.
- There is no test/lint/build step for this repo — it's a packaging pipeline, not a build. Every push to `main` cuts a new dated release (`release-<run_number>`), so treat commits to `main` as release-worthy by default.

## Working in this repo

- Because `server.lua`/`client.js` are obfuscated artifacts, any real logic change has to happen upstream (in the private source repo that produces these builds) and land here as a replacement of the whole file — never hand-patch the obfuscated content.
- Most legitimate work in *this* repo is: updating `config.lua`'s commented examples/defaults, updating `fxmanifest.lua` (e.g. new dependency lines), or updating `internal/CLAUDE.md`'s installation/framework guidance. Treat `internal/CLAUDE.md` as the source of truth for anything about framework compatibility, event signatures, or client-onboarding troubleshooting.
- `Config.framework` values are case-sensitive and must match the exact keys in the (obfuscated) `frameworkHandlers` table in `server.lua` — see the table in `internal/CLAUDE.md` rather than guessing from `config.lua`'s comments, which are known to be out of date (e.g. list `creative-network`/`vorpcore` which don't exist as valid keys).
