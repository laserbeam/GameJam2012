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

-- Lot of things have health can take damage and die
-- This would be sort of a base class for everything
function makeUnit( health )
	local unit = {}
	unit.health = health
	unit.maxHealth = health
	
	unit.prop = MOAIProp2D.new()
	unit.healthBar = makeHealthBar( unit )

	function unit:getHealthPerc ()
		return self.health/self.maxHealth
	end

	function unit:applyDamage( damage ) 
		self.health = self.health - damage
		self.healthBar.prop:forceUpdate()
		if self.health <= 0 then self:die() end
	end

	function unit:healDamage( damage )
		self.healthBar.prop:forceUpdate()
		self.health = min( self.health + damage, self.maxHealth )
	end

	function unit:die()
		self.isDead = true
	end
	return unit
end

local function rank( best, current, desc )
	if current < best and not desc then return true end
	if current > best and desc then return true end
	return false
end

--- Selecting a target requires a lot of parameters
-- range - limit only to units from the table which are in range
-- prioritize - select the target with the best field named by prioritize or
-- 		best distance from the seeker
-- desc - true if one wants the largest prioritize, not smallest
-- force - drop current target even if it's still in range
-- distinct - true if the selection should ignore the selector
function selectTarget( self, table, range, prioritize, desc, force, distinct )
	range = range or INFINITY
	local target = self.target
	if target then
		if force or target.isDead or distanceSq( self.prop, target.prop ) > self.range * self.range then
			target = nil
		end
	end
	if not target and table then
		best = INFINITY
		if desc then best = -INFINITY end
		for _, v in pairs( table ) do
			local d = distanceSq( self.prop, v.prop )
			if distinct then print( v, self ) end
			if (not distinct or v ~= self) and d < range*range then
				if not prioritize then return v
				elseif prioritize == 'distance' and rank( best, d, desc ) then
					best = d
					target = v
				elseif v[prioritize] and rank( best, v[prioritize], desc ) then
					best = v[prioritize]
					target = v
				end
			end
		end
	end

	return target
end

--- This takes a gameState as a parameter as bullets have to be placed inside it
-- Probably the ugliest function out there
function fire( gameState, shooter, target, bulletDeck, speed )
	local bullet = {}
	bullet.prop = MOAIProp2D.new()
	bullet.prop:setDeck( bulletDeck )
	bullet.prop:setLoc( shooter.prop:getLoc() )
	bullet.damage = shooter.damage
	local speed = speed or 250
	local x, y = shooter.prop:getLoc()
	local angle = angleFromXY( x, y, target.prop:getLoc() )
	local time = LRStateManager.getTime()
	bullet.dx = speed*time*cos(angle)
	bullet.dy = speed*time*sin(angle)
	bullet.prop:setRot( degree(angle)+90 )
	shooter:resetCooldown()
	bullet.thread = MOAIThread:new()
	gameState.fgLayer:insertProp( bullet.prop )
	bullet.thread:run (
		function ()
			local x, y = bullet.prop:getLoc()
			local tx, ty = target.prop:getLoc()
			while abs(tx-x) > abs(bullet.dx) and abs(ty-y) > abs(bullet.dy) do
				coroutine.yield()
				bullet.prop:moveLoc( bullet.dx, bullet.dy )
				if target.isDead then 
					gameState.fgLayer:removeProp( bullet.prop )
					return
				end
				x, y = bullet.prop:getLoc()
			end
			gameState.fgLayer:removeProp( bullet.prop )
			target:applyDamage( bullet.damage )
		end
	)
end

function rotateToTarget( self, target )
	local x, y = self.prop:getLoc()
	local angle = angleFromXY( x, y, target.prop:getLoc() )
	self.prop:setRot( degree(angle)+90 )
	return angle
end

local function getHPColor( perc )
	-- local rr, rg, rb = 0.6, 0, 0
	-- local gr, gg, gb = 0, 0.6, 0.1

	return (1-perc)*0.8, perc*0.8, perc*0.2, 1
end

function makeHealthBar( unit )
	local hb = {}
	local w = 36
	hb.unit = unit
	local function onDraw( index, xOff, yOff, xFlip, yFlip )
		local hp = clamp( hb.unit:getHealthPerc(), 0, 1 )
		local x, y = hb.unit.prop:getLoc()
		if hp < 1 then
			MOAIGfxDevice.setPenColor( getHPColor(hp) )
			MOAIDraw.fillRect( x-w/2, y+20, x-w/2 + hp*w, y+25 )
			MOAIGfxDevice.setPenColor( 1, 1, 1, 1 )
			MOAIDraw.drawRect( x-w/2, y+20, x+w/2, y+25 )
		end
	end

	scriptDeck = MOAIScriptDeck.new()
	scriptDeck:setRect( -64, -64, 64, 64 )
	scriptDeck:setDrawCallback( onDraw )

	hb.prop = MOAIProp2D.new ()
	hb.prop:setDeck( scriptDeck )
	hb.prop:setPriority( 1000 )

	return hb

end