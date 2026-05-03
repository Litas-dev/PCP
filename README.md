# PCP (PartyBot Control Panel) — Custom ![Downloads](https://img.shields.io/github/downloads/Litas-dev/PCP/total?label=Downloads&logo=github&color=blue)
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
### 2.1.2 - Custom
- Version updated to `2.1.2 - Custom` (TOC + in-window version label).
- Macro Mode:
  - `/pcpmacro on` inserts commands into the macro editor instead of sending them to chat.
  - `/pcpmacro off` sends commands normally again (RAID/PARTY/SAY).

### 2.1.0 - Custom
- Version updated to `2.1.0 - Custom` (TOC + in-window version label).
- Quick Windows system:
  - Create unlimited small, closable quick windows (each window has its own buttons + layout).
  - Big “Quick Windows” manager UI (Gear → Quick Windows…) to create/copy/delete windows.
  - Command library + custom button creator (label + command) to build quick bars in-game.
  - Reorder/remove buttons inside a window and change layout (Row/Grid) + columns.
  - Row layout now wraps (won’t run out of the window when you add more buttons).
  - Quick windows remember position and show/hide state.
  - Opening the main PCP frame re-opens visible quick windows.
- Quick Windows manager UI improvements:
  - Modern scrollbar styling (thin thumb, no default arrow buttons).
  - Modern Row/Grid toggle (no Blizzard dropdown).
  - Modern edit box styling (search/title/columns/custom fields).
- Quick command library improvements:
  - Adds bot shortcuts (Add Tank/Healer/DPS, Clone, Remove).
  - Adds marking shortcuts that work without selecting CC/Focus first:
    - CC Moon/Star/Circle/Diamond/Triangle/Square/Cross/Skull
    - Focus Moon/Star/Circle/Diamond/Triangle/Square/Cross/Skull
    - Clear CC / Clear Focus / Clear All Marks
- UI behavior fixes:
  - UI Settings auto-hide no longer disappears while you drag the scale slider.
  - UI Settings scale/font changes also apply to the main quick bar.

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
