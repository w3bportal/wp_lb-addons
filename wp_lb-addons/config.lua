Config = {}

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
Config.TrendyViewPayout    = 10     -- $ per unique view (one-time per viewer)
Config.TrendyPayoutInterval = 60    -- minutes between payouts (0 = off)

-- Birdy
Config.RequireVerifiedBirdy = false  -- payouts to verified accounts only
Config.BirdyLikePayout     = 5      -- $ per new like
Config.BirdyRetweetPayout  = 10     -- $ per new retweet
Config.BirdyReplyPayout    = 3      -- $ per new reply
Config.BirdyPayoutInterval = 30     -- minutes between payouts (0 = off)
Config.BirdyPayoutMaxAge   = 7      -- max post age in days to pay (0 = all)

Config.Locales = {
    -- InstaPic
    InstaPicAppName         = 'InstaPic',
    DonateTooltip           = 'Donate',
    DonateBtnLabel          = 'Donate $%d',
    DonateNotVerified       = 'This streamer is not verified.',
    DonateInsufficientFunds = 'Insufficient funds to donate.',
    DonateReceivedTitle     = 'New Donation!',
    DonateReceivedContent   = '%s donated $%d!',
    DonateDeductLabel       = 'Donation to @%s',
    DonateReceiveLabel      = 'Donation from @%s',
    DonateChatMessage       = 'donated $%d!',

    -- Trendy
    TrendyEarningsLabel     = 'Trendy earnings',

    -- Birdy
    BirdyEarningsLabel      = 'Birdy earnings',
}
