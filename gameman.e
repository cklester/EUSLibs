-- Tabletop Game Simulator/Modeler (TGaSM)

include std/map.e as map
include std/filesys.e
include std/text.e
include std/datetime.e as dt
include std/sequence.e

include std/pretty.e
include std/console.e

include messaging.e

sequence
	games = {{},{},{},{},{{},{}}}

integer
	current_game = 0,
	game_map = 0

enum
	  NAMES
	, FNAMES
	, DATA
	, VARS
	, PLAYER_DEF

	, EIDS = 1
	, ELEMENTS

function delete_game_db(sequence dbname)
	return delete_file( dbname )
end function

function get_db_name(sequence s)
sequence result = ""
datetime d

	s = lower( s )
	for t=1 to length(s) do
		if find(s[t],"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX0123456789_") = 0 then
			result &= '_'
		else
			result &= s[t]
		end if
	end for

	d = now_gmt()
	result &= dt:format(d, "_%Y-%m-%d-%H-%M-%S")

	return result & ".txt"
end function

public function game_exists( sequence name )
	return find(name,games[NAMES]) > 0
end function

-- PLAYER MANAGEMENT FUNCTIONS

public function is_human( atom pid )
	return map:get( pid, "Human" )
end function

public function set_player_record(sequence s)
integer m, result = 0
sequence fld, def

	def = games[PLAYER_DEF]
	for t=1 to length( s ) do
		fld = split( s[t], ":" )
		if length(fld) = 2 then
			m = find( fld[1], def[1] )
			if m = 0 then
				games[PLAYER_DEF][1] = append(games[PLAYER_DEF][1],fld[2])
				games[PLAYER_DEF][2] = append(games[PLAYER_DEF][2],fld[1])
			else
				err("Field definition already exists")
			end if
		else
			err("Bad field definition")
		end if
	end for

	return result
end function

public function get_player_names()
atom m
	m = map:get(games[DATA][current_game],"PLAYERS")
	return map:keys( m )
end function

function player_exists( sequence name )
	return find( name, get_player_names() ) > 0
end function

public function add_player(sequence fields )
integer i, m, result = 0, game_players, id = 0
sequence def, fd, names, pid = ""
map new_player

	def = games[PLAYER_DEF]
	fields = split(fields,",")

	i = current_game

	m = games[DATA][i]
	game_players = map:get(m,"PLAYERS")
	new_player = map:new()

	for t=1 to length( fields ) do
		fd = split( fields[t], ":" )
		if length(fd) = 2 then
			m = find(fd[1],def[1])
			if m > 0 then
				if equal(fd[1],"Name") then
					if not id then
						id = 1
						pid = fd[2]
						map:put(new_player,fd[1],fd[2])
					else
						err("Name defined twice")
					end if
				else
					map:put(new_player,fd[1],fd[2])
				end if
			else
				err("Unrecognized player field")
			end if
		else
			err("Bad player record")
		end if
	end for

	if id then
		-- make sure this named player doesn't exist
		names = get_player_names()
		if length(names) and find( pid, names ) then
			err("That player already exists.")
		else
			map:put(game_players,pid,new_player)
		end if
	else
		err("Unique name not supplied for new player.")
	end if

	return new_player
end function

public function add_player_element(atom pmap, sequence fld, object data )
integer result = 0
sequence def

	if not equal(fld,"Name") then
		def = games[PLAYER_DEF]
		if find(fld,def[1]) then
			-- assume data is the right type (def[2])
			map:put(pmap,fld,data)
			result = 1
		else
			err("Invalid player definition field: " & fld)
		end if
	else
		err("Cannot change name.")
	end if

	return result
end function

public function get_player_element(atom pmap, sequence fld)
object result = ""
integer i
	i = find(fld,games[PLAYER_DEF][1])
	if i > 0 then
		result = map:get(pmap,fld)
		if equal("SEQ",games[PLAYER_DEF][2][i]) then
			if not sequence(result) then
				result = "Error!"
				?1/0
			end if
		else
			if not atom(result) then
				result = "Error!"
				?1/0
			end if
		end if
	else
		err("That element doesn't exist.")
		?1/0
	end if
	return result
end function

public function set_player_element(atom pmap, sequence fld, object data)
integer result = 0
	if equal(fld,"Name") then
		err("Can't change name.")
	else
		if has(pmap,fld) then
			map:put(pmap,fld,data)
			result = 1
		else
			err("Don't has that.")
		end if
	end if
	return result
end function

-- GAME MANAGEMENT FUNCTIONS

/*

To manage a game, call new_game(). This will return the name of the game.

*/

public function new_game( sequence name, integer clear_prior_game_db = 1 )
-- give new_game the name of the new game you want to create
integer i
object ngame
sequence fname = get_db_name( name ), result

	i = find( name, games[NAMES] )

	if i > 0 then
		if clear_prior_game_db then
			games[NAMES] = games[NAMES][1..i-1] & games[NAMES][i+1..$]
			games[FNAMES] = games[FNAMES][1..i-1] & games[FNAMES][i+1..$]
			games[DATA] = games[DATA][1..i-1] & games[DATA][i+1..$]
			i = 0
		end if
	end if

	if i = 0 then
		games[NAMES] = append(games[NAMES],name)
		games[FNAMES] = append(games[FNAMES],fname)
		games[DATA] &= map:new()

		if file_exists( fname ) then
			if clear_prior_game_db then
				if not delete_game_db( fname ) then
					err("Could not delete " & fname )
				end if
			else
				err("That game file already exists.")
			end if
		end if

		ngame = games[DATA][$]

		map:put( ngame, "PLAYERS", map:new() ) 	-- this will hold player data, indexed by name
		map:put( ngame, "COMPONENTS", map:new() )	-- this will hold game components indexed by name

		result = games[NAMES][$]
	else
		err("A game with that name already exists.")
		result = ""
	end if

	current_game = length( games[NAMES] )
	game_map = games[DATA][$]

	return result
end function

public function add_element( sequence name, object s)
integer result = 1, game_comps
	game_comps = map:get(game_map,"COMPONENTS")
	map:put(game_comps,name,s)
	return result
end function

public function get_element( sequence name )
integer game_comps
object result = ""

	game_comps = map:get(game_map,"COMPONENTS")

	if map:has( game_comps, name ) then
		result = map:get( game_comps, name )
	else
		err("Could not find component '" & name & "'")
		puts(1,"Could not find component '" & name & "'")

		puts(1,"\nkeys:" & pretty_sprint( map:keys(game_comps)))

		wait_key()
	end if

	return result
end function

public function set_element( sequence name, object val )
integer game_comps, result = 1

	game_comps = map:get(game_map,"COMPONENTS")
	map:put( game_comps, name, val )

	return result
end function

public function add_to_player_element( atom pmap, sequence name, object val )
sequence s
	s = map:get(pmap,name)
	if length(s) = 0 then
		if sequence(val) then
			map:put(pmap,name,{val})
		else
			map:put(pmap,name,val)
		end if
	else
		if sequence(val) then
			map:put(pmap,name,append(s,val))
		else
			map:put(pmap,name,s & val)
		end if
	end if
	return 1
end function

public function add_game_variables(sequence dbname, sequence s)
integer result = 0

	return result
end function

