-- registration.e
-- an include file that allows use of
-- require(), version tracking, etc.

-- currently, the registry holds records formatted as
-- { filename, version info }

-- version info must be in the format { Y, M, D, R, P }
-- where R = release # and P = patch #
-- R and P must increase sequentially per release

-- You can choose to use only dates or only R+P sets
-- for example, {0,0,0,1,2} will be concerned only with the release/patch numbers
-- for example, {2007,9,21,0,0} will be concerned only with the release date

-- Examples
-- register( "registration.e", { 2007, 9, 21, 1, 1 } ) <- first release
-- register( "my_include.e", { 2005, 11, 3, 1, 1.3 } ) <- first patch, third update
-- register( "insanity.e", { 2007, 1, 1, 3, 0 } ) 	   <- third release

sequence registry
	registry = {{},{}}
	
global procedure register_code(sequence s, sequence v)
atom i
	i = find(s,registry[1])
	if i = 0 then
		registry[1] = append(registry[1],s)
		registry[2] = append(registry[2],v)
	end if
end procedure

global function require(sequence s, sequence v)
atom i
	i = find(s,registry[1])
	if i then
		i = registry[2][i] = v
	end if
	return i
end function

global function require_at_least(sequence s, sequence v)
atom i
	i = find(s,registry[1])
	if i then
		i = registry[2][i] >= v
	end if
	return i
end function

global function getRegistryInfoFor( sequence s )
atom i
sequence r
	i = find(s,registry[1])
	r = {}
	if i > 0 then
		r = registry[2][i]
	end if
	return r
end function

global function getRegistryInfo()
	return registry
end function

global function getVersionDataFor(sequence s)
sequence result
	result = getRegistryInfoFor( s )
	if length(result) = 0 then
		result = ""
	else
		if result[1] = 0 and result[2] = 0 and result[3] = 0 then
			if result[4] = 0 and result[5] = 0 then
				result = ""
			else
				result = sprintf("%d.%d",result[4..5])
			end if
		else
			if result[4] = 0 and result[5] = 0 then
				result = sprintf("%04d-%02d-%02d",result[1..3])
			else
				result = sprintf("%04d-%02d-%02d %d.%d",result)
			end if
		end if
	end if
	return result
end function

register_code( "registration.e", {2007,9,28,1,2} )
