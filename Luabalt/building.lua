building = { 
  tileSize = 16,

  screen_height,

  x = 0,
  y = 0,
  width = 0,
  height = 0,
  body,
  shape
} -- the table representing the class, which will double as the metatable for the instances
-- tiles are 16 bit
-- this class holds these variables any building must have these perameters

building.__index = building -- failed table lookups on the instances should fallback to the class table, to get methods

function building:makeBuilding(x, y, tileSize)

  -- self is referring to the current object being edited, in this case the building

  local self = setmetatable({}, building)

  self:setupBuilding(x, y, tileSize)
-- use the class on this object to make a building
  return self
end

--function that sets the parameters of the building
function building:setupBuilding(x, tileSize)

  self.tileSize = tileSize
  self.x = x
  self.y = 300

  -- between 20 and 30 wide
  -- being 5 to 12 high
  self.width  = math.ceil((love.math.random( ) * 10) + 20)
  self.height = math.ceil(5 + love.math.random( ) * 7)
  --self.height = 7
  
  self.body = love.physics.newBody(world, 0, 0, "static")
  -- sets the building's body type to static (meaning it will not move), places it in the world, and initializes its x and y position,
  
  -- make a rectangle shape for the building with the given x and y position, width, and height
  self.shape = love.physics.newRectangleShape(self.x, self.y, 
                                              self.tileSize * self.width, 
                                              self.tileSize * self.height)
  fixture = love.physics.newFixture(self.body, self.shape)
  --fixtures attach shapes (the visual object) to bodies (Like rigidbodies in Unity, determines physics interactions)
  fixture:setUserData("Building")
  -- set the user data of the fixture to "Building" so we can identify it later
  -- 
end

-- when right edge of the building is further left on screen than the player, creates a new building on screen 150 units to the right
function building:update(body, dt, other_building)

  if self.x + self.width/2 * self.tileSize < body:getX() then
      self:setupBuilding(
          other_building.x + other_building.width  * self.tileSize + 150, 
          16)
  end
end

--tilesetBatch is the image of the tileset, tileQuads is the table of quads that represent the tiles
-- draws the building on the screen
function building:draw(tilesetBatch, tileQuads)
  x1, y1 = self.shape:getPoints()

  tilesetBatch:add(tileQuads[0], self.x, self.y, 0)
  for x=self.width - 1, 0, -1 do 
    for y=0,self.height - 1, 1 do
      if x == 0 and y == 0 then
        tilesetBatch:add(tileQuads[1], x1 + x * tileSize, y1 + y * tileSize, 0)
      else
        if y == 0 and x == self.width - 1 then
          tilesetBatch:add(tileQuads[3], x1 + x * tileSize, y1 + y * tileSize, 0)
        else 
          if y == 0 then
            tilesetBatch:add(tileQuads[2], x1 + x * tileSize, y1 + y * tileSize, 0)
          else 
            num = math.floor(x + y + x1 + y1)
            if (num)%5 == 0 then
              tilesetBatch:add(tileQuads[8], x1 + x * tileSize, y1 + y * tileSize, 0)
            else
              tilesetBatch:add(tileQuads[4], x1 + x * tileSize, y1 + y * tileSize, 0)
            end
          end
        end
      end
    end
  end
end
