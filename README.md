# TF2 AFK Kick

An extension plugin for [TF2 AFK Manager](https://github.com/maxijabase/TF2-AFK-Manager) that kicks players who stay AFK for too long.

## What It Does

- Listens for AFK state changes from the core AFK Manager.
- Warns players in chat as their kick deadline approaches.
- Kicks them once the configured time is reached.
- Respects the core AFK Manager's admin immunity system.
- Optionally adds its own flag-based kick immunity on top, for cases where you want kick-specific overrides.
- Won't kick anyone if the server is below a minimum player count.

## ConVars

| ConVar | Default | Description |
|---|---|---|
| `sm_afk_kick_enable` | `1` | Enable or disable AFK kicking. |
| `sm_afk_kick_time` | `120` | Seconds of AFK time before a player is kicked. `0` to disable. |
| `sm_afk_kick_warn_time` | `30` | Seconds remaining before kick when warnings begin. |
| `sm_afk_kick_min_players` | `6` | Minimum connected players for kicks to be active. |
| `sm_afk_kick_prefix` | `AFK Manager` | Chat message prefix. |
| `sm_afk_kick_immunity_flag` | `""` | Admin flag(s) that grant kick immunity. Blank = disabled (falls back to core immunity). |

## Requirements

- SourceMod 1.12
- [TF2 AFK Manager](https://github.com/maxijabase/TF2-AFK-Manager)

## Translations

Place `translations/afk_kick.phrases.txt` in your SourceMod translations folder.
