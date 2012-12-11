local sin = math.sin 
local cos = math.cos 
local abs = math.abs 
local min = math.min 
local max = math.max 

function updateCooldown( self, time )
	self.cooldown = max( 0, self.cooldown - time )
end

function resetCooldown( self )
	self.cooldown = self.maxCooldown
end

function makeUnit( health )
	unit = {}
	unit.health = health
	unit.maxHealth = health
	
	unit.prop = MOAIProp2D.new()

	function unit:applyDamage( damage ) 
		self.health = self.health - damage
		if self.health < 0 then self:die() end
	end

	function unit:healDamage( damage )
		self.health = min( self.health + damage, self.maxHealth )
	end

	function unit:die()
		self.isDead = true
	end
	return unit
end

function pickTargetInRangeFromTable( self, table, range )
	for _, v in pairs( table ) do
		if distanceSq( self.prop, v.prop ) < range*range then
			return v
		end
	end
	return nil
end

--- This takes a scene as a parameter as bullets have to be placed inside it
function fire( scene, shooter, target, bulletDeck, speed )
	local bullet = {}
	bullet.prop = MOAIProp2D.new()
	bullet.prop:setDeck( bulletDeck )
	bullet.prop:setLoc( shooter.prop:getLoc() )
	bullet.damage = shooter.damage
	local speed = speed or 200
	local x, y = shooter.prop:getLoc()
	local angle = angleFromXY( x, y, target.prop:getLoc() )
	local time = LRStateManager.getTime()
	bullet.dx = speed*time*cos(angle)
	bullet.dy = speed*time*sin(angle)
	bullet.prop:setRot( degree(angle)+90 )
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
			end
			scene.fgLayer:removeProp( bullet.prop )
			target:applyDamage( bullet.damage )
		end
	)
end

function rotateToTarget( self, target )
	local x, y = self.prop:getLoc()
	local angle = angleFromXY( x, y, target.prop:getLoc() )
	self.prop:setRot( degree(angle)+90 )
end