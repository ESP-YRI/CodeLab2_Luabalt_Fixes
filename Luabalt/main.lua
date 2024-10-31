local anim8 = require 'anim8'
require 'building'

tileQuads = {} -- parts of the tileset used for different tiles

local time = 0

--loads the game at a certain screensize with a specific title on the window
--and initializes all of the other parameters required upon startup
--such as the audio, the player's animations, the gravity of the game world, and the first buildings in the game
function love.load()
  width = 600
  height = 300

  love.window.setMode(width, height, {resizable=false})
  love.window.setTitle("Luabalt")

  -- One meter is 32px in physics engine
  love.physics.setMeter(15)
  -- Create a world with standard gravity
  world = love.physics.newWorld(0, 9.81*15, true)

  background=love.graphics.newImage('media/iPadMenu_atlas0.png')
  --Make nearest neighbor, so pixels are sharp
  background:setFilter("nearest", "nearest")

  --Get Tile Image
  tilesetImage=love.graphics.newImage('media/play1_atlas0.png')
  --Make nearest neighbor, so pixels are sharp
  tilesetImage:setFilter("nearest", "nearest") -- this "linear filter" removes some artifacts if we were to scale the tiles
  tileSize = 16
 
  -- crate
  tileQuads[0] = love.graphics.newQuad(0, 0, 
    18, 18,
    tilesetImage:getWidth(), tilesetImage:getHeight())
  -- left corner
  tileQuads[1] = love.graphics.newQuad(228, 0, 
    16, 16,
    tilesetImage:getWidth(), tilesetImage:getHeight())
  -- top middle
  tileQuads[2] = love.graphics.newQuad(324, 0, 
    16, 16,
    tilesetImage:getWidth(), tilesetImage:getHeight())
  -- right middle
  tileQuads[3] = love.graphics.newQuad(387, 68, 
    16, 16,
    tilesetImage:getWidth(), tilesetImage:getHeight())
  -- middle1
  tileQuads[4] = love.graphics.newQuad(100, 0, 
    16, 16,
    tilesetImage:getWidth(), tilesetImage:getHeight())
  tileQuads[5] = love.graphics.newQuad(116, 0, 
    16, 16,
    tilesetImage:getWidth(), tilesetImage:getHeight())

  tilesetBatch = love.graphics.newSpriteBatch(tilesetImage, 1500)

  -- Create a Body for the crate.
  crate_body = love.physics.newBody(world, 770, 200, "dynamic")
  crate_box = love.physics.newRectangleShape(9, 9, 18, 18)
  fixture = love.physics.newFixture(crate_body, crate_box)
  fixture:setUserData("Crate") -- Set a string userdata
  
  --changed the mass of the crate to 10 so that colliding with it slows down the player
  crate_body:setMassData(crate_box:computeMass( 7 ))

  text = "hello World"

  --initializes two buildings on the screen at specific coordinates
  building1 = building:makeBuilding(750, 16)
  building2 = building:makeBuilding(1200, 16)

  playerImg = love.graphics.newImage("media/player2.png")
  -- Create a Body for the player.
  body = love.physics.newBody(world, 400, 100, "dynamic")
  -- Create a shape for the body.
  player_box = love.physics.newRectangleShape(15, 15, 30, 30)
  -- Create fixture between body and shape
  fixture = love.physics.newFixture(body, player_box)
  fixture:setUserData("Player") -- Set a string userdata
  
  -- Calculate the mass of the body based on attatched shapes.
  -- This gives realistic simulations.
  body:setMassData(player_box:computeMass( 1 ))
  body:setFixedRotation(true)
  --the player an init push.
  body:applyLinearImpulse(1000, 0)

  -- Set the collision callback.
  world:setCallbacks(beginContact,endContact)

  love.graphics.setNewFont(12)
  love.graphics.setBackgroundColor(155,155,155)

  -- initializes all of the player character's animations
  local g = anim8.newGrid(30, 30, playerImg:getWidth(), playerImg:getHeight())
  runAnim = anim8.newAnimation(g('1-14',1), 0.05)
  jumpAnim = anim8.newAnimation(g('15-19',1), 0.1)
  inAirAnim = anim8.newAnimation(g('1-8',2), 0.1)
  rollAnim = anim8.newAnimation(g('9-19',2), 0.05)

  --sets the first animation to be shown on screen upon loading the game to the inAirAnim
  --as the player is falling from the sky at the start of the game
  currentAnim = inAirAnim

  --initializes and plays the music 
  music = love.audio.newSource("media/18-machinae_supremacy-lord_krutors_dominion.mp3", "stream")
  music:setVolume(0.5)
  love.audio.play(music)

  --initializes a running sound effect and sets it to loop (but does not play it)
  runSound = love.audio.newSource("media/foot1.mp3", "static")
  runSound:setLooping(true);


  shape = love.physics.newRectangleShape(450, 500, 100, 100)
