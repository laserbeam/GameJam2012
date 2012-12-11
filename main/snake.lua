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

decks.bullet = MOAIGfxQuad2D.new ()
decks.bullet:setTexture ( "assets/gun.png" )
decks.bullet:setRect ( -8, -8, 8, 8 )
decks.bullet:setUVRect ( 0, 0, 1, 1 )


function makeSnakeHead()
	head = {}
	head.prop = MOAIProp2D.new()
	head.prop:setDeck(decks.head)
	return head
end

function makeSnakeJoint()
	joint = {}
	joint.prop = MOAIProp2D.new()
	joint.prop:setDeck(decks.joint)
	return joint
end

function makeSnakeTail()
	tail = {}
	tail.prop = MOAIProp2D.new()
	tail.prop:setDeck(decks.tail)
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

function updateCooldown( self, time )
	self.cooldown = max( 0, self.cooldown - time )
end

function resetCooldown( self )
	self.cooldown = self.maxCooldown
end

function makeSnakeTurret( health, damage, cooldown )
	turret = {}
	turret.health = health or 20
	turret.maxHealth = turret.health
	turret.damage = damage or 1
	turret.cooldown = 0
	turret.maxCooldown = cooldown or .8
	turret.prop = MOAIProp2D.new()
	turret.prop:setDeck(decks.turret)
	turret.target = nil
	turret.range = 130

	turret.bulletDeck = decks.bullet

	turret.updateCooldown = updateCooldown
	turret.resetCooldown = resetCooldown

	return turret
end
