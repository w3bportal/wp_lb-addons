RegisterNUICallback("GetWpConfig", function(data, cb)
    cb(exports['wp_lb-addons']:getConfig())
end)

-- ── InstaPic donations ────────────────────────────────────────────────────────

RegisterNUICallback("InstaPicDonate", function(data, cb)
    local streamer = data.streamer
    local amount   = tonumber(data.amount)
    if not streamer or not amount then return cb(false) end
    TriggerServerEvent("phone:instagram:donate", streamer, amount)
    cb(true)
end)

-- ── Trendy view recording ─────────────────────────────────────────────────────

RegisterNUICallback("TrendyViewPayout", function(data, cb)
    local videoId = data.videoId
    if not videoId then return cb(false) end
    TriggerServerEvent("phone:trendy:viewPayout", videoId, data.creatorUsername)
    cb(true)
end)
