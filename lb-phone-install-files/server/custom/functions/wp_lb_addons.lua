local ESX = exports['es_extended']:getSharedObject()

local _cfg = nil
local function getCfg()
    if not _cfg then _cfg = exports['wp_lb-addons']:getConfig() end
    return _cfg
end

local function isValidAmount(cfg, amount)
    local amounts = cfg and cfg.DonateAmounts
    if not amounts then return false end
    for _, d in ipairs(amounts) do
        if d.amount == amount then return true end
    end
    return false
end

RegisterNetEvent("phone:instagram:donate", function(streamerUsername, amount)
    local source = source
    local cfg = getCfg()
    local L   = (cfg and cfg.Locales) or {}

    if not isValidAmount(cfg, amount) then return end

    local donorPhone = GetEquippedPhoneNumber(source)
    if not donorPhone then return end

    local donorUsername = MySQL.scalar.await(
        "SELECT username FROM phone_logged_in_accounts WHERE phone_number = ? AND app = 'Instagram'",
        { donorPhone }
    )
    if not donorUsername then return end

    if cfg and cfg.RequireVerifiedStreamer then
        local isVerified = MySQL.scalar.await(
            "SELECT verified FROM phone_instagram_accounts WHERE username = ?",
            { streamerUsername }
        )
        if not isVerified or isVerified == 0 then
            SendNotification(donorPhone, {
                app     = "Instagram",
                title   = L.InstaPicAppName or 'InstaPic',
                content = L.DonateNotVerified or 'This streamer is not verified.',
            })
            return
        end
    end

    local xDonor = ESX.GetPlayerFromId(source)
    if not xDonor then return end
    if xDonor.getAccountMoney('bank') < amount then
        SendNotification(donorPhone, {
            app     = "Instagram",
            title   = L.InstaPicAppName or 'InstaPic',
            content = L.DonateInsufficientFunds or 'Insufficient funds to donate.',
        })
        return
    end

    -- Calculate streamer payout with platform fee
    local fee    = cfg and cfg.PlatformFeePercent or 0
    local payout = math.floor(amount * (1 - fee / 100))

    -- Deduct from donor via Wallet
    exports['lb-phone']:AddTransaction(donorPhone, -amount,
        string.format(L.DonateDeductLabel or 'Donation to @%s', streamerUsername))

    -- Credit streamer via Wallet (works even if streamer is offline)
    local streamerPhone = MySQL.scalar.await(
        "SELECT phone_number FROM phone_logged_in_accounts WHERE username = ? AND app = 'Instagram'",
        { streamerUsername }
    )
    if streamerPhone then
        exports['lb-phone']:AddTransaction(streamerPhone, payout,
            string.format(L.DonateReceiveLabel or 'Donation from @%s', donorUsername))
        SendNotification(streamerPhone, {
            app     = "Instagram",
            title   = L.DonateReceivedTitle or 'New Donation!',
            content = string.format(L.DonateReceivedContent or '%s donated $%d!', donorUsername, amount),
        })
    end

    -- Broadcast as a live chat message to all viewers
    TriggerClientEvent("phone:instagram:addLiveMessage", -1, {
        live = streamerUsername,
        user = {
            username = donorUsername,
            verified = false,
        },
        content = string.format(L.DonateChatMessage or 'donated $%d!', amount),
    })
end)
