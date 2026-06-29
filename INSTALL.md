wp_lb-addons — lb-phone Addons (InstaPic Donations + Trendy View Payouts)
=========================================================================

STEP 1 — Copy wp_lb-addons resource
  Copy the "wp_lb-addons" folder into your resources folder (e.g. resources/[wp_scripts]/)

STEP 2 — Copy lb-phone custom files
  From the "lb-phone-install-files" folder, copy:
    server/custom/functions/wp_lb_addons.lua  ->  lb-phone/server/custom/functions/wp_lb_addons.lua
    client/custom/functions/wp_lb_addons.lua  ->  lb-phone/client/custom/functions/wp_lb_addons.lua

STEP 3 — Database (automatic)
  The Trendy view-payout and Birdy payout tables are created automatically on first start.
  To create them manually instead, run wp_lb-addons/install.sql.

STEP 4 — Add to server.cfg
  Add AFTER lb-phone:
    ensure wp_lb-addons

STEP 5 — Start
  Start or restart the server.
  wp_lb-addons automatically finds lb-phone's real UI page (from its fxmanifest `ui_page`,
  so it works even if lb-phone bumped its build folder, e.g. ui/dist7/index2.html), patches
  in the donate overlay, and restarts lb-phone once. No manual edits to lb-phone files needed.

  NOTE: players already connected may keep a cached phone page and not see the donate button
  until they rejoin (or clear the FiveM NUI cache: %localappdata%\FiveM\FiveM.app\data\cache).
  Fresh joiners get it immediately.

STEP 6 — Configure (optional)
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
