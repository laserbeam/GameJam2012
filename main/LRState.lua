--=========================================================================
-- LRState is practically a bogus abstract class
-- It's not actually needed! and I'm not sure if it should actually be used
-- It's just there to know Scenes exist :))
--=========================================================================


LRState = {}
LRState.__index = LRState

function LRState.new( o )
	-- No metatables or shit as parameters... just return a table
	o = o or {}
	setmetatable(o, LRState)
	o.layers = {}
	o.rigs = {}
	return o
end

--[[
-- Methods a scene may or may not define.
-- Descriptions of these method can be found in LRStateManager

function LRState:onLoad( ... )
function LRState:onUnload()
function LRState:onFocus()
function LRState:onLoseFocus()
function LRState:onInput()
function LRState:onUpdate( time )
--]]

function LRState:initLayers( layerCount )
	layerCount = layerCount or 1
	self.objectLayerID = math.min(layerCount, 2)
	for i=1,layerCount do
		local layer = MOAILayer2D.new()
		layer:setViewport( MAIN_VIEWPORT )
		table.insert(self.layers, layer)
	end
end


-- function LRState:addRig( rig, layerID )
-- 	layerID = layerID or self.objectLayerID
-- 	self.layers[layerID]:insertProp( rig.prop )
-- 	self.rigs[rig] = layerID
-- 	rig.layer = self.layers[layerID]
-- end

-- function LRState:removeRig( rig )
-- 	if self.rigs[rig] then
-- 		self.layers[self.rigs[rig]]:removeProp( rig.prop )
-- 		self.rigs[rig] = nil
-- 		rig.layer = nil
-- 	end
-- end

-- function LRState:updateRigs( time )
-- 	for k, v in pairs(self.rigs) do
-- 		k:update( time )
-- 	end
-- end

-- function LRState:clearRigs()
-- 	for k, v in pairs(self.rigs) do
-- 		self.layers[v]:removeProp( k )
-- 		self.rigs[k] = nil
-- 	end
-- end

function LRState:getLayers()
	return self.layers
end

function LRState:addLayer( layer )
	layer = layer or function()
		local l = MOAILayer2D.new()
		l:setViewport( MAIN_VIEWPORT )
		return l
	end

	table.insert(self.layers, layer)
	return layer
end

return LRState