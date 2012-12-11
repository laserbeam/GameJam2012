LRLogger = {}
LRLogger.NONE = 0
LRLogger.ERROR = 1
LRLogger.WARN = 2
LRLogger.DEBUG = 3
LRLogger.STATUS = 4
LRLogger.VERBOSE = 5
LRLogger.level = LRLogger.VERBOSE
LRLogger.useFile = nil --'log.txt'
if LRLogger.level > 0 and LRLogger.useFile then
	LRLogger.file = io.open('log.txt', 'w')
end

local lines = 0

function LRLogger.log( level, string )
	if LRLogger.level >= level then
		print( string )
		if LRLogger.useFile then
			LRLogger.file:write( string .. '\n' )
		end
		lines = lines + 1
		if lines > 10 then
			lines = 0
			LRLogger.file:flush()
		end
	end
end

function LRLogger.trace( string )
	LRLogger.log( LRLogger.DEBUG, string )
end

log = LRLogger.log
trace = LRLogger.trace

return LRLogger