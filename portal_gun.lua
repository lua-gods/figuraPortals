local screens = require "screens"
local skyColor = require "sky_color"
local lineLibrary = require "GNLineLib"

local color1 = vec(1, 0.56, 0.2)
local color2 = vec(0.2, 0.75, 1)

local enabled = false

local portal1 = screens.newScreen(vec(1, 2), vec(0, -65536, 0), vec(0, 0, 0), nil, nil, true)
local portal1enabled = false
local portal1side = "up"
local portal2 = screens.newScreen(vec(1, 2), vec(0, -65536, 0), vec(0, 0, 0), nil, nil, true)
local portal2enabled = false
local portal2side = "up"

local pixelTexture = textures:newTexture("pixelTexture", 1, 1):setPixel(0, 0, 1, 1, 1)
local modelpart = models:newPart("portalGunPortals", "World")
local frontPortalSprites = {}
modelpart:newPart("portal1")
table.insert(frontPortalSprites, modelpart.portal1:newSprite("front"):texture(pixelTexture, 16, 32):pos(0, 0, -0.1):renderType("end_gateway"))
table.insert(frontPortalSprites, modelpart.portal1:newSprite("front2"):texture(pixelTexture, 16, 32):pos(0, 0, -0.05):color(0, 0, 0):renderType("translucent_cull"))
modelpart.portal1:newSprite("back2"):texture(pixelTexture, 16, 32):rot(0, 180, 0):pos(-16, 0, -0.05):color(0, 0, 0):renderType("translucent_cull")
modelpart.portal1:newSprite("back"):texture(pixelTexture, 16, 32):rot(0, 180, 0):pos(-16, 0, -0.1):renderType("end_gateway")
modelpart:newPart("portal2")
table.insert(frontPortalSprites, modelpart.portal2:newSprite("front"):texture(pixelTexture, 16, 32):pos(0, 0, -0.1):renderType("end_gateway"))
table.insert(frontPortalSprites, modelpart.portal2:newSprite("front2"):texture(pixelTexture, 16, 32):pos(0, 0, -0.05):color(0, 0, 0):renderType("translucent_cull"))
modelpart.portal2:newSprite("back2"):texture(pixelTexture, 16, 32):rot(0, 180, 0):pos(-16, 0, -0.05):color(0, 0, 0):renderType("translucent_cull")
modelpart.portal2:newSprite("back"):texture(pixelTexture, 16, 32):rot(0, 180, 0):pos(-16, 0, -0.1):renderType("end_gateway")

local linesList = {}

local time = 0

local sides = {
   north = {
      rot = vec(0, 0, 0), pos = vec(1, 2, 1), targetRot = vec(0, 180, 0), targetOffset = vec(-1, 0, 0), teleportOffset = vec(-0.5, -2, -0.5), dir = 0
   },
   east = {
      rot = vec(0, -90, 0), pos = vec(0, 2, 1), targetRot = vec(0, 90, 0), targetOffset = vec(0, 0, -1), teleportOffset = vec(0.5, -2, -0.5), dir = 1
   },
   west = {
      rot = vec(0, 90, 0), pos = vec(1, 2, 0), targetRot = vec(0, -90, 0), targetOffset = vec(0, 0, 1), teleportOffset = vec(-0.5, -2, 0.5), dir = 3
   },
   south = {
      rot = vec(0, 180, 0), pos = vec(0, 2, 0), targetRot = vec(0, 0, 0), targetOffset = vec(1, 0, 0), teleportOffset = vec(0.5, -2, 0.5), dir = 2
   },
   up = {
      rot = vec(90, 0, 0), pos = vec(1, 0, 2), targetRot = vec(-90, 180, 0), targetOffset = vec(-1, 0, 0), teleportOffset = vec(-0.5, 0, -1), dir = 0
   },
   up2 = {
      rot = vec(90, -90, 0), pos = vec(-1, 0, 1), targetRot = vec(-90, 90, 0), targetOffset = vec(0, 0, -1), teleportOffset = vec(1, 0, -0.5), dir = 1
   },
   up3 = {
      rot = vec(90, 180, 0), pos = vec(0, 0, -1), targetRot = vec(-90, 0, 0), targetOffset = vec(1, 0, 0), teleportOffset = vec(0.5, 0, 1), dir = 2
   },
   up4 = {
      rot = vec(90, 90, 0), pos = vec(2, 0, 0), targetRot = vec(-90, -90, 0), targetOffset = vec(0, 0, 1), teleportOffset = vec(-1, 0, 0.5), dir = 3
   },
   down = {
      rot = vec(-90, 180, 0), pos = vec(0, 1, 2), targetRot = vec(90, 0, 0), targetOffset = vec(1, 0, 0), teleportOffset = vec(0.5, -2, -1), dir = 0
   },
   down2 = {
      rot = vec(-90, 90, 0), pos = vec(-1, 1, 0), targetRot = vec(90, -90, 0), targetOffset = vec(0, 0, 1), teleportOffset = vec(1, -2, 0.5), dir = 1
   },
   down3 = {
      rot = vec(-90, 0, 0), pos = vec(1, 1, -1), targetRot = vec(90, 180, 0), targetOffset = vec(-1, 0, 0), teleportOffset = vec(-0.5, -2, 1), dir = 2
   },
   down4 = {
      rot = vec(-90, -90, 0), pos = vec(2, 1, 1), targetRot = vec(90, 90, 0), targetOffset = vec(0, 0, -1), teleportOffset = vec(-1, -2, -0.5), dir = 4
   }
}

