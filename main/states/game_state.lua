require 'LRState'
require 'player'
require 'enemies'
require 'snake'

local sin = math.sin 
local cos = math.cos 
local abs = math.abs 

local state = LRState.new()

function makePathHolder() 
	
	local pathHolder = {}
	pathHolder.pathXY = {}
	pathHolder.lengths = {}

	local onDraw = function ( index, xOff, yOff, xFlip, yFlip )
		MOAIGfxDevice.setPenColor( 1, 0, 0, 1 )
		MOAIDraw.drawLine( pathHolder.pathXY )
	end

	function pathHolder:addPoint( x, y )
		local len = table.getn( self.pathXY )
		if len > 1 then
			local oldx, oldy = self.pathXY[len-1], self.pathXY[len]
			local d = distanceXY( oldx, oldy, x, y )
			if d>4 then
				local aux = self.lengths[ table.getn(self.lengths) ]
				table.insert( self.lengths, d + aux )
				table.insert( self.pathXY, x )
				table.insert( self.pathXY, y )
			end
		else
			table.insert( self.pathXY, x )
			table.insert( self.pathXY, y )
		end
	end

	function pathHolder:resetPath()
		self.pathXY = {}
		self.lengths = {0}
	end

	function pathHolder:finalizePath()
		-- This is called when the path is finished, the path should be smoothed here!
		print (table.getn(self.pathXY), table.getn(self.lengths))
	end

	function pathHolder:getXYAngleAtDistance( distance )
		if distance < 0 then distance = 0 end
		local i, d = binSearch( self.lengths, distance )
		if i == table.getn(self.lengths) then
			return self.pathXY[2*i-1], self.pathXY[2*i]
		end
		local xa, ya = self.pathXY[2*i-1], self.pathXY[2*i]
		local xb, yb = self.pathXY[2*i+1], self.pathXY[2*i+2]
		distance = distance - d
		local total = self.lengths[i+1] - d
		local alpha = distance/total
		local x, y = xb-xa, yb-ya
		local angle = angleFromXY( x, y )
		x, y = x*alpha, y*alpha
		return xa+x, ya+y, angle
	end

	scriptDeck = MOAIScriptDeck.new()
	scriptDeck:setRect( -64, -64, 64, 64 )
	scriptDeck:setDrawCallback( onDraw )

	pathHolder.prop = MOAIProp2D.new()
	pathHolder.prop:setDeck( scriptDeck )

	return pathHolder

end


isDrawing = false

--- Make a snake and place its props in the game state
local function makeRunningSnake( state, length, config )
	local theSnake = {}
	theSnake.joints = {}
	theSnake.mountedTurrets = {}
	theSnake.jointSpacing = 20
	theSnake.tDist = 0
	theSnake.speed = 60

	table.insert( theSnake.joints, makeSnakeHead() )
	table.insert( theSnake.mountedTurrets, 0 )
	for i=1,length do
		table.insert( theSnake.joints, makeSnakeJoint() )
		if i%3 == 2 then
			table.insert( theSnake.mountedTurrets, makeSnakeTurret() )
		else
			table.insert( theSnake.mountedTurrets, 0 )
		end
	end
	table.insert( theSnake.joints, makeSnakeTail() )
	table.insert( theSnake.mountedTurrets, 0 )

	for i,v in ipairs(theSnake.joints) do
		state.objectLayer:insertProp(v.prop)
	end
	for i,v in ipairs(theSnake.mountedTurrets) do
		if v ~= 0 then
			state.objectLayer:insertProp(v.prop)
		end
	end

	function theSnake:clear()
		for i,v in ipairs(theSnake.joints) do
			state.objectLayer:removeProp(v.prop)
		end
		for i,v in ipairs(theSnake.mountedTurrets) do
			if v ~= 0 then
				state.objectLayer:removeProp(v.prop)
			end
		end
	end

	if state.theSnake then state.theSnake.clear() end
	state.theSnake = theSnake
end

--- Populates the state with enemies based on some level file
--- but right now it just adds a couple turrets
local function loadLevel( state, levelName )
	state.enemies = {}
	e = makeEnemyTurret( 20, 10, 10 )
	e.prop:setLoc( -200, -200 )
	state.objectLayer:insertProp( e.prop )
	state.enemies[e] = e

	e = makeEnemyTurret( 20, 10, 10 )
	e.prop:setLoc( 100, 100 )
	state.objectLayer:insertProp( e.prop )
	state.enemies[e] = e
end

