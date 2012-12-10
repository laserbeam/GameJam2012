local sqrt = math.sqrt 
local floor = math.floor 
INFINITY = 0x3f3f3f3f

---------------------------------------------------------------------------
-- Utility function which creates a MOAITimer to call a function after a delay
function callWithDelay( delay, func, ... )
	local timer = MOAITimer.new()
	timer:setSpan( delay )
	timer:setListener( MOAITimer.EVENT_TIMER_LOOP, 
		function ()
			timer:stop()
			timer = nil
			func( unpack( arg ) )
		end
	)
	timer:start()
end

---------------------------------------------------------------------------
-- Get the distance between 2 rigs

function distanceSqXY( ax, ay, bx, by )
	return (ax-bx)*(ax-bx) + (ay-by)*(ay-by)
end

function distanceXY( ax, ay, bx, by )
	return sqrt( distanceSqXY( ax, ay, bx, by ) )
end

function distanceSq( A, B )
	local ax, ay = A:getLoc()
	local bx, by = B:getLoc()
	return (ax-bx)*(ax-bx) + (ay-by)*(ay-by)
end

function distance( A, B )
	return sqrt( distanceSq( A, B ) )
end


---------------------------------------------------------------------------
--- Binary search through a sorted array 
function binSearch( array, value, first, last )
	first = first or 1
	last = last or table.getn(array)
	local mid = 0
	local res = 0
	while (first <= last) do
		mid = floor((first+last)/2)
		if array[mid] > value then
			last = mid-1
		else
			res = mid
			first = mid+1
		end
	end
	return res, array[res]
end

---------------------------------------------------------------------------
-- Make a button! 
-- Call updateClick on click events!
function makeButton ( texture, w, h )

	local button = {}
	local gfxQuad = MOAIGfxQuad2D.new ()
	gfxQuad:setTexture ( texture )
	gfxQuad:setRect ( -w/2, -h/2, w/2, h/2 )
	
	local prop = MOAIProp2D.new ()
	prop:setDeck ( gfxQuad )
	prop:setPriority ( 0 )
	button.prop =  prop
	
	button.func = nil
	
	button.hit = false
	
	-- updates the button based on Input status
	button.updateClick = function ( self, down, x, y )
		if down then
			--
			if self.prop:inside ( x, y ) then
				self.hit = true
				self.prop:setScl ( 1.2, 1.2 )
			else
				self.hit = false
				self.prop:setScl ( 1.0, 1.0 )
			end
		else
			-- only process uphits if the button 
			if self.prop:inside ( x, y ) and self.hit then
				self.prop:setScl ( 1.0, 1.0 )
				if self.func then
					self:func ()
				end
			else
				playButtonHit = false
				self.prop:setScl ( 1.0, 1.0 )
			end
		end
	end
	
	button.setCallback = function ( self, func )
		self.func = func
	end
	
	return button
end

function makeTextButton ( font, texture, w, h, textY )

	-- make a basic button
	local textButton = makeButton ( texture, w, h )
	
	-- add the text
	local textbox = MOAITextBox.new ()
	textbox:setFont ( font )
	textbox:setAlignment ( MOAITextBox.CENTER_JUSTIFY )
	textbox:setYFlip ( true )
	textbox:setRect ( -w/2, -h/2, w/2, h/2 )
	textbox:setLoc ( 0, -textY )
	textbox:setPriority ( 1 )
	textButton.txt = textbox
	
	-- allow the user to set the string
	textButton.setString = function ( self, text )
		self.txt:setString ( text )
	end
	
	
	return textButton
end
