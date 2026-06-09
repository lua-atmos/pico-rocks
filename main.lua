require "atmos.env.pico"

pico.set.window { title="The Battle of Ships" }
pico.set.dim {'!', w=640, h=480}

math.randomseed()

loop(function ()
    local Battle = require "battle" -- actual battle gameplay

    -- BACKGROUND
    spawn(function ()
        local p = { '%', x=0.5, y=0.5 }
        every('draw', function ()
            pico.output.draw.image("imgs/bg.png", p)
        end)
    end)

    -- POINTS
    local points = { L=0, R=0 }
    spawn(function ()
        local l = { '%', x=0.1, y=0.9, h=0.075 }
        local r = { '%', x=0.9, y=0.9, h=0.075 }
        every('draw', function ()
            pico.set.pencil { color='white' }
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
        watching({tag='key.dn', key='Return'}, function ()
            while true do
                -- 500ms on
                watching(500*_ms_, function ()
                    local p = { '%', x=0.5, y=0.5, h=0.075 }
                    every('draw', function ()
                        pico.set.pencil { color='white' }
                        pico.output.draw.text("= PRESS ENTER TO START =", p)
                    end)
                end)
                -- 500ms off
                await(500*_ms_)
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
                await{tag='key.dn', key='P'}
                toggle(battle, false)
                local _ <close> = spawn(function ()
                    local p = { '%', x=0.5, y=0.5 }
                    every('draw', function ()
                        pico.output.draw.image("imgs/pause.png", p)
                    end)
                end)
                await{tag='key.dn', key='P'}
                toggle(battle, true)
            end
        end)

        -- Battle terminates:
        --  * awaits battle to return winner
        --  * increments winner points
        --  * awaits 1s before next battle
        local winner = await(battle)
        points[winner] = points[winner] + 1
        await(1*_s_)
    end
end)
