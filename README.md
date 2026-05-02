# PCP (PartyBot Control Panel) — 2.0.0 - Custom ![Downloads](https://img.shields.io/github/downloads/Litas-dev/PCP/total?label=Downloads&logo=github&color=blue)
PCP is a PartyBot Control Panel addon for SoloCraft / PartyBot commands. This is a custom fork.

## Install
1. Download / clone the repository.
2. Put the `PCP` folder into:
   - `World of Warcraft/_classic_era_/Interface/AddOns/`
3. Restart WoW or run `/reload`.

## Updates
- WoW addons cannot fetch GitHub releases directly (no HTTP), so PCP can’t auto-check the URL in-game.
- PCP can still notify you if someone in your party/raid/guild has a newer version installed.
- Releases: https://github.com/Litas-dev/PCP/releases

## Changelog
### 2.0.0 - Custom
- Version updated to `2.0.0 - Custom` (TOC + in-window version label).
- Classic Era compatibility fixes:
  - TOC Interface updated to `11500`.
  - Fixes load order / double-loading issues that could break the UI.
  - PCPFrame hidden by default at login (no more “stuck on screen”).
  - Minimap button created on `PLAYER_LOGIN` (prevents early-load issues).
- Modern UI:
  - Dark flat frame styling + modernized text buttons.
  - Minimap button styled and cropped.
  - Adds tabs: Bots / Commands / Marks / All.
  - Adds “last used” click flash (1s highlight).
- Gear (options) menu:
  - UI Scale slider (0.8–1.3).
  - Big Font toggle.
- Saved settings improvements:
  - Saves UI settings under `PCPSettings.ui` (scale, bigFont, activeTab).
  - Tabs no longer overwrite your saved section enable/disable settings.
- External addon compatibility:
  - Avoids re-skinning icon-only buttons (keeps gear icon visible).
  - Avoids breaking FillRaidBots side buttons (icons stay intact).

## Notes
- Upstream: https://github.com/Litas-dev/PCP


