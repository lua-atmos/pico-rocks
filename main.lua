require "atmos.env.pico"

pico.set.title "The Battle of Ships"
local dim = {w=640,h=480}
pico.set.view { grid=false, window=dim, world=dim }

math.randomseed()

local Battle = require "battle" -- actual battle gameplay

call(function ()

    -- BACKGROUND
    spawn(function ()
        local p = { 'C', x=0.5, y=0.5 }
        every('draw', function ()
            pico.output.draw.image("imgs/bg.png", p)
        end)
    end)

    -- POINTS
    local points = { L=0, R=0 }
    spawn(function ()
        local l = { 'C', x=0.1, y=0.9, h=0.075 }
        local r = { 'C', x=0.9, y=0.9, h=0.075 }
        every('draw', function ()
            pico.set.color.draw "white"
            pico.output.draw.text(points.L, l)
            pico.output.draw.text(points.R, r)
        end)
    end)

    -- MAIN LOOP:
    --  * shows the "press enter to start" message
    --  * runs the next battle
    --  * restarts whenever one of the ships is destroyed

    while true do

        -- Start with 'ENTER':
        --  * spawns a blinking message, and awaits "enter" key
        watching('key.dn', 'Return', function ()
            while true do
                -- 500ms on
                watching(clock{ms=500}, function ()
                    local pt = { 'C', x=0.5, y=0.5, h=0.075 }
                    every('draw', function ()
                        pico.set.color.draw "white"
                        pico.output.draw.text("= PRESS ENTER TO START =", pt)
                    end)
                end)
                -- 500ms off
                await(clock{ms=500})
            end
        end)

        -- plays the restart sound
        pico.output.sound "snds/start.wav"

        -- spawns the actual battle
        local battle = spawn(Battle)

        -- Pause with 'P':
        --  * awaits 'P' to toggle battle off
        --  * shows a "paused" image
        --  * awaits 'P' to toggle battle on
        local _ <close> = spawn(function ()
            while true do
                await('key.dn', 'P')
                toggle(battle, false)
                local _ <close> = spawn(function ()
                    local pt = { 'C', x=0.5, y=0.5 }
                    every('draw', function ()
                        pico.output.draw.image("imgs/pause.png", pt)
                    end)
                end)
                await('key.dn', 'P')
                toggle(battle, true)
            end
        end)

        -- Battle terminates:
        --  * awaits battle to return winner
        --  * increments winner points
        --  * awaits 1s before next battle
        local winner = await(battle)
        points[winner] = points[winner] + 1
        await(clock{s=1})
    end
end)
