-- config
local renderConfig = {
   useParticleTexture = true,
   cull = true,
   tinyBlocks = false,
}
-- side map
local sideMap = {
   SOUTH = vec(0, 0, 1),
   NORTH = vec(0, 0, -1),
   UP = vec(0, 1, 0),
   DOWN = vec(0, -1, 0),
   EAST = vec(1, 0, 0),
   WEST = vec(-1, 0, 0),
}
-- overrides
local overrideList = require("override", function() return {ids = {}, tags = {}} end)
local emptyOverride = {}
-- renderer
local modelpart
local vec3 = vec(0, 0, 0)
local modelData = {}
-- get override color
local function getOverrideColor(overrideData, side, i)
   return overrideData.sideColors and overrideData.sideColors[side] and overrideData.sideColors[side][i] and overrideData.sideColors[side][i].color or vec(1, 1, 1)
end
-- new sprite
local id = 0
local function newSprite(data, list, side, pos, offset, size, uvStart, uvEnd, rot)
   -- get texture
   local overrideTextureList = data.override.textures
   local textureList = data.textures
   local spriteTextures
   local usedSide
   if overrideTextureList and overrideTextureList[side] and #overrideTextureList[side] ~= 0 then
      usedSide = side
      spriteTextures = overrideTextureList[side]
   elseif textureList[side] and #textureList[side] ~= 0 then
      usedSide = side
      spriteTextures = textureList[side]
   elseif renderConfig.useParticleTexture and textureList.PARTICLE and #textureList.PARTICLE ~= 0 then
      usedSide = "PARTICLE"
      spriteTextures = textureList.PARTICLE
   else
      return
   end
   -- cull
   if data.cull then
      local sideOffset = sideMap[usedSide]
      if sideOffset then
         local tbl = list[data.offset.x + sideOffset.x][data.offset.y + sideOffset.y][data.offset.z + sideOffset.z]
         if tbl and tbl.cull == data.cull and not data.override.noCull then
            return
         end
      end
   end
   -- render
   local normal = matrices.rotation3(rot) * vec(0, 0, -1)
   local globalColor = data.override.color or vec(1, 1, 1)
   -- save to model data
   if not modelpart then
      for i = 1, #spriteTextures do
         table.insert(modelData, {
            pos + offset + normal * (i - 1) * 0.01,
            spriteTextures[i]..".png",
            rot,
            size.xy,
            uvStart,
            uvEnd,
            globalColor * getOverrideColor(data.override, usedSide, i)
         })
      end
      return
   end
   -- render model
   offset = offset * 16
   for i = 1, #spriteTextures do
      id = id + 1
      local sprite = modelpart:newSprite(id)
      :texture(spriteTextures[i]..".png", 16, 16)
      :pos(pos * 16 + offset + normal * (i - 1) * 0.25)
      :scale(size.x, size.y, 1)
      :setRenderType("translucent_cull")
      :rot(rot)
      :color(globalColor * getOverrideColor(data.override, usedSide, i))
      -- set uv
      for _, v in pairs(sprite:getVertices()) do
         v:setUV(math.lerp(uvStart, uvEnd, v:getUV()))
      end
      -- add to modelparts
      table.insert(modelData, sprite)
   end

   if data.block.id == "minecraft:water" then
      print("YEP")
   end
end

local function newCube(data, list, min, max)
   local pos = data.offset
   
   if renderConfig.tinyBlocks then
      min, max = math.lerp(min, 0.5, 0.5), math.lerp(max, 0.5, 0.5)
   end

   local size = max - min
   newSprite(data, list, "SOUTH", pos + min, size._yz, size.xy, min.x_ + 1 - max._y, max.x_ + 1 - min._y, vec(0, 180, 0))
   newSprite(data, list, "NORTH", pos + min, vec3, size.xy, max.x_ + 1 - min._y, min.x_ + 1 - max._y, vec(0, 0, 180))
   newSprite(data, list, "UP", pos + min, size._y_, size.xz, min.xz, max.xz, vec(90, 180, 0))
   newSprite(data, list, "DOWN", pos + min, size.__z, size.xz, max.xz, min.xz, vec(-90, 180, 0))
   newSprite(data, list, "EAST", pos + min, size.x__, size.zy, max.z_ + 1 - min._y, min.z_ + 1 - max._y, vec(0, 90, 180))
   newSprite(data, list, "WEST", pos + min, size._y_, size.zy, min.z_ + 1 - max._y, max.z_ + 1 - min._y, vec(0, 90, 0))
end

local function renderBlock(list, data)
   if data.override.mesh then
      for _, v in pairs(data.override.mesh) do
         newSprite(data, list, v.side, data.offset, v.pos, v.size, v.uvStart, v.uvEnd, v.rot)
      end
   else
      for _, v in pairs(data.shape) do
         newCube(data, list, v[1], v[2])
      end
   end
end

local function render(pos, dist, renderSprites)
   pos = pos:copy():floor()
   modelpart = renderSprites
   modelData = {}
   id = 0

   local list = {}
   for x = -dist - 1, dist + 1 do
      list[x] = {}
      for y = -dist - 1, dist + 1 do
         list[x][y] = {}
         for z = -dist - 1, dist + 1 do
            local offset = vec(x, y, z)
            local p = pos + offset
            local block = world.getBlockState(p)
            local cull
            if renderConfig.cull and block:isFullCube() then
               cull = block:isOpaque() and 1 or 0
            end
            local override = overrideList.ids[block.id]
            if not override then
               for _, tag in pairs(block:getTags()) do
                  if overrideList.tags[tag] then
                     override = overrideList.tags[tag]
                     break
                  end
               end
            end
            list[x][y][z] = {
               pos = p,
               offset = offset,
               block = block,
               textures = block:getTextures(),
               shape = block:getOutlineShape(),
               cull = cull,
               override = override or emptyOverride
            }
         end
      end
   end

   for x = -dist, dist do
      for y = -dist, dist do
         for z = -dist, dist do
            renderBlock(list, list[x][y][z])
         end
      end
   end

   return modelData
end

return render