--[[

     Licensed under GNU General Public License v2
      * (c) 2015, Luca CPZ

--]]

local helpers  = require("lain.helpers")
local json     = require("lain.util").dkjson
local focused  = require("awful.screen").focused
local naughty  = require("naughty")
local wibox    = require("wibox")
local math     = math
local os       = os
local io       = io
local string   = string
local type     = type
local tonumber = tonumber

-- OpenWeatherMap
-- current weather and X-days forecast
-- lain.widget.weather

local function factory(args)
    args                        = args or {}

    local weather               = { widget = args.widget or wibox.widget.textbox() }
    local APPID                 = args.APPID -- mandatory
    local timeout               = args.timeout or 60 * 15 -- 15 min
    local current_call          = args.current_call  or "curl -s 'https://api.openweathermap.org/data/2.5/weather?id=%s&units=%s&lang=%s&APPID=%s'"
    local forecast_call         = args.forecast_call or "curl -s 'https://api.openweathermap.org/data/2.5/forecast?id=%s&units=%s&lang=%s&APPID=%s'"
    local city_id               = args.city_id or 0 -- placeholder
    local units                 = args.units or "metric"
    local lang                  = args.lang or "en"
    local cnt                   = args.cnt or 5
    local icons_path            = args.icons_path or helpers.icons_dir .. "openweathermap/"
    local notification_preset   = args.notification_preset or {}
    local notification_text_fun = args.notification_text_fun or
                                  function (wn)
                                      local day = os.date("%a %d", wn["dt"])
                                      local temp = math.floor(wn["main"]["temp"])
                                      local desc = wn["weather"][1]["description"]
                                      return string.format("<b>%s</b>: %s, %d ", day, desc, temp)
                                  end
    local weather_na_markup     = args.weather_na_markup or " N/A "
    local followtag             = args.followtag or false
    local showpopup             = args.showpopup or "on"
    local settings              = args.settings or function() end

    weather.widget:set_markup(weather_na_markup)
    weather.icon_path = icons_path .. "na.png"
    weather.icon = wibox.widget.imagebox(weather.icon_path)

    function weather.show(seconds)
        weather.hide()

        if followtag then
            notification_preset.screen = focused()
        end

        if not weather.notification_text then
            weather.update()
            weather.forecast_update()
        end

        weather.notification = naughty.notify {
            preset  = notification_preset,
            text    = weather.notification_text,
            icon    = weather.icon_path,
            timeout = type(seconds) == "number" and seconds or notification_preset.timeout
        }
    end

    function weather.hide()
        if weather.notification then
            naughty.destroy(weather.notification)
            weather.notification = nil
        end
    end

    function weather.attach(obj)
        obj:connect_signal("mouse::enter", function()
            weather.show(0)
        end)
        obj:connect_signal("mouse::leave", function()
            weather.hide()
        end)
    end

    function weather.forecast_update()
        local cmd = string.format(forecast_call, city_id, units, lang, APPID)
        helpers.async(cmd, function(f)
            local err
            weather_now, _, err = json.decode(f, 1, nil)

            if not err and type(weather_now) == "table" and tonumber(weather_now["cod"]) == 200 then
                weather.notification_text = ""
                for i = 1, weather_now["cnt"], weather_now["cnt"]//cnt do
                    weather.notification_text = weather.notification_text ..
                                                notification_text_fun(weather_now["list"][i])
                    if i < weather_now["cnt"] then
                        weather.notification_text = weather.notification_text .. "\n"
                    end
                end
            end
        end)
    end

    local cache_path = args.cache_path or (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/awesome-weather-" .. tostring(city_id) .. ".json"

    local function cache_write(tbl)
        local ok, encoded = pcall(json.encode, tbl, { indent = false })
        if not ok or not encoded then return end
        local f = io.open(cache_path, "w")
        if not f then return end
        f:write(encoded)
        f:close()
    end

    local function cache_read()
        local f = io.open(cache_path, "r")
        if not f then return nil end
        local s = f:read("*a")
        f:close()
        if not s or s == "" then return nil end
        local obj, _, err = json.decode(s, 1, nil)
        if err or type(obj) ~= "table" then return nil end
        return obj
    end

    function weather.update()
        local cmd = string.format(current_call, city_id, units, lang, APPID)
        helpers.async(cmd, function(f)
            local err
            weather_now, _, err = json.decode(f, 1, nil)

            if not err and type(weather_now) == "table" and tonumber(weather_now["cod"]) == 200 then
                local sunrise = tonumber(weather_now["sys"]["sunrise"])
                local sunset  = tonumber(weather_now["sys"]["sunset"])
                local icon    = weather_now["weather"][1]["icon"]
                local loc_now = os.time()

                if sunrise <= loc_now and loc_now <= sunset then
                    icon = string.gsub(icon, "n", "d")
                else
                    icon = string.gsub(icon, "d", "n")
                end

                weather.icon_path = icons_path .. icon .. ".png"
                widget = weather.widget

                -- Let user settings() compute markup etc as before
                settings()

                -- Try to capture a "current temperature" and markup to cache.
                -- temp: OpenWeatherMap main.temp (already in your payload)
                local temp = nil
                if weather_now["main"] and weather_now["main"]["temp"] then
                    temp = tonumber(weather_now["main"]["temp"])
                end

                cache_write({
                    ts = os.time(),
                    temp = temp,
                    icon_path = weather.icon_path,
                    -- If your settings() sets markup, try to persist it too:
                    markup = widget.get_markup and widget:get_markup() or nil
                })
            else
                -- Fallback: load last known good value
                local cached = cache_read()
                if cached then
                    if cached.icon_path then
                        weather.icon_path = cached.icon_path
                    else
                        weather.icon_path = icons_path .. "na.png"
                    end

                    if cached.markup and weather.widget.set_markup then
                        weather.widget:set_markup(cached.markup)
                    elseif cached.temp then
                        -- If we don't have cached markup, at least show temp
                        weather.widget:set_markup(string.format(" %d ", math.floor(cached.temp)))
                    else
                        weather.widget:set_markup(weather_na_markup)
                    end
                else
                    weather.icon_path = icons_path .. "na.png"
                    weather.widget:set_markup(weather_na_markup)
                end
            end

            weather.icon:set_image(weather.icon_path)
        end)
    end

    if showpopup == "on" then weather.attach(weather.widget) end

    weather.timer = helpers.newtimer("weather-" .. city_id, timeout, weather.update, false, true)
    weather.timer_forecast = helpers.newtimer("weather_forecast-" .. city_id, timeout, weather.forecast_update, false, true)

    return weather
end

return factory
