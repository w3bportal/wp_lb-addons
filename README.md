# wp_lb-addons — lb-phone Addons
### ESX only · Requires [lb-phone](https://github.com/lbphone/lb-phone) ( updates proof, just re do the install process )

Adds pay-per-interaction systems to three lb-phone apps:

| App | Feature |
|-----|---------|
| **InstaPic** (Instagram) | Live stream donations |
| **Trendy** (TikTok) | Automatic view payouts |
| **Birdy** (Twitter/X) | Automatic like / retweet / reply payouts |

<img width="336" height="678" alt="image" src="https://github.com/user-attachments/assets/abf5a2ac-9dc4-44db-94d7-fb5e7d2673d6" />
<img width="363" height="688" alt="image" src="https://github.com/user-attachments/assets/1bc03074-ee6e-40a8-854b-20d836a25dad" />
<img width="292" height="51" alt="image" src="https://github.com/user-attachments/assets/8ab15001-5adf-4f71-886d-2de451793cfb" />

---

## Installation

**Step 1 — Copy the resource**
Copy the `wp_lb-addons` folder into your resources directory.

**Step 2 — Copy lb-phone custom files**
From the `lb-phone-install-files` folder, copy both files into lb-phone:
lb-phone-install-files/server/custom/functions/wp_lb_addons.lua
→ lb-phone/server/custom/functions/wp_lb_addons.lua

lb-phone-install-files/client/custom/functions/wp_lb_addons.lua
→ lb-phone/client/custom/functions/wp_lb_addons.lua



**Step 3 — Add to server.cfg**
Add this line **after** `ensure lb-phone`:
ensure wp_lb-addons



**Step 4 — Database**
The tables are created automatically on first start. If you prefer to create them manually, run `install.sql`.

**Step 5 — Start**
Start or restart the server. `wp_lb-addons` will automatically patch lb-phone's `index.html` and restart lb-phone. No manual edits to lb-phone files are needed.

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