local placeOffsets = {
   vec(0, 0, 0),
   vec(0, 1, 0),
   vec(0, -1, 0),
   vec(1, 0, 0),
   vec(-1, 0, 0),
}

local function updateLines(portal, color)
   local rotMat = matrices.rotation3(portal.rot)
   local a = portal.pos
   local b = portal.pos - portal.size.x__ * rotMat
   local c = portal.pos - portal.size.xy_ * rotMat
   local d = portal.pos - portal.size._y_ * rotMat
   table.insert(linesList, lineLibrary:newLine():from(a):to(b):depth(-0.05):width(0.05):color(color))
   table.insert(linesList, lineLibrary:newLine():from(b):to(c):depth(-0.05):width(0.05):color(color))
   table.insert(linesList, lineLibrary:newLine():from(c):to(d):depth(-0.05):width(0.05):color(color))
   table.insert(linesList, lineLibrary:newLine():from(d):to(a):depth(-0.05):width(0.05):color(color))

   table.insert(linesList, lineLibrary:newLine():from(a):to(b):depth(-0.025):width(0.1):color(color * 0.5))
   table.insert(linesList, lineLibrary:newLine():from(b):to(c):depth(-0.025):width(0.1):color(color * 0.5))
   table.insert(linesList, lineLibrary:newLine():from(c):to(d):depth(-0.025):width(0.1):color(color * 0.5))
   table.insert(linesList, lineLibrary:newLine():from(d):to(a):depth(-0.025):width(0.1):color(color * 0.5))

   table.insert(linesList, lineLibrary:newLine():from(a):to(b):depth(-0.9):width(0.02):color(color))
   table.insert(linesList, lineLibrary:newLine():from(b):to(c):depth(-0.9):width(0.02):color(color))
   table.insert(linesList, lineLibrary:newLine():from(c):to(d):depth(-0.9):width(0.02):color(color))
   table.insert(linesList, lineLibrary:newLine():from(d):to(a):depth(-0.9):width(0.02):color(color))
end

function pings.portals(enabled1, enabled2, pos1, side1, pos2, side2)
   if enabled1 and enabled2 then
      if not portal1enabled or not portal2enabled or pos1 ~= portal1.pos or pos2 ~= portal2.pos or side1 ~= portal1side or side2 ~= portal2side then
         portal1.targetPos = pos2 + sides[side2].targetOffset
         portal1.targetRot = sides[side2].targetRot
         portal2.targetPos = pos1 + sides[side1].targetOffset
         portal2.targetRot = sides[side1].targetRot
         portal1:rebuild()
         portal2:rebuild()
      end
      portal1.disabled = false
      portal2.disabled = false
   else
      portal1.disabled = true
      portal2.disabled = true
   end
   portal1.pos = pos1
   portal2.pos = pos2
   portal1side = side1
   portal2side = side2
   portal1.rot = sides[side1].rot
   portal2.rot = sides[side2].rot
   portal1enabled = enabled1
   portal2enabled = enabled2

   modelpart.portal1:setPos(pos1 * 16)
   modelpart.portal1:setRot(sides[side1].rot)
   modelpart.portal1:setVisible(enabled1)

   modelpart.portal2:setPos(pos2 * 16)
   modelpart.portal2:setRot(sides[side2].rot)
   modelpart.portal2:setVisible(enabled2)

   for _, v in pairs(frontPortalSprites) do
      v:setVisible(not (enabled1 and enabled2))
   end

   for _, v in pairs(linesList) do
      v:delete()
   end
   linesList = {}

   if enabled1 then updateLines(portal1, color1) end
   if enabled2 then updateLines(portal2, color2) end
