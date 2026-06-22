local SHIP_FRAMES   = 4
local SHIP_ACC_DIV  = 10
local SHIP_VEL_MAX  = { '%', x=0.4, y=0.4 }
local SHOT_COLOR    = { r=0xFF, g=0xFF, b=0x88 }
local METEOR_FRAMES = 6
local METEOR_AWAIT  = 5000

function between (min, v, max)
    if v < min then
        return min
    elseif v > max then
        return max
    else
        return v
    end
end

function random_signal ()
    return ((math.random(0,1)==1) and 1) or -1
end

-- Simple "physics" to update Meteor/Shot `rect` position based on `vel` speed:
--  * updates rect every 'step' frame
--  * terminates when rect leaves the screen

Move_T = task(function (rect, vel)
    local function out_of_screen ()
        return (
            rect.x < 0  or
            rect.x > 1  or
            rect.y < 0  or
            rect.y > 1
        )
    end
    watching(out_of_screen, function ()
        loop_on('clock', function (us)
            local ms = us / 1000
            local dt = ms / 1000
            rect.x = rect.x + (vel.x * dt)
            rect.y = rect.y + (vel.y * dt)
        end)
    end)
end)

local meteors = pico.layer.images (
    nil,
    "meteor",
    "imgs/meteor.gif",
    {'#', w=METEOR_FRAMES, h=1}
)

Meteor = task(function ()
    local y_sig = random_signal()

    local vx = math.random()/5 * random_signal()
    local vy = math.random()/5 * y_sig

    local frame = 1

    local x = math.random()
    local y = (y_sig == 1) and 0 or 1
    local rect = { '%', x=x, y=y, w=0.075, h=0.075 }
    xtask().tag  = 'M'
    xtask().rect = rect

    par_any(function ()
        local dt = math.random(1, METEOR_AWAIT)
        await(dt*_ms_)
        par_any(function ()
            await(spawn (Move_T, rect, {x=vx,y=vy}))
        end, function ()
            await('collided')
            pico.output.sound "snds/meteor.wav"
        end)
    end, function ()
        loop_on('draw', function ()
            pico.output.draw.layer(meteors[frame], rect)
        end)
    end, function ()
        local v = ((vx^2) + (vy^2)) ^ (1/2)
        local x = 0
        loop_on('clock', function (us)
            local ms = us / 1000
            x = x + v * ms
            frame = (x//50 % METEOR_FRAMES) + 1
        end)
    end)
end)

Shot = task(function (V, pos, vy)
    pico.output.sound "snds/shot.wav"
    local rect = { '%', x=pos.x, y=pos.y, w=0.02, h=0.01 }
    xtask().tag = V.tag
    xtask().rect = rect
    par_any(function ()
        await('collided')
    end, function ()
        await(spawn (Move_T, rect, {x=V.x*0.33, y=vy}))
    end, function ()
        loop_on('draw', function ()
            pico.set.pencil { color=SHOT_COLOR }
            pico.output.draw.rect(rect)
        end)
    end)
end)

local ships = {
    ["imgs/ship-L.gif"] = pico.layer.images (
        nil,
        "imgs/ship-L.gif",
        "imgs/ship-L.gif",
        {'#', w=1, h=SHIP_FRAMES}
    ),
    ["imgs/ship-R.gif"] = pico.layer.images(
        nil,
        "imgs/ship-R.gif",
        "imgs/ship-R.gif",
        {'#', w=1, h=SHIP_FRAMES}
    ),
}

Ship = task(function (V, shots)
    local frames = ships[V.img]
    local vel = {x=0,y=0}
    local rect = { '%', x=V.pos, y=0.5, w=0.075, h=0.075 }
    xtask().tag = V.tag
    xtask().rect = rect

    local acc = {x=0,y=0}
    local key
    do_spawn(function ()
        par(function ()
            loop_on('key.dn', function (evt)
                if false then
                elseif evt.key == V.ctl.move.l then
                    acc.x = -0.1
                elseif evt.key == V.ctl.move.r then
                    acc.x =  0.1
                elseif evt.key == V.ctl.move.u then
                    acc.y = -0.1
                elseif evt.key == V.ctl.move.d then
                    acc.y =  0.1
                elseif evt.key == V.ctl.shot then
                    spawn_in(shots, Shot, V.shot, {'%',x=rect.x,y=rect.y}, vel.y)
                end
                key = evt.key
            end)
        end, function ()
            loop_on('key.up', function ()
                key = nil
                acc = {x=0,y=0}
            end)
        end)
    end)

    watching('collided', function ()
        par(function ()
            loop_on('draw', function ()
                local frame = 0; do
                    if false then
                    elseif key == V.ctl.move.l then
                        frame = V.ctl.frame.l
                    elseif key == V.ctl.move.r then
                        frame = V.ctl.frame.r
                    elseif key == V.ctl.move.u then
                        frame = V.ctl.frame.u
                    elseif key == V.ctl.move.d then
                        frame = V.ctl.frame.d
                    end
                end
                pico.output.draw.layer(frames[frame+1], rect)
            end)
        end, function ()
            loop_on('clock', function (us)
                local ms = us / 1000
                local dt = ms / 1000
                vel.x = between(-SHIP_VEL_MAX.x, vel.x+(acc.x*dt), SHIP_VEL_MAX.x)
                vel.y = between(-SHIP_VEL_MAX.y, vel.y+(acc.y*dt), SHIP_VEL_MAX.y)

                local x = rect.x + (vel.x*dt)
                local y = rect.y + (vel.y*dt)
                rect.x = between(V.lim.x1, x, V.lim.x2)
                rect.y = between(0.04, y, 0.96)
            end)
        end)
    end)

    watching(100*_ms_, function ()
        local d = 0;
        par(function ()
            loop_on('clock', function (us)
                local ms = us / 1000
                d = d + ms/500
            end)
        end, function ()
            loop_on('draw', function ()
                pico.set.pencil { color='red' }
                pico.output.draw.oval { '%', x=rect.x, y=rect.y, w=d, h=d }
            end)
        end)
    end)

    return xtask().tag
end)