function state:onLoad()
	trace('onLoad called')
	self:initLayers( 3 )
	self.pathHolder = makePathHolder()
	self.objectLayer:insertProp( self.pathHolder.prop )

	gfxQuad = MOAIGfxQuad2D.new ()
	gfxQuad:setTexture ( "assets/moai.png" )
	gfxQuad:setRect ( -128, -128, 128, 128 )
	gfxQuad:setUVRect ( 0, 0, 1, 1 )

	loadLevel( self, '1.json' )
end

function state:onInput()
	local x, y = self.objectLayer:wndToWorld ( LRInputManager.getTouch ())	
	-- print ( x, y )
	if LRInputManager.down () then
		local x, y = self.objectLayer:wndToWorld ( LRInputManager.getTouch ())
		self.pathHolder:resetPath()
		self.pathHolder:addPoint( x, y )

		isDrawing = true
	elseif LRInputManager.isDown() then
		local x, y = self.objectLayer:wndToWorld ( LRInputManager.getTouch ())
		self.pathHolder:addPoint( x, y )
		self.pathHolder.prop:forceUpdate()
	elseif LRInputManager.up() then
		self.pathHolder:finalizePath()
		print (self.theSnake)
		makeRunningSnake( self, 10 )
		print (self.theSnake)
		isDrawing = false
	end
end

local function updateMovingSnake( scene, time )
	if (not isDrawing) and scene.theSnake then
		local dist = scene.theSnake.tDist
		for i,v in ipairs(scene.theSnake.joints) do
			local x, y, angle = scene.pathHolder:getXYAngleAtDistance(dist)
			angle = angle or 0
			v.prop:setLoc( x, y )
			v.prop:setRot( degree(angle)+90 )
			if scene.theSnake.mountedTurrets[i] ~= 0 then
				local t = scene.theSnake.mountedTurrets[i]
				t.prop:setLoc( x, y )
				if t.target then
					angle = angleFromXY( x, y, t.target.prop:getLoc() )
				end
				t.prop:setRot( degree(angle)+90 )
			end
			dist = dist - scene.theSnake.jointSpacing
		end
		scene.theSnake.tDist = scene.theSnake.tDist + scene.theSnake.speed*time
	end
end

local function fire( scene, shooter, target )
	local bullet = {}
	bullet.prop = MOAIProp2D.new()
	bullet.prop:setDeck( shooter.bulletDeck )
	bullet.prop:setLoc( shooter.prop:getLoc() )
	bullet.damage = shooter.damage
	local speed = 200
	local x, y = shooter.prop:getLoc()
	local angle = angleFromXY( x, y, target.prop:getLoc() )
	local time = LRStateManager.getTime()
	bullet.dx = speed*time*cos(angle)
	bullet.dy = speed*time*sin(angle)
	bullet.prop:setRot( degree(angle)+90 )

	-- bullet.delay = distance( shooter.prop, target.prop ) / speed
	shooter:resetCooldown()
	bullet.thread = MOAIThread:new()
	scene.fgLayer:insertProp( bullet.prop )
	bullet.thread:run (
		function ()
			local x, y = bullet.prop:getLoc()
			local tx, ty = target.prop:getLoc()
			while abs(tx-x) > abs(bullet.dx) and abs(ty-y) > abs(bullet.dy) do
				coroutine.yield()
				bullet.prop:moveLoc( bullet.dx, bullet.dy )
				if target.isDead then 
					scene.fgLayer:removeProp( bullet.prop )
					return
				end
				x, y = bullet.prop:getLoc()
				tx, ty = target.prop:getLoc()
			end
			scene.fgLayer:removeProp( bullet.prop )
			target:applyDamage( bullet.damage )
		end
	)
end

local function updateSnakeTurrets( scene, time )
	for i,turret in ipairs( scene.theSnake.mountedTurrets ) do
		if turret ~= 0 then
			if turret.target then
				if turret.target.isDead or distanceSq( turret.prop, turret.target.prop ) > turret.range * turret.range then
					turret.target = nil
				end
			end
			if not turret.target and scene.enemies then
				for j,enemy in pairs( scene.enemies ) do
					if distanceSq( turret.prop, enemy.prop ) <= turret.range * turret.range then
						turret.target = enemy
						break
					end
				end
			end

			-- If the turent has cooldown on its weapon, update it
			if turret.updateCooldown then turret:updateCooldown( time ) end
			if turret.cooldown <= 0 and turret.target then
				fire( scene, turret, turret.target )
			end

		end
	end
end

function state:onUpdate( time )
	updateMovingSnake( self, time )
	if self.theSnake then
		updateSnakeTurrets( self, time )
	end
	for i, e in pairs( self.enemies ) do
		if e.isDead then
			print (e, " died... how sad")
			self.objectLayer:removeProp( e.prop )
			self.enemies[e] = nil
		end
	end
end

function state:onUnload()
	-- self.button = nil
	self.pathHolder = nil
end

return state