-- Patches lb-phone's index.html to load the wp_lb-addons overlay script.
-- Runs whenever wp_lb-addons or lb-phone starts, so lb-phone updates are handled automatically.
-- Bump SCRIPT_VERSION whenever donate-overlay.js changes to force a cache refresh.

local SCRIPT_VERSION = 11
local SCRIPT_BASE    = 'https://cfx-nui-wp_lb-addons/ui/donate-overlay.js'
local SCRIPT_TAG     = '<script src="' .. SCRIPT_BASE .. '?v=' .. SCRIPT_VERSION .. '"></script>'

-- lb-phone cache-busts its built UI by bumping the build folder (ui/dist -> ui/dist2 -> ...)
-- and may rename the entry page (index.html -> index2.html). The OLD hardcoded
-- 'ui/dist/index.html' silently fails on any such build (file not found -> overlay never
-- loads -> donate buttons don't show). Read the REAL page from lb-phone's fxmanifest
-- `ui_page` so we always patch the exact file the client actually loads.
local function getIndexPath()
    local base = GetResourcePath('lb-phone')
    if not base then return nil end

    local mf = io.open(base .. '/fxmanifest.lua', 'r')
    if mf then
        local manifest = mf:read('*a')
        mf:close()
        -- ui_page "ui/dist7/index2.html"  (single or double quotes)
        local page = manifest:match('ui_page%s+[\'"]([^\'"]+)[\'"]')
        if page then
            page = page:gsub('^@[%w_%-]+/', '') -- strip a leading @resource/ if present
            return base .. '/' .. page
        end
    end

    -- Fallback: classic path (vanilla lb-phone that never bumped its build folder).
    return base .. '/ui/dist/index.html'
end

local function patchIndexHtml()
    local indexPath = getIndexPath()
    if not indexPath then
        print('^1[wp_lb-addons] ERROR: lb-phone resource not found.^7')
        return false
    end

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

    -- Remove any existing donate-overlay script tag (handles old resource names / versions)
    local cleaned = content:gsub('<script src="https://cfx%-nui%-wp_[^/]*/ui/donate%-overlay%.js[^"]*"></script>\n?', '')
    local patched = cleaned:gsub('(</body>)', '    ' .. SCRIPT_TAG .. '\n    %1')

    local out = io.open(indexPath, 'w')
    if not out then
        print('^1[wp_lb-addons] ERROR: Could not write to ' .. indexPath .. '^7')
        return false
    end
    out:write(patched)
    out:close()

    print('^2[wp_lb-addons] Patched ' .. indexPath .. '^7')
    return true
end

-- Expose config to other resources (e.g. lb-phone/server/custom/functions/wp_lb_addons.lua)
exports('getConfig', function() return Config end)

AddEventHandler('onResourceStart', function(resourceName)
    local self = GetCurrentResourceName()
    if resourceName ~= self and resourceName ~= 'lb-phone' then
        return
    end

    local wasPatched = patchIndexHtml()
    if not wasPatched then
        return
    end

    if resourceName == self then
        -- Safe to restart: lb-phone is a dependency, so it is already fully booted by the
        -- time wp_lb-addons starts. This delivers the overlay to currently-connected players.
        print('^3[wp_lb-addons] Restarting lb-phone to apply...^7')
        Citizen.SetTimeout(1000, function()
            ExecuteCommand('restart lb-phone')
        end)
    else
        -- Patched during lb-phone's OWN start: do NOT restart it here. Restarting lb-phone
        -- mid-boot tears a player's phone down and can leave it stuck on the loading screen.
        -- The tag is on disk now and applies on lb-phone's next natural start.
        print('^3[wp_lb-addons] Run `restart wp_lb-addons` (or restart lb-phone) once to apply.^7')
    end
end)