end

local function pingPortals(id, enabled, pos, side)
   if id == 1 then
      pings.portals(enabled, portal2enabled, pos, side, portal2.pos, portal2side)
   elseif id == 2 then
      pings.portals(portal1enabled, enabled, portal1.pos, portal1side, pos, side)
   else
      pings.portals(portal1enabled, portal2enabled, portal1.pos, portal1side, portal2.pos, portal2side)
   end
end

function events.world_tick()
   local color = skyColor.getColor()

   portal1.backgroundColor = math.lerp(vec(0.1, 0.1, 0.1), color, math.min(world.getSkyLightLevel(portal2.pos - vec(0.5, 0.5, 0.5) * matrices.rotation3(portal2.rot)) / 4, 1))
   portal2.backgroundColor = math.lerp(vec(0.1, 0.1, 0.1), color, math.min(world.getSkyLightLevel(portal1.pos - vec(0.5, 0.5, 0.5) * matrices.rotation3(portal1.rot)) / 4, 1))

   time = time + 1
   if time % 100 == 0 then
      pingPortals()
   end
end

-- host only
if not host:isHost() then
   return
end

local teleportModes = {
   [0] = "none",
   "command (requires op)",
   "extura (requires extura)",
   "extura with velocity (requires extura)",
}

local currentTeleportMode = 0

local function teleportPlayer(pos, rot, vel)
   if currentTeleportMode == 1 then
      local command = {
         "tp @s ",
         math.round(pos.x * 1000) / 1000, " ",
         math.round(pos.y * 1000) / 1000, " ",
         math.round(pos.z * 1000) / 1000, " ",
         (math.round(rot.y * 100) / 100 + 180) % 360 - 180, " ",
         (math.round(rot.x * 100) / 100 + 90) % 180 - 90
      }

      host:sendChatCommand(table.concat(command))
   elseif currentTeleportMode == 2 or currentTeleportMode == 3 then
      if host.setPos then
         host:setPos(pos)
      end
      if host.setRot then
         host:setRot(rot)
      end
      if currentTeleportMode == 3 and host.setVelocity then
         host:setVelocity(vel)
      end
   end
end

local function setPortal(portalType)
   if not player:isLoaded() then
      return
   end

   local block, pos, side = player:getTargetedBlock()
   if block:isAir() then
      return
   end

   local rot = math.round(player:getRot().y / 90) % 4 + 1
   if rot ~= 1 and sides[side..rot] then
      side = side..rot
   end

   local sideData = sides[side]

   pos = pos - player:getLookDir() * 0.001
   pos = pos:floor()
   pos = pos + sideData.pos

   local rotMat = matrices.rotation3(sideData.rot)

   local secondPortal = portalType == 1 and portal2 or portal1

   local secondPortalPos1 = secondPortal.pos
   local secondPortalPos2 = secondPortal.pos - secondPortal.size.xy:augmented() * matrices.rotation3(secondPortal.rot)
   
   -- min1 < max2 and max1 > min2
   local secondPortalMin = vec(math.min(secondPortalPos1.x, secondPortalPos2.x), math.min(secondPortalPos1.y, secondPortalPos2.y), math.min(secondPortalPos1.z, secondPortalPos2.z))
   local secondPortalMax = vec(math.max(secondPortalPos1.x, secondPortalPos2.x), math.max(secondPortalPos1.y, secondPortalPos2.y), math.max(secondPortalPos1.z, secondPortalPos2.z))
   
   for _, offset in pairs(placeOffsets) do
      local p = pos + rotMat * offset
      local portalPos2 = p - secondPortal.size.xy:augmented() * rotMat
      local portalMin = vec(math.min(p.x, portalPos2.x), math.min(p.y, portalPos2.y), math.min(p.z, portalPos2.z))
      local portalMax = vec(math.max(p.x, portalPos2.x), math.max(p.y, portalPos2.y), math.max(p.z, portalPos2.z))
      if #world.getBlockState(p + vec(-0.5, -0.5, -0.5) * rotMat):getCollisionShape() == 0 and
         #world.getBlockState(p + vec(-0.5, -1.5, -0.5) * rotMat):getCollisionShape() == 0 and
         world.getBlockState(p + vec(-0.5, -0.5, 0.5) * rotMat):isFullCube() and
         world.getBlockState(p + vec(-0.5, -1.5, 0.5) * rotMat):isFullCube() and
         not (portalMin < secondPortalMax and portalMax > secondPortalMin) then
         pingPortals(portalType, true, p, side)
         break
      end
   end
