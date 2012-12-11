

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

function makeSnakeTurret()
	turret = {}
	turret.prop = MOAIProp2D.new()
	turret.prop:setDeck(decks.turret)
	turret.target = {0, 0}
	return turret
end
