-- wp_lb-addons Trendy (TikTok) view payout handler
-- Views accumulate as pending earnings (collected = 0).
-- The server automatically pays all creators on a configurable interval.

local ESX = exports['es_extended']:getSharedObject()

local payoutRunning = false

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS wp_lb_addons_trendy_views (
            viewer_id        VARCHAR(100) NOT NULL,
            creator_username VARCHAR(50)  NOT NULL,
            collected        TINYINT(1)   NOT NULL DEFAULT 0,
            PRIMARY KEY (viewer_id, creator_username),
            INDEX idx_pending (collected, creator_username)
        )
    ]])
    -- Migrations for existing installs
    MySQL.query('ALTER TABLE wp_lb_addons_trendy_views ADD COLUMN IF NOT EXISTS collected TINYINT(1) NOT NULL DEFAULT 0')
    MySQL.query('CREATE INDEX IF NOT EXISTS idx_pending ON wp_lb_addons_trendy_views (collected, creator_username)')

    -- Scheduled payout thread
    Citizen.CreateThread(function()
        if not Config.TrendyPayoutInterval or Config.TrendyPayoutInterval <= 0 then return end
        while true do
            Citizen.Wait(Config.TrendyPayoutInterval * 60 * 1000)

            if payoutRunning then goto continue end
            payoutRunning = true

            local ok, err = pcall(function()
                local fee  = Config.PlatformFeePercent or 0
                local unit = math.floor((Config.TrendyViewPayout or 0) * (1 - fee / 100))
                if unit <= 0 then return end

                -- Single JOIN query: pending view counts + creator phone numbers
                local rows = MySQL.query.await([[
                    SELECT tv.creator_username, COUNT(*) AS views, lia.phone_number
                    FROM wp_lb_addons_trendy_views tv
                    LEFT JOIN phone_logged_in_accounts lia
                        ON lia.username = tv.creator_username AND lia.app = 'TikTok'
                    WHERE tv.collected = 0
                    GROUP BY tv.creator_username, lia.phone_number
                ]])
                if not rows or #rows == 0 then return end

                -- Mark all pending rows collected in one shot before paying out,
                -- so any views that arrive mid-loop are not lost or double-paid.
                MySQL.query('UPDATE wp_lb_addons_trendy_views SET collected = 1 WHERE collected = 0')

                local label = (Config.Locales and Config.Locales.TrendyEarningsLabel) or 'Trendy earnings'
                for _, row in ipairs(rows) do
                    if row.phone_number and row.views > 0 then
                        exports['lb-phone']:AddTransaction(row.phone_number, row.views * unit, label)
                    end
                end
            end)

            if not ok then
                print('^1[wp_lb-addons] TrendyPayout error: ' .. tostring(err) .. '^7')
            end

            payoutRunning = false

            ::continue::
        end
    end)
end)

-- Record a view (no immediate payout — server auto-pays on interval)
RegisterNetEvent('phone:trendy:viewPayout', function(videoId, creatorUsername)
    local source = source

    local xViewer = ESX.GetPlayerFromId(source)
    if not xViewer then return end
    local viewerId = xViewer.identifier

    creatorUsername = MySQL.scalar.await(
        'SELECT username FROM phone_tiktok_videos WHERE id = ?',
        { videoId }
    )
    if not creatorUsername then return end

    -- INSERT IGNORE: viewer/creator pair is unique — no double-counting
    MySQL.query(
        'INSERT IGNORE INTO wp_lb_addons_trendy_views (viewer_id, creator_username) VALUES (?, ?)',
        { viewerId, creatorUsername }
    )
end)
