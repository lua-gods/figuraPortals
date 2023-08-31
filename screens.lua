-- libraries
local worldRenderer = require("renderer")

-- config
local blockDist = vectors.vec2(3,3)
local renderOnlyWhenCameraMoving = true

-- variables
local worldModelPart = models:newPart("screenWorld", "World")
local lib = {}
local screens = {}
local backgroundTexture = textures:newTexture("backgroundScreenTexture", 1, 1):setPixel(0, 0, 1, 1, 1)

-- functions`
local function rebuild(screen)
   -- remove previous sprites
   for _, sprite in pairs(screen.sprites) do
      sprite:remove()
   end
   screen.vertices = {}
   
   -- force screen to update
   screen.needToUpdate = true

   -- calculate some things
   local scaleFix = vec(1, 1, -1)
   local reversedTargetRot = matrices.rotation3(screen.targetRot):transpose()

   -- sprites offset
   local spritesOffset = vec(math.floor(-screen.size.x * 0.5), math.floor(-screen.size.y * 0.5), math.max(blockDist.x,blockDist.y))

   -- mirror
   if screen.mirror then
      spritesOffset.z = -spritesOffset.z
      scaleFix.z = 1
   end

   -- rotate sprite offset
   spritesOffset = (spritesOffset * matrices.rotation3(screen.targetRot) + 0.5):floor()
   
   -- generate sprites for blocks
   screen.sprites = worldRenderer(screen.targetPos + spritesOffset, blockDist, screen.modelpart)

   -- fix sprite offset
   spritesOffset = spritesOffset * 16
   -- go through all sprites and add them to list
   screen.vertices.world = {}
   for _, sprite in pairs(screen.sprites) do
      local spritePos = sprite:getPos() + spritesOffset
      local spriteScale = sprite:getScale()
      local rotMatrix = matrices.rotation3(sprite:getRot())
      sprite:pos():rot():scale():setLight(15, 15)
      local spriteVertices = {sprite = sprite}
      table.insert(screen.vertices.world, spriteVertices)
      for _, vertex in pairs(sprite:getVertices()) do
         local vertexPos = vertex:getPos()
         if screen.mirror then
            vertexPos.x = 16 - vertexPos.x
            local uv = vertex:getUV()
            uv.x = -uv.x
            vertex:setUV(uv)
         end
         table.insert(spriteVertices, {
            (vertexPos * spriteScale * rotMatrix - spritePos) * reversedTargetRot * scaleFix,
            vertex
         })
      end
   end
end

function lib.newScreen(size, pos, rot, targetPos, targetRot, disabled, mirror)
   local screenModelPartname = "screen"..(#screens + 1)
   local modelpart = worldModelPart[screenModelPartname] or worldModelPart:newPart(screenModelPartname)

   local screen = {
      -- data
      modelpart = modelpart,
      sprites = {},
      vertices = {},
      size = size,
      pos = pos,
      rot = rot,
      targetPos = targetPos or pos,
      targetRot = targetRot or rot,
      lastOffset = vec(0, 0, 0),
      needToUpdate = false,
      -- apis
      rebuild = rebuild,
      clampFunc = nil,
      disabled = disabled or false,
      background = true,
      backgroundColor = vec(0, 0, 0),
      mirror = mirror or false
   }

   screen.backgroundSprite = screen.modelpart:newSprite("bg")
      :texture(backgroundTexture, 1, 1)
      :scale(size.x * 16, size.y * 16, 1)
      :light(15, 15)
      :renderType("translucent_cull")
      :pos(0, 0, -0.05)

   table.insert(screens, screen)

   screen:rebuild()

   return screen
end

function lib.getScreens()
   return screens
end

-- render
local function defaultclampFunc(pos, size)
   return vec(
      math.clamp(pos.x, 0, size.x * 16),
      math.clamp(pos.y, 0, size.y * 16)
   )
end

local function depthMatrix(offset, depth, size)
   local mat = matrices.mat3()

   -- calculate size that should be used
   local scale = offset.z / (offset.z + depth)

   local translate = offset.xy * 16 / size -- translate to scale at camera xz

   -- do operations on matrix
   mat:translate(translate)
   mat:scale(scale, scale, 1)
   mat:translate(-translate)

   -- return matrix
   return mat
end

local function needRender(offset, screen)
   -- dont render screen if its disabled
   if screen.disabled then
      return false
   end
   -- dont render if behind screen
   if offset.z > 0 then
      return false
   end
   -- stop rendering when too far
   if offset:length() > 96 then
      return false
   end
   -- get points and convert to screen space
   local rotMat = matrices.rotation3(screen.rot)
   local p1 = vectors.worldToScreenSpace(screen.pos)
   local p2 = vectors.worldToScreenSpace(screen.pos - screen.size.x__ * rotMat)
   local p3 = vectors.worldToScreenSpace(screen.pos - screen.size._y_ * rotMat)
   local p4 = vectors.worldToScreenSpace(screen.pos - screen.size.xy_ * rotMat)
   -- stop rendering if all points are behind camera
   if p1.z < 1 and p2.z < 1 and p3.z < 1 and p4.z < 1 and p1.z > 0 and p2.z > 0 and p3.z > 0 and p4.z > 0 then
      return false
   end
   -- calculate smallest and biggest position
   local min = vec(math.min(p1.x, p2.x, p3.x, p4.x), math.min(p1.y, p2.y, p3.y, p4.y))
   local max = vec(math.max(p1.x, p2.x, p3.x, p4.x), math.max(p1.y, p2.y, p3.y, p4.y))
   -- stop if rectange containing all points is outside of camera
   if min.x > 1 and min.y > 1 and max.x < 1 and max.y < 1 then
      return false
   end
   -- allow rendering
   return true
end

local function renderScreen(camera, screen)
   local offset = (camera - screen.pos) * matrices.rotation3(screen.rot):transpose()
   
   if not needRender(offset, screen) then
      screen.modelpart:setVisible(false)
      return
   end
   screen.modelpart:setVisible(true)
   screen.modelpart:setPos(screen.pos * 16)
   screen.modelpart:setRot(screen.rot)
   screen.backgroundSprite:setVisible(screen.background)
   screen.backgroundSprite:setColor(screen.backgroundColor)

   local minimumDistance = math.clamp(offset.z * -0.001, 0.005, 0.01)
   if screen.needToUpdate then
      screen.needToUpdate = false
   elseif (screen.lastOffset - offset):length() < minimumDistance and renderOnlyWhenCameraMoving then
      return
   end
   screen.lastOffset = offset:copy()

   local clampFunc = screen.clampFunc or defaultclampFunc
   
   local size = screen.size
   
   local depthoffset = 0.5

   offset.xy = offset.xy * size
   offset.z = math.abs(offset.z) * 16
   
   local depthMatrixCache = {}
   for _, verticesGroup in pairs(screen.vertices) do
      for _, spriteGroup in pairs(verticesGroup) do
         local visible = false
         for _, data in ipairs(spriteGroup) do
            local pos, vertex = data[1], data[2]
            visible = visible or pos.z >= 0
            local depth = math.max(pos.z, 0)
            local mat = depthMatrixCache[depth]
            if not mat then
               mat = depthMatrix(offset, depth, size)
               depthMatrixCache[depth] = mat
            end
            if mat.c3.x+8 > 0 and size.x * 16 > mat.c3.x - 8 and mat.c3.y+8 > 0 and size.y * 16 > mat.c3.y - 8 then
               local newPos = pos.xy:augmented(1) * mat
               local renderOffset = pos.z * 0.0025 - depthoffset
               newPos = clampFunc(newPos.xy, size)
               vertex:setPos(newPos.x, newPos.y, renderOffset)
            else
               vertex:setPos(0, 0, 99999999)
            end
         end
         spriteGroup.sprite:setVisible(visible)
      end
   end
end

function events.world_render()
   local camera = client:getCameraPos()
   for _, screen in pairs(screens) do
      renderScreen(camera, screen)
   end
end

-- return library
return lib