end

function love.update(dt)

  --updates what is loaded on screen and what frame of the animation the player is currently showing
  --every frame
  currentAnim:update(dt)
  world:update(dt)

  --updates where the 2 buildings in the game are on screen every frame
  building1:update(body, dt, building2)
  building2:update(body, dt, building1)

  --runs the function that updates the tilesetBatch and redraws the objects on screen
  updateTilesetBatch()

  --if the player is in the air for more than 0.25 seconds, the player's animation changes to the inAirAnim
  if(time < love.timer.getTime( ) - 0.25) and currentAnim == jumpAnim then
    currentAnim = inAirAnim
    currentAnim:gotoFrame(1)
  end

  --if the player has been rolling for more than 0.5 seconds, the player's animation changes to the runAnim
  if (time < love.timer.getTime( ) - 0.5) and currentAnim == rollAnim then
    currentAnim = runAnim
    currentAnim:gotoFrame(1)
  end

  --if the player object is on the runAnim, a force of a factor of 250 is applied to push the character to the right 
  --else, less force is applied to the character (factor of 100)
  if(currentAnim == runAnim) then
    --print("ON GROUND")
    body:applyLinearImpulse(250 * dt, 0)
  else
    body:applyLinearImpulse(100 * dt, 0)
  end

  --figure out how to get the player's y position to make this work
 -- if(player.getY > height) then
  --  text = "Player fell off a building. Hit escape to quit."
  --end
end

--draws the background, the text on the screen, the player character, the buildings, and the tilesetBatch
function love.draw()
  love.graphics.draw(background, 0, 0, 0, 1.56, 1.56, 0, 200)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(text, 10, 10)

  love.graphics.translate(width/2 - body:getX(), 0)
   
  currentAnim:draw(playerImg, body:getX(), body:getY(), body:getAngle())

  --love.graphics.setColor(255, 0, 0)
  --love.graphics.polygon("line", building1.shape:getPoints())
  --love.graphics.polygon("line", building2.shape:getPoints())

  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(tilesetBatch, 0, 0, 0, 1, 1)
end

--updates the sprites currently in the batch and redraws the objects on screen
function updateTilesetBatch()
  tilesetBatch:clear()

  tilesetBatch:add(tileQuads[0], crate_body:getX(), crate_body:getY(), crate_body:getAngle());

  building1:draw(tilesetBatch, tileQuads);
  building2:draw(tilesetBatch, tileQuads);

  tilesetBatch:flush()
end

--if the player hits the up arrow key, applies force to move the player character upwards on screen
--and changes the player character's animation to jumpAnim to simulate jumping
--instantiates a timer to keep track of how long the player has been in the air
function love.keypressed( key, isrepeat )
  if key == "up" and onGround then
    body:applyLinearImpulse(0, -300)
    currentAnim = jumpAnim
    currentAnim:gotoFrame(1)
    time = love.timer.getTime( )
  end
  
  --added functionality: player can quit the game by pressing the escape key
  if key == "escape" then
    love.event.quit()
  end

  if key == "down" then
    music:setVolume(0)
    runSound:setVolume(0)
  end
end

-- This is called every time a collision begins.
-- it tracks which two objects have collided and prints that information out in a message to the console
function beginContact(bodyA, bodyB, coll)
  local aData=bodyA:getUserData()
  local bData =bodyB:getUserData()

  cx,cy = coll:getNormal()
  text = text.."\n"..aData.." colliding with "..bData.." with a vector normal of: "..cx..", "..cy

  print (text)

  --if the player is one of the two objects colliding then set the onGround bool to true,
  --change the player character's animation to the rolling animation's first frame
  --initialize a timer to keep track of how long the player has been rolling
  --and play the running sound
  if(aData == "Player" or bData == "Player") then

    onGround = true
    currentAnim = rollAnim
    currentAnim:gotoFrame(1)
    time = love.timer.getTime( )
    runSound:play()

  end

  if(aData == "Player" or bData == "Player" and aData == "Crate" or bData == "Crate") then
    -- figure out how to destroy the crate
  end
end

-- This is called every time a collision ends.
-- sets the onGround bool to false
-- changes the on screen text to show that the collision has ended 
function endContact(bodyA, bodyB, coll)
  onGround = false
  local aData=bodyA:getUserData()
  local bData=bodyB:getUserData()
  text = "Collision ended: " .. aData .. " and " .. bData

  --stops the running sound of one of the objects that is no longer colliding is the player
  if(aData == "Player" or bData == "Player") then
    runSound:stop();
  end
end

-- a function that is not called anywhere
function love.focus(f)
  if not f then
    print("LOST FOCUS")
  else
    print("GAINED FOCUS")
  end
end

--closes the window and prints a message to the console
function love.quit()
  print("Thanks for playing! Come back soon!")
end