local SHIP_FRAMES   = 4
local SHIP_ACC_DIV  = 10
local SHIP_VEL_MAX  = { '%', x=0.4, y=0.4 }
local SHOT_DIM      = { '%', w=0.02, h=0.01 }
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

function Move_T (rect, vel)
    local function out_of_screen ()
        return (
            rect.x < 0  or
            rect.x > W  or
            rect.y < 0  or
            rect.y > H
        )
    end
    watching(out_of_screen, function ()
        every('clock', function (_,ms)
            local dt = ms / 1000
            rect.x = rect.x + (vel.x * dt)
            rect.y = rect.y + (vel.y * dt)
        end)
    end)
end

function Meteor ()
    local dim = pico.get.image("imgs/meteor.gif")

    local y_sig = random_signal()

    local vx = (1 + (math.random(0,W/5))) * random_signal()
    local vy = (1 + (math.random(0,H/5))) * y_sig

    local w = dim.x / METEOR_FRAMES
    local dx = 0

    local x = math.random(0,W)
    local y = (y_sig == 1) and 0 or H
    local rect = { x=x, y=y, w=w, h=dim.y }
    task().tag  = 'M'
    task().rect = rect

    par_or(function ()
        local dt = math.random(1, METEOR_AWAIT)
        await(clock{ms=dt})
        par_or(function ()
            await(spawn (Move_T, rect, {x=vx,y=vy}))
        end, function ()
            await('collided')
            --pico.output.sound "snds/meteor.wav"
        end)
    end, function ()
        every('draw', function ()
            pico.set.crop { x=dx, y=0, w=w, h=dim.y }
            pico.output.draw.image("imgs/meteor.gif", rect)
            pico.set.crop()
        end)
    end, function ()
        local v = ((vx^2) + (vy^2)) ^ (1/2)
        local x = 0
        every('clock', function (_,ms)
            x = x + ((v * ms) / 1000)
            dx = (x % dim.x) - (x % w)
        end)
    end)
end

function Shot (V, pos, vy)
    --pico.output.sound "snds/shot.wav"
    local rect = { x=pos.x, y=pos.y, w=SHOT_DIM.x, h=SHOT_DIM.y }
    task().tag = V.tag
    task().rect = rect
    par_or(function ()
        await('collided')
    end, function ()
        await(spawn (Move_T, rect, {x=(W/3)*V.x, y=vy}))
    end, function ()
        every('draw', function ()
            pico.set.color.draw(SHOT_COLOR)
            pico.output.draw.rect(rect)
        end)
    end)
end

function Ship (V, shots)
    local dim = pico.get.image(V.img)
    local vel = {x=0,y=0}
    local dy = dim.h / SHIP_FRAMES
    local rect = { 'C', x=0.5, y=0.5, w=dim.w, h=dy }
    task().tag = V.tag
    task().rect = rect

    local acc = {x=0,y=0}
    local key
    spawn(function ()
        par(function ()
            every('key.dn', function (evt)
                if false then
                elseif evt.key == V.ctl.move.l then
                    acc.x = -W/SHIP_ACC_DIV
                elseif evt.key == V.ctl.move.r then
                    acc.x =  W/SHIP_ACC_DIV
                elseif evt.key == V.ctl.move.u then
                    acc.y = -H/SHIP_ACC_DIV
                elseif evt.key == V.ctl.move.d then
                    acc.y =  H/SHIP_ACC_DIV
                elseif evt.key == V.ctl.shot then
                    spawn_in(shots, Shot, V.shot, {x=rect.x,y=rect.y}, vel.y)
                end
                key = evt.key
            end)
        end, function ()
            every('key.up', function ()
                key = nil
                acc = {x=0,y=0}
            end)
        end)
    end)

    watching('collided', function ()
        par(function ()
            every('draw', function ()
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
                pico.set.crop { x=0, y=frame*dy, w=rect.w, h=dy }
print(rect[1], rect.x,rect.y)
                pico.output.draw.image(V.img, rect)
                pico.set.crop()
            end)
        end, function ()
            local H = pico.get.view().world.w
            every('clock', function (_,ms)
                local dt = ms / 1000
                vel.x = between(-SHIP_VEL_MAX.x, vel.x+(acc.x*dt), SHIP_VEL_MAX.x)
                vel.y = between(-SHIP_VEL_MAX.y, vel.y+(acc.y*dt), SHIP_VEL_MAX.y)

                local x = rect.x + (vel.x*dt)
                local y = rect.y + (vel.y*dt)
                rect.x = between(V.lim.x1, x, V.lim.x2-dim.w)
                rect.y = between(0, y, H-dy)
            end)
        end)
    end)

    watching(clock{ms=100}, function ()
        local d = dy / 2;
        par(function ()
            every('clock', function (_,ms)
                d = d + (((15*d)*ms)/1000)
            end)
        end, function ()
            every('draw', function ()
                pico.set.color.draw "red"
                pico.output.draw.oval { x=rect.x, y=rect.y, w=d, h=d }
            end)
        end)
    end)
end
