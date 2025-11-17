require "atmos.env.pico"
pico = require "pico"

W, H = 640, 480

pico.set.title "The Battle of Ships"
pico.set.size.window(W, H)
pico.set.font(nil, H/15)

math.randomseed()

local Battle = require "battle" -- actual battle gameplay

call(function ()

    -- BACKGROUND
    spawn(function ()
        local pt = pico.pos(50, 50)
        every('draw', function ()
            pico.output.draw.image(pt, "imgs/bg.png")
        end)
    end)

    -- POINTS
    local points = { L=0, R=0 }
    spawn(function ()
        local l = pico.pos(10, 90)
        local r = pico.pos(90, 90)
        every('draw', function ()
            pico.set.color.draw(0xFF, 0xFF, 0xFF)
            pico.output.draw.text(l, points.L)
            pico.output.draw.text(r, points.R)
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
                    local pt = pico.pos(50, 50)
                    every('draw', function ()
                        pico.set.color.draw(0xFF, 0xFF, 0xFF)
                        pico.output.draw.text(pt, "= PRESS ENTER TO START =")
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
                    local pt = pico.pos(50, 50)
                    every('draw', function ()
                        pico.output.draw.image(pt, "imgs/pause.png")
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
