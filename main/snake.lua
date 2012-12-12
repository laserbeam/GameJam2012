local max = math.max 

local decks = {}
decks.head = MOAIGfxQuad2D.new ()
decks.head:setTexture ( "assets/moai.png" )
decks.head:setRect ( -16, -16, 16, 16 )
decks.head:setUVRect ( 0, 0, 1, 1 )

decks.joint = MOAIGfxQuad2D.new ()
decks.joint:setTexture ( "assets/moai.png" )
decks.joint:setRect ( -16, -16, 16, 16 )
decks.joint:setUVRect ( 0, 0, 1, 1 )

decks.tail = MOAIGfxQuad2D.new ()
decks.tail:setTexture ( "assets/moai.png" )
decks.tail:setRect ( -16, -16, 16, 16 )
decks.tail:setUVRect ( 0, 0, 1, 1 )

decks.turret = MOAIGfxQuad2D.new ()
decks.turret:setTexture ( "assets/gun.png" )
decks.turret:setRect ( -20, -20, 20, 20 )
decks.turret:setUVRect ( 0, 0, 1, 1 )

decks.healer = MOAIGfxQuad2D.new ()
decks.healer:setTexture ( "assets/green.png" )
decks.healer:setRect ( -20, -20, 20, 20 )
decks.healer:setUVRect ( 0, 0, 1, 1 )

decks.bullet = MOAIGfxQuad2D.new ()
decks.bullet:setTexture ( "assets/gun.png" )
decks.bullet:setRect ( -8, -8, 8, 8 )
decks.bullet:setUVRect ( 0, 0, 1, 1 )

function makeSnakeHead()
	head = makeUnit( 20 )
	head.prop = MOAIProp2D.new()
	head.prop:setDeck( decks.head )
	return head
end

function makeSnakeJoint()
	joint = {}
	joint.prop = MOAIProp2D.new()
	joint.prop:setDeck( decks.joint )
	return joint
end

function makeSnakeTail()
	tail = {}
	tail.prop = MOAIProp2D.new()
	tail.prop:setDeck( decks.tail )
	return tail
end

-- Nope, we'll just set this directly... DUCK TYPE!
-- 
-- -- I am declaring setTarget outside of any object
-- -- so I can just attach it to anything
-- function setTarget( self, target )
-- 	self.target = target
-- end

-- function clearTarget( self )
-- 	self.target = nil
-- end

local function makeSnakeTurret( health, damage, cooldown, range )
	turret = makeUnit( health or 20 )
	turret.damage = damage or 2
	turret.cooldown = 0
	turret.maxCooldown = cooldown or .8
	turret.prop:setDeck( decks.turret )
	turret.target = nil
	turret.range = range or 130

	turret.bulletDeck = decks.bullet

	turret.updateCooldown = updateCooldown
	turret.resetCooldown = resetCooldown

	function turret:update ( gameState, time )
		self.target = selectTarget( self, gameState.enemies, self.range, 'health', true )

		self:updateCooldown( time )
		if self.cooldown <= 0 and self.target then
			fire( gameState, self, self.target, self.bulletDeck )
		end
	end

	return turret
end

local function makeHealMount( health, damage, cooldown )
	turret = makeUnit( health or 20 )
	turret.damage = damage or 5
	turret.cooldown = cooldown or 3
	turret.maxCooldown = cooldown or 3
	turret.prop:setDeck( decks.healer )

	turret.updateCooldown = updateCooldown
	turret.resetCooldown = resetCooldown

	function turret:update( gameState, time )
		self:updateCooldown( time )
		if self.cooldown <= 0 then
			self.target = selectTarget( self, gameState.theSnake.mountedTurrets, false, 'health', false, true )
			if self.target then
				self.target:healDamage( self.damage )
				self:resetCooldown()
			end
		end
	end

	return turret

end

--- Make a snake and place its props in the game state
-- Length only covers joints... the snake has head + length*joints + tail number of segments
-- The length stored in the snake is the number of joints.
-- There should be length/3 mounts on the snake (keep length%3==0)
function makeRunningSnake( state, config )
	local theSnake = {}
	length = config.length
	theSnake.joints = {}
	theSnake.mountedTurrets = {}
	theSnake.jointSpacing = 20
	theSnake.tDist = 0
	theSnake.speed = 60
	theSnake.totalLength = theSnake.jointSpacing*(config.length+1)

	table.insert( theSnake.joints, makeSnakeHead() )
	for i=1,length do
		table.insert( theSnake.joints, makeSnakeJoint() )
		if i%3 == 0 then
			local m = config:getMountTemplate( i/3 )
			if m then
				theSnake.mountedTurrets[i] = makeTemplateMount( m )
			end
		end
	end
	table.insert( theSnake.joints, makeSnakeTail() )
	
	for i,v in ipairs( theSnake.joints ) do
		state.objectLayer:insertProp(v.prop)
	end
	for i,v in pairs( theSnake.mountedTurrets ) do
		state.objectLayer:insertProp(v.prop)
	end

	function theSnake:clear()
		for i,v in ipairs( self.joints ) do
			state.objectLayer:removeProp( v.prop )
		end
		for i,v in pairs( self.mountedTurrets ) do
			state.objectLayer:removeProp( v.prop )
		end
	end

	function theSnake:countMounts()
		local rez = 0
		for i,v in pairs( self.mountedTurrets ) do
			rez = rez+1
		end
		return rez
	end

	function theSnake:getMount( slot )
		return self.mountedTurrets[ slot*3-1 ]
	end

	function theSnake:setMount( slot, mount )
		self.mountedTurrets[ slot*3-1 ] = mount
	end

	return theSnake
end

local templates = {}

function makeSnakeConfig()
	local config = {}
	config.length = 0
	config.mounts = {}
	
	function config:setMountLength( length )
		self.length = length*3
	end

	function config:getMountCount( )
		return math.floor(config.length+1/3)
	end

	function config:setMountTemplate( slot, mountType )
		if slot > self.getMountCount() then return end
		self.mounts[slot] = mountType
	end

	function config:getMountTemplate( slot )
		return self.mounts[slot]
	end

	function config:getDeck( slot )
		if config.mounts[slot] then return decks[config.mounts[slot]] end
		return nil
	end

	return config
end

function makeTemplateMount( name )
	local s = templates[name]
	if not s then return nil end
	local mount = nil
	if name == 'turret' then
		mount = makeSnakeTurret( s.health, s.damage, s.cooldown, s.range )
	elseif name == 'healer' then
		mount = makeHealMount( s.health, s.damage, s.cooldown )
	end
	return mount
end

local function loadTemplates( filename )
	templates = loadJSONFile( 'assets/' .. ( filename or 'mounts.json' ) )
end

loadTemplates()