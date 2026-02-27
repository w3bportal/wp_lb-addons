-- Patches lb-phone's index.html to load the wp_lb-addons overlay script.
-- Runs whenever wp_lb-addons or lb-phone starts, so lb-phone updates are handled automatically.
-- Bump SCRIPT_VERSION whenever donate-overlay.js changes to force a cache refresh.

local SCRIPT_VERSION = 11
local SCRIPT_BASE    = 'https://cfx-nui-wp_lb-addons/ui/donate-overlay.js'
local SCRIPT_TAG     = '<script src="' .. SCRIPT_BASE .. '?v=' .. SCRIPT_VERSION .. '"></script>'

local function patchIndexHtml()
    local indexPath = GetResourcePath('lb-phone') .. '/ui/dist/index.html'

    local file = io.open(indexPath, 'r')
    if not file then
        print('^1[wp_lb-addons] ERROR: Could not open ' .. indexPath .. '^7')
        return false
    end
    local content = file:read('*a')
    file:close()

    -- Already on the correct version — nothing to do
    if content:find(SCRIPT_TAG, 1, true) then
        return false
    end

    -- Remove any existing donate-overlay script tag (handles old resource names too)
    local cleaned = content:gsub('<script src="https://cfx%-nui%-wp_[^/]*/ui/donate%-overlay%.js[^"]*"></script>\n?', '')
    local patched  = cleaned:gsub('(</body>)', '    ' .. SCRIPT_TAG .. '\n    %1')

    local out = io.open(indexPath, 'w')
    if not out then
        print('^1[wp_lb-addons] ERROR: Could not write to ' .. indexPath .. '^7')
        return false
    end
    out:write(patched)
    out:close()

    return true
end

-- Expose config to other resources (e.g. lb-phone/server/custom/functions/wp_lb_addons.lua)
exports('getConfig', function() return Config end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() and resourceName ~= 'lb-phone' then
        return
    end

    local wasPatched = patchIndexHtml()

    if wasPatched then
        print('^2[wp_lb-addons] lb-phone patched successfully^7')
        print('^3[wp_lb-addons] Restarting lb-phone to apply changes...^7')
        Citizen.SetTimeout(1000, function()
            ExecuteCommand('restart lb-phone')
        end)
    end
end)