end

local portalGunPressTime = 0
local portalGunKey = keybinds:newKeybind("portal gun", "key.keyboard.grave.accent")
portalGunKey.press = function()
   portalGunPressTime = time
end
portalGunKey.release = function()
   if time > portalGunPressTime + 10 then
      return
   end
   enabled = not enabled
   if enabled then
      host:setActionbar("portal gun enabled")
   else
      host:setActionbar("portal gun disabled")
   end
end

keybinds:fromVanilla("key.attack").press = function()
   if portalGunKey:isPressed() then
      portalGunPressTime = -10
      currentTeleportMode = (currentTeleportMode - 1) % (#teleportModes + 1)
      print("teleport mode:\n"..teleportModes[currentTeleportMode])
      return true
   elseif enabled then
      setPortal(1)
      return true
   end
end
keybinds:fromVanilla("key.use").press = function()
   if portalGunKey:isPressed() then
      portalGunPressTime = -10
      currentTeleportMode = (currentTeleportMode + 1) % (#teleportModes + 1)
      print("teleport mode:\n"..teleportModes[currentTeleportMode])
      return true
   elseif enabled then
      setPortal(2)
      return true
   end
end

local allowTeleport = false
local previousVelocity = vec(0, 0, 0)
function events.tick()
   if currentTeleportMode == 0 or not portal1enabled or not portal2enabled then
      previousVelocity = vec(0, 0, 0)
      return
   end
   local playerPos = player:getPos()
   local playerBoundingBox = player:getBoundingBox()
   local playerMin = playerPos - playerBoundingBox.x_z * 0.5
   local playerMax = playerPos + playerBoundingBox.x_z * 0.5 + playerBoundingBox._y_
   if not allowTeleport then
      playerMin = playerMin - 0.25
      playerMax = playerMax + 0.25
   end

   local portal1Pos1 = portal1.pos
   local portal1Pos2 = portal1.pos - portal1.size.xy:augmented(0.2) * matrices.rotation3(portal1.rot)
   local portal1Min = vec(math.min(portal1Pos1.x, portal1Pos2.x), math.min(portal1Pos1.y, portal1Pos2.y), math.min(portal1Pos1.z, portal1Pos2.z))
   local portal1Max = vec(math.max(portal1Pos1.x, portal1Pos2.x), math.max(portal1Pos1.y, portal1Pos2.y), math.max(portal1Pos1.z, portal1Pos2.z))
   local touchingPortal1 = playerMin < portal1Max and playerMax > portal1Min

   local portal2Pos1 = portal2.pos
   local portal2Pos2 = portal2.pos - portal2.size.xy:augmented(0.2) * matrices.rotation3(portal2.rot)
   local portal2Min = vec(math.min(portal2Pos1.x, portal2Pos2.x), math.min(portal2Pos1.y, portal2Pos2.y), math.min(portal2Pos1.z, portal2Pos2.z))
   local portal2Max = vec(math.max(portal2Pos1.x, portal2Pos2.x), math.max(portal2Pos1.y, portal2Pos2.y), math.max(portal2Pos1.z, portal2Pos2.z))
   local touchingPortal2 = playerMin < portal2Max and playerMax > portal2Min

   if touchingPortal1 or touchingPortal2 then
      if allowTeleport and touchingPortal1 ~= touchingPortal2 then
         local startPortal = touchingPortal1 and portal1 or portal2
         local startPortalSide = sides[touchingPortal1 and portal1side or portal2side]
         local endPortal = touchingPortal2 and portal1 or portal2
         local endPortalSide = sides[touchingPortal2 and portal1side or portal2side]
         local pos = endPortal.pos + endPortalSide.teleportOffset
         local rot = player:getRot()
         rot.y = rot.y - startPortalSide.dir * 90 + endPortalSide.dir * 90 + 180
         local vel = previousVelocity * matrices.rotation3(startPortal.rot):transpose() * matrices.rotation3(0, 180, 0) * matrices.rotation3(endPortal.rot)
         teleportPlayer(pos, rot, vel)
      end
      allowTeleport = false
   else
      allowTeleport = true
   end

   previousVelocity = player:getVelocity()
end