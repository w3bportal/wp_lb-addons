wp_lb-addons — lb-phone Addons (InstaPic Donations + Trendy View Payouts)
=========================================================================

STEP 1 — Copy wp_lb-addons resource
  Copy the "wp_lb-addons" folder into your resources folder (e.g. resources/[wp_scripts]/)

STEP 2 — Copy lb-phone custom files
  From the "lb-phone-install-files" folder, copy:
    server/custom/functions/wp_lb_addons.lua  ->  lb-phone/server/custom/functions/wp_lb_addons.lua
    client/custom/functions/wp_lb_addons.lua  ->  lb-phone/client/custom/functions/wp_lb_addons.lua

STEP 3 — Add to server.cfg
  Add AFTER lb-phone:
    ensure wp_lb-addons

STEP 4 — Start
  Start or restart the server.
  wp_lb-addons will automatically patch lb-phone's index.html and restart lb-phone.
  No manual edits to lb-phone files needed.

STEP 5 — Configure (optional)
  Edit wp_lb-addons/config.lua to adjust payout amounts:
    Config.TrendyViewPayout = 10           -- $ creator earns per unique viewer on Trendy
    Config.PlatformFeePercent = 0          -- % cut from all payouts (0 = disabled)
    Config.RequireVerifiedStreamer = false  -- donations to verified InstaPic users only

FEATURES
  InstaPic (Instagram) Live Donations
    - Viewers can donate $50, $100, $500, or $1000 to the streamer
    - Money is deducted from donor's Wallet and credited to streamer's Wallet
    - Donation appears as a highlighted message in the live chat

  Trendy (TikTok) View Payouts
    - Views accumulate as pending earnings for the creator
    - Creator opens Trendy and taps "Collect" to claim all pending earnings at once
    - Tracked in the database — survives server restarts (no double-counting)
    - Creator does not need to be online when views happen
