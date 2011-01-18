-- Simple Standard Library ... by Aku 2000-2004
-- Renewed in 2005 to use English and for general public
-- Removed a lot of unused routines
-- + by contributors (see below)

-- Some routines, including shuffle(), are not made by me.
-- Sorry that I don't remember the author name. 
-- Please contact me if you are the author.

-- Please help me extending this file by optimizing the algorithms 
-- and adding new routines BUT please keep it SIMPLE.

include std/dll.e
include std/get.e
include std/wildcard.e
include std/file.e
include std/machine.e           
include std/text.e
include std/os.e

---------------------------------------------------------------------
---------------------------------------------------------------------

object pppath
if platform() = LINUX then pppath = '/' else pppath = '\\' end if

---------------------------------------------------------------------
--# String / Sequence
---------------------------------------------------------------------

-- left(string st, int n)
-- same as left() on VB, returns the first /n chars of st, if /n > length(/st)
-- then /st is returned
global function left(sequence st, atom n)
	if n >= length(st) then
		return st
	else
		return st[1..n]
	end if
end function

-- mid(string st, int start, int len)
-- same as mid() on VB, returns the /len chars of /st starting from 
-- position /start. If /len = -1, /st[/start..length(/st)] is returned.
global function mid(sequence st, atom start, atom len)
	if start > length(st) then
		return ""
	elsif len = 0 or len <= -2 then
		return ""
	elsif start+len-1 > length(st) then
		return st[start..length(st)]
	elsif len = -1 then
		return st[start..length(st)]
	elsif len+start-1 < 0 then
		return ""
	elsif start < 1 then
		return st[1..len+start-1]
	else
		return st[start..len+start-1]
	end if
end function

-- slice(string st, int start, int stop)
-- returns /st[/start../stop] but takes care of invalid subscript
global function slice(sequence st, atom start, atom stop)
	if stop = -1 then stop = length(st) end if
	if start < 1 then start = 1 end if
	if stop > length(st) then stop = length(st) end if
	if start > stop then return "" end if
	return st[start..stop]
end function

-- vslice(sequence s, int colno)
-- vertical slicing
-- for example, if /s = {{1,2}, {3,4}} and /colno = 2, 
-- then vslice(s, colno) = {2,4}
global function vslice(sequence s, atom colno)
sequence ret
	ret = {}
	for i = 1 to length(s) do
		ret = append(ret, s[i][colno])
	end for
	return ret
end function

-- right(string st, int n)
-- same as right() on VB, returns the last /n chars of st, if /n > length(/st)
-- then /st is returned
global function right(sequence st, atom n)
	if n >= length(st) then
		return st
	else
		return st[length(st)-n+1..length(st)]
	end if
end function

-- instr(int start, string st1, string st2)
-- same as instr() in VB
-- Basically it's match(st2, /st1[start..length(/st1)]),
-- but if st2 = "", will return 1
global function instr(atom start, sequence st1, sequence st2)
integer pos
	if start > length(st1) then
		return 0
	elsif equal(st2, {}) then
		return 1
	else
		pos = match(st2, st1[start..length(st1)])
		if pos then
			return pos + start - 1
		else
			return 0
		end if
	end if
end function

-- instr_nc(int start, string st1, string st2)
-- non case sensitive version of instr()
global function instr_nc(atom start, sequence st1, sequence st2)
	return instr(start, lower(st1), lower(st2))
end function

-- join(sequence s, string delim)
-- joins /s to the original string
-- example: join({"1", "23"}, "_") = "1_23"
global function join(sequence s, object delim)
object ret
	if not length(s) then return "" end if

	ret = ""
	for i=1 to length(s)-1 do
		ret &= s[i] & delim
	end for
	ret &= s[length(s)]
	return ret
end function

-- replace(string st, string sfind, string sreplace)
-- replaces every occurence of /sfind in /st with /sreplace
global function ganti(sequence st, sequence sfind, sequence sreplace)
atom pos, a
	pos = 1
	
	while 1 do
		a = instr(pos, st, sfind)
		if not a then exit end if
		st = st[1..a-1] & sreplace & st[length(sfind)+a..length(st)]
		pos = a+length(sreplace)
	end while
	
	return st
end function

-- part(sequence s, int pos)
-- simply returns /s[/pos] with error handling
-- useful for emulating: func(something)[pos] which is not a legal syntax in eu
-- in that case, use: part(func(something), pos)
global function part(object s, atom pos)
	if atom(s) then return s end if
	if length(s) = 0 then return 0 end if
	if pos > length(s) then return s[length(s)] end if
	if pos < 1 then return s[1] end if
	return s[pos]
end function

-- remove_dup(sequence s)
-- remove duplicates in s
global function remove_dup(sequence s)
object mark, ret
	mark = repeat(1, length(s))
	for i = 1 to length(s)-1 do
		for j = i+1 to length(s) do
			if equal(s[i], s[j]) then
				mark[j] = 0
			end if
		end for
	end for
	ret = {}
	for i = 1 to length(mark) do
		if mark[i] then
			ret = append(ret, s[i])
		end if
	end for
	return ret
end function

-- seq_insert(int at, sequence s, object new)
-- inserts /new at position /at to /s
global function seq_insert(integer at, sequence s, object new)
	s &= 0
	s[at+1..length(s)] = s[at..length(s)-1]
	s[at] = new
	return s
end function

