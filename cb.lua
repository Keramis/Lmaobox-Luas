--holy shit can we please predict when the player will hit the ground?
--we can, but not when crouching comes into play....

CrouchOffset = 20 --distance the legs move up when you crouch.
Acceleration = 800/66.67 --sv_gravity = 800(hu/s^2), 66.67 ticks per second. This is the value that you will add to your Z velocity every game tick.
Gravity = 800 --gravity is always 800 hu/s^2 in-game.

local function isOnGround(player)
    local pFlags = player:GetPropInt("m_fFlags")
    return (pFlags & FL_ONGROUND) == 1
end

local function printV3(v3)
    local x, y, z = v3:Unpack()
    print("VectorPrint: " .. x .. " | " .. y .. " | " .. z)
end
local myfont = draw.CreateFont( "Veranda", 30, 300 )


local function showTextCentered(screenx, screeny, text)
    local tw, th = draw.GetTextSize( text )
    local x = math.ceil(screenx - (tw/2))
    local y = math.ceil(screeny - (th/2))
    draw.Text(x, y, text)
end

local function decimateNumber(num, decPlace)
    local height = 10^decPlace
    local n = num * height
    n = math.floor(n)
    return (n/height)
end

--draws a rectangle based on the world v3 coordinates, with width and height spread evenly.
local function rectWorldCentered(v3, w, h)
    local pos = client.WorldToScreen( v3 )
    --print(pos[1] .. " || " .. pos[2])
    local x = pos[1]; local y = pos[2]
    local startX = x + w/2; local endY = y + h/2
    local endX = x - w/2; local startY = y - h/2
    draw.Color(255, 255, 0, 255)
    draw.FilledRect(startX, startY, endX, endY)
end

local landingPredictionV3 = nil;
local newpos = false;

callbacks.Register("CreateMove", "landingPredict", function()
    local localPlayer = entities.GetLocalPlayer()
    if isOnGround(localPlayer) then return end
    local velocity = localPlayer:EstimateAbsVelocity()
    local origin = localPlayer:GetAbsOrigin()
    local down = Vector3(origin.x, origin.y, origin.z - 2000)
    local downAdded = vector.Add(down, velocity)
    local trace = engine.TraceLine( origin, downAdded, MASK_SOLID )
    --get endpoint of trace (whatever it hit)
    local endpos = trace.endpos
    --print(endpos.x .. " | " .. endpos.y .. " | " .. endpos.z)
    landingPredictionV3 = endpos --for drawing it
    newpos = true
end)

local fMove = nil
local sMove = nil

callbacks.Register("CreateMove", "crouchPredict", function(cmd)
    fMove = cmd.forwardmove
    sMove = cmd.sidemove
    if not input.IsButtonDown( KEY_LSHIFT ) then return end
    local localPlayer = entities.GetLocalPlayer()
    if isOnGround(localPlayer) then return end --have to not be on ground...
    local vel = localPlayer:EstimateAbsVelocity()
    cmd:SetButtons(cmd.buttons | IN_DUCK) --have to be crouching (unduck last tick)
    local orig = localPlayer:GetAbsOrigin()
    if (vel.z > 0) then return end --gotta be falling!

    if (orig.z + (vel.z/66.67) - CrouchOffset) < landingPredictionV3.z then
        --going to hit ground next tick if we uncrouch
        cmd:SetButtons(cmd.buttons & (~IN_DUCK))
        cmd:SetButtons(cmd.buttons | IN_JUMP)
    end

end)

callbacks.Register("Draw", "drawForwardMove", function()
    if fMove == nil or sMove == nil then return end
    draw.SetFont( 1 )
    draw.Color(255, 100, 100, 255)
    draw.Text(100, 200, "SideMove: " .. sMove)
    draw.Text(100, 250, "ForwardMove: " .. fMove)
end)