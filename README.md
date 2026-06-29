# wp_lb-addons — lb-phone Addons
### ESX · Requires [lb-phone](https://github.com/lbphone/lb-phone) + oxmysql

Adds pay-per-interaction monetization to three lb-phone apps:

| App | Feature |
|-----|---------|
| **InstaPic** (Instagram) | Live-stream donations — viewers tip the streamer |
| **Trendy** (TikTok) | Automatic per-view payouts to the creator |
| **Birdy** (Twitter/X) | Automatic like / retweet / reply payouts |

> **Update-proof.** The patcher reads lb-phone's real UI page from its `fxmanifest.lua`
> (`ui_page`), so it keeps working even after lb-phone bumps its build folder for cache-busting
> (`ui/dist` → `ui/dist7/index2.html`, etc.). After an lb-phone update, just
> `restart wp_lb-addons` — no files to re-copy, no manual edits.

<img width="336" height="678" alt="image" src="https://github.com/user-attachments/assets/abf5a2ac-9dc4-44db-94d7-fb5e7d2673d6" />
<img width="363" height="688" alt="image" src="https://github.com/user-attachments/assets/1bc03074-ee6e-40a8-854b-20d836a25dad" />
<img width="292" height="51" alt="image" src="https://github.com/user-attachments/assets/8ab15001-5adf-4f71-886d-2de451793cfb" />

---

## Requirements

- [lb-phone](https://github.com/lbphone/lb-phone)
- oxmysql
- es_extended (ESX) — payouts move money through ESX bank/wallet accounts

---

## Installation

**Step 1 — Copy the resource**
Copy the `wp_lb-addons` folder into your resources directory.

**Step 2 — Copy lb-phone custom files**
From the `lb-phone-install-files` folder, copy both files into lb-phone:

```
server/custom/functions/wp_lb_addons.lua  →  lb-phone/server/custom/functions/wp_lb_addons.lua
client/custom/functions/wp_lb_addons.lua  →  lb-phone/client/custom/functions/wp_lb_addons.lua
```

**Step 3 — Add to server.cfg**
Add this line **after** `ensure lb-phone`:

```
ensure wp_lb-addons
```

**Step 4 — Database (automatic)**
The tables are created automatically on first start. To create them manually instead, run `install.sql`.

**Step 5 — Start**
Start or restart the server. `wp_lb-addons` automatically finds lb-phone's UI page, injects the
donate overlay, and restarts lb-phone once. No manual edits to lb-phone files are needed.

> **Note:** players already connected may keep a cached phone page and not see the donate button
> until they **rejoin** (or clear the FiveM NUI cache: `%localappdata%\FiveM\FiveM.app\data\cache`).
> Fresh joiners get it immediately.

---

## Usage

- **InstaPic donations** — open someone's live stream; a **Donate** button appears in the live
  header. Viewers pick an amount; funds move donor → streamer (works even if the streamer is
  offline) and a highlighted message is posted in the live chat.
- **Trendy payouts** — views accrue as pending earnings; creators are paid automatically on a
  configurable interval. Tracked in the database, so it survives restarts with no double-counting,
  and the creator doesn't need to be online when views happen.
- **Birdy payouts** — new likes / retweets / replies pay the post author automatically on a
  configurable interval.

---

## Configuration

Edit `wp_lb-addons/config.lua`:

```lua
-- Platform
Config.PlatformFeePercent = 0       -- % cut from every payout (0 = off)

-- InstaPic
Config.RequireVerifiedStreamer = false  -- donations to verified streamers only
Config.DonateAmounts = {
    { amount = 50,   color = 'green'  },
    { amount = 100,  color = 'green'  },
    { amount = 500,  color = 'green'  },
    { amount = 1000, color = 'yellow' },
}

-- Trendy
Config.TrendyViewPayout     = 10    -- $ per unique view (one-time per viewer)
Config.TrendyPayoutInterval = 60    -- minutes between payouts (0 = off)

-- Birdy
Config.RequireVerifiedBirdy = false -- payouts to verified accounts only
Config.BirdyLikePayout      = 5     -- $ per new like
Config.BirdyRetweetPayout   = 10    -- $ per new retweet
Config.BirdyReplyPayout     = 3     -- $ per new reply
Config.BirdyPayoutInterval  = 30    -- minutes between payouts (0 = off)
Config.BirdyPayoutMaxAge    = 7     -- only pay on posts newer than N days (0 = all)
```