-- seq_remove(object at, sequence s)
-- removes element(s) in position(s) /at from /s
-- /at can be an int or an {int from, int to}
global function seq_remove(object at, sequence s)
	if atom(at) then at = {at,at} end if
		s = s[1..at[1]-1] & s[at[2]+1..length(s)]
	return s
end function

-- shuffle(sequence s)
-- changes the order of elements of /s randomly
global function shuffle(sequence s)
	object temp
	integer j

	for i = length(s) to 2 by -1 do
		j = rand(i)
		temp = s[j]
		s[j] = s[i]
		s[i] = temp
	end for
	return s
end function

-- find_all(sequence s, object sfind)
-- returns positions of matching elements
-- example: find_all({1,9,3,9,9}, 9) = {2,4,5}
global function find_all(sequence s, object ofind)
object ret
	ret = {}
	for i=1 to length(s) do
		if equal(ofind, s[i]) then
			ret &= i
		end if
	end for
	return ret
end function

-- vfind(object ofind, sequence o, atom colno)
-- vertical find.
-- finds /sfind in column /colno of /o
global function vfind(object ofind, sequence o, atom colno)
	for i=1 to length(o) do
		if equal(ofind, o[i][colno]) then
			return i
		end if
	end for
	return 0
end function

-- trim(string st)
-- removes \n, \r, \t, and spaces from beginning and end of /st
global function trim(sequence st)
object p
	p = 0
	for i = 1 to length(st) do
		if find(st[i], "\n\r\t ") then
			p = i
		else
			exit
		end if
	end for
	st = st[p+1..length(st)]
	p = length(st)+1
	for i = length(st) to 1 by -1 do
		if find(st[i], "\n\r\t ") then
			p = i
		else
			exit
		end if
	end for
	st = st[1..p-1]
	return st
end function

-- is_string(object o)
-- determines whether /o is a sequence with atom (>=32 and <=255) 
-- or in "\n\r\t" as its elements
global function is_string(object o)
	if sequence(o) then
		for i=1 to length(o) do
			if sequence(o[i]) then
				return 0
			elsif not ((o[i] >= 32 and o[i] <= 255) or find(o[i], "\n\r\t")) then
				return 0
			end if
		end for
		return 1
	end if
	return 0
end function

---------------------------------------------------------------------
--# Pretty Printing
---------------------------------------------------------------------

object euob_tmp

procedure euob_makeString(object o)
sequence ret
	ret = "\""
	for i = 1 to length(o) do
		if o[i] = '\t' then
			ret &= "\\t"
		elsif o[i] = '\n' then
			ret &= "\\n"
		elsif o[i] = '\r' then
			ret &= "\\r"
		elsif o[i] = '"' then
			ret &= "\\\""
		elsif o[i] = '\'' then
			ret &= "\\'"
		elsif o[i] = '\\' then
			ret &= "\\\\"
		else
			ret &= o[i]
		end if
	end for
	ret &= "\""
	euob_tmp &= ret
end procedure

procedure euob_do(object o)
	if atom(o) then
		euob_tmp &= sprintf("%.12g", o)
	elsif is_string(o) then
		euob_makeString(o)
	else
		euob_tmp &= "{"
		for i = 1 to length(o) do
			euob_do(o[i])
			if i != length(o) then
				euob_tmp &= ", "
			end if
		end for
		euob_tmp &= "}"
	end if
end procedure

-- euob(object o)
-- returns a string representation of an Eu object /o
global function euob(object o)
	euob_tmp = ""
	euob_do(o)
	return euob_tmp
end function

---------------------------------------------------------------------
--# File and I/O
---------------------------------------------------------------------

-- write_lines(object f, sequence s)
-- write lines to file, opposite of read_lines
global procedure write_lines(object f, sequence s)
object fn
	if sequence(f) then 
		fn = open(f, "w")
	else
		fn = f
	end if
	
	for i=1 to length(s) do
		puts(fn, s[i])
		puts(fn, "\n")
	end for

	if sequence(f) then 
		close(fn)
	end if
end procedure

-- write_file(object f, string s)
-- write all contents to file, opposite of read_file
global procedure write_file(object f, sequence s)
object fn
	if sequence(f) then 
		fn = open(f, "wb")
	else
		fn = f
	end if
	
	if fn = -1 then return end if
	puts(fn, s)
	
	if sequence(f) then 
		close(fn)
	end if
end procedure

-- read_value(int fn)
-- reads a Eu object from file number /fn
-- equals value(get(/fn))[2]
global function read_value(atom fn)
object temp
	temp = get(fn)
	return temp[2]
end function

-- merge_path(string path, string file)
-- merges the /file to its /path.
-- example: on win32, merge_path("c:\\abc", "def") = "c:\\abc\\def"
-- takes care of excessive slashes
global function merge_path(sequence path, sequence file)
	if length(path) = 0 then return file end if
	if path[length(path)] = pppath then
		path = path[1..length(path)-1]
	end if
	if length(file) = 0 then return path end if
	if file[1] = pppath then
		file = file[2..length(file)]
	end if
	return path & pppath & file
end function

---------------------------------------------------------------------
--# Misc
---------------------------------------------------------------------

-- val(string o)
-- returns value(/o)[2]
global function val(sequence o)
object tp
	tp = value(o)
	return tp[2]
end function

-- iif(atom v, object iftrue, object iffalse)
-- Inline if. 
-- will return /iftrue if /v, or /iffalse if not /v.
global function iif(atom v, object iftrue, object iffalse)
	if v then
		return iftrue
	end if
	return iffalse
end function
