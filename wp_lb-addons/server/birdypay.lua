-- wp_lb-addons Birdy (Twitter) pay-per-interaction handler
-- On each interval, new likes / retweets / replies on posts since the last
-- payout are counted and the post owner is credited via lb-phone's wallet.
--
-- FIRST RUN: existing interaction counts are used as the baseline so that
-- only *new* interactions after setup are ever paid out.

local payoutRunning = false

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS wp_lb_addons_birdy_payouts (
            tweet_id      VARCHAR(10)  NOT NULL,
            paid_likes    INT          NOT NULL DEFAULT 0,
            paid_retweets INT          NOT NULL DEFAULT 0,
            paid_replies  INT          NOT NULL DEFAULT 0,
            PRIMARY KEY (tweet_id)
        ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
    ]])

    MySQL.query.await('ALTER TABLE wp_lb_addons_birdy_payouts ADD COLUMN IF NOT EXISTS paid_replies INT NOT NULL DEFAULT 0')

    Citizen.CreateThread(function()
        if not Config.BirdyPayoutInterval or Config.BirdyPayoutInterval <= 0 then return end

        while true do
            Citizen.Wait(Config.BirdyPayoutInterval * 60 * 1000)
            RunBirdyPayout()
        end
    end)
end)

function RunBirdyPayout()
    if payoutRunning then return end
    payoutRunning = true

    local ok, err = pcall(function()
        local fee           = Config.PlatformFeePercent or 0
        local multiplier    = 1 - fee / 100
        local likePayout    = math.floor((Config.BirdyLikePayout    or 0) * multiplier)
        local retweetPayout = math.floor((Config.BirdyRetweetPayout or 0) * multiplier)
        local replyPayout   = math.floor((Config.BirdyReplyPayout   or 0) * multiplier)

        if likePayout <= 0 and retweetPayout <= 0 and replyPayout <= 0 then return end

        local maxAge        = Config.BirdyPayoutMaxAge or 0
        local verifiedOnly  = Config.RequireVerifiedBirdy or false

        local ageClause      = maxAge > 0
            and ('AND t.timestamp >= DATE_SUB(NOW(), INTERVAL ' .. tonumber(maxAge) .. ' DAY)')
            or  ''
        local verifiedClause = verifiedOnly and 'AND a.verified = 1' or ''

        local rows = MySQL.query.await(string.format([[
            SELECT
                t.id            AS tweet_id,
                t.username,
                t.like_count,
                t.retweet_count,
                t.reply_count,
                p.paid_likes,
                p.paid_retweets,
                p.paid_replies,
                lia.phone_number
            FROM phone_twitter_tweets t
            INNER JOIN phone_twitter_accounts a
                ON a.username = t.username
            LEFT JOIN wp_lb_addons_birdy_payouts p
                ON p.tweet_id = t.id
            LEFT JOIN phone_logged_in_accounts lia
                ON lia.username = t.username AND lia.app = 'Twitter'
            WHERE 1=1 %s %s
        ]], ageClause, verifiedClause))

        if not rows or #rows == 0 then return end

        -- Aggregate earnings per phone number so each account gets one wallet entry.
        -- Build one upsert values list for all baseline updates (new + existing tweets).
        local earningsByPhone    = {}
        local upsertPlaceholders = {}
        local upsertParams       = {}
        local label = (Config.Locales and Config.Locales.BirdyEarningsLabel) or 'Birdy earnings'

        for _, row in ipairs(rows) do
            local curLikes    = row.like_count    or 0
            local curRetweets = row.retweet_count or 0
            local curReplies  = row.reply_count   or 0

            if row.paid_likes ~= nil then
                -- Known tweet: calculate delta and accumulate earnings
                local deltaLikes    = math.max(0, curLikes    - row.paid_likes)
                local deltaRetweets = math.max(0, curRetweets - row.paid_retweets)
                local deltaReplies  = math.max(0, curReplies  - row.paid_replies)

                local earnings = deltaLikes * likePayout
                               + deltaRetweets * retweetPayout
                               + deltaReplies  * replyPayout

                if earnings > 0 and row.phone_number then
                    earningsByPhone[row.phone_number] = (earningsByPhone[row.phone_number] or 0) + earnings
                end
            end
            -- Both new and existing tweets go into the bulk upsert.
            -- New tweets:      INSERT sets the baseline (no prior paid counts = no delta).
            -- Existing tweets: ON DUPLICATE KEY UPDATE advances baseline via GREATEST().
            table.insert(upsertPlaceholders, '(?, ?, ?, ?)')
            table.insert(upsertParams, row.tweet_id)
            table.insert(upsertParams, curLikes)
            table.insert(upsertParams, curRetweets)
            table.insert(upsertParams, curReplies)
        end

        -- Single bulk upsert replaces all per-row INSERT/UPDATE queries
        MySQL.query(
            'INSERT INTO wp_lb_addons_birdy_payouts (tweet_id, paid_likes, paid_retweets, paid_replies) VALUES '
            .. table.concat(upsertPlaceholders, ', ')
            .. [[ ON DUPLICATE KEY UPDATE
                paid_likes    = GREATEST(paid_likes,    VALUES(paid_likes)),
                paid_retweets = GREATEST(paid_retweets, VALUES(paid_retweets)),
                paid_replies  = GREATEST(paid_replies,  VALUES(paid_replies))]],
            upsertParams
        )

        -- One AddTransaction per unique account with accumulated earnings
        for phone, earnings in pairs(earningsByPhone) do
            exports['lb-phone']:AddTransaction(phone, earnings, label)
        end
    end)

    if not ok then
        print('^1[wp_lb-addons] BirdyPayout error: ' .. tostring(err) .. '^7')
    end

    payoutRunning = false
end
