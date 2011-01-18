---------------------------------------------------------------------------------
-- FILE IO ROUTINES --
-- written by Jason Mirwald
-- NOTE: max number of files that can be open at one time
-- by Euphoria is 25 including 0,1,2 (in/out/error)

atom
	  M_ALLOC = 16
	, M_FREE = 17
	, NULL = 0

---------------------------------------------------------------------------------
function alloc(atom size)
  return machine_func(M_ALLOC,size)
end function

procedure dealloc(atom lp)
  machine_proc(M_FREE,lp)
end procedure
---------------------------------------------------------------------------------

constant lp256 = alloc(256)

---------------------------------------------------------------------------------

-------------------------------------------------
global function getn(integer fn, integer n)
-- Return a sequence of n bytes from a file.
-- If EOF is reached before n bytes have been read, the remainder will be filled with -1's
 sequence s
  s = repeat(-1, n)
  for i = 1 to n do
    s[i] = getc(fn)
  end for
  return s
end function

------------------------------------------------
global function get_string(object x)
------------------------------------------------
-- syntax:        s = get_string(fn)
-- returns: a string of chars, up to, but not including binary 0 or EOF
-- description:
--    Get a 0-terminated string from a file.
------------------------------------------------
 sequence s
 integer c
  if atom(x) then
    s = {}
    c = getc(x)
    while c > 0 do
      s &= c
      c = getc(x)    
    end while
  else
    s = repeat(NULL,x[2])
    for i = 1 to x[2] do
      s[i] = get_string(x[1])
    end for
  end if
  return s
end function
------------------------------------------------

----------------------------------------------

global function get2u(object o)
 sequence s
 integer fn
  if atom(o) then
    return getc(o) + (getc(o)*#0100)
  else
    if length(o) = 2 then
      fn = o[1]
      s = repeat(0,o[2])
      for n = 1 to o[2] do
        s[n] = getc(fn) + (getc(fn)*#0100)
      end for
      return s
    end if
  end if
  return 0
end function

----------------------------------------------

global function get2s(object o)
 sequence s
 integer fn
 atom a
  if atom(o) then
    a = getc(o) + (getc(o)*#0100)
    return a-(#10000*(and_bits(a,#8000)!=0))
  else
    if length(o) = 2 then
      fn = o[1]
      s = repeat(0,o[2])
      for n = 1 to o[2] do
        a = getc(fn) + (getc(fn)*#0100)
        s[n] = a-(#10000*(and_bits(a,#8000)!=0))
      end for
      return s
    end if
  end if
  return 0
end function

----------------------------------------------

global function get4u(object o)
 sequence s
 atom lp
  lp = lp256
  if atom(o) then
    o = {o,1}
  else
    lp = alloc(o[2]*4)
  end if
  poke(lp,getn(o[1],o[2]*4))
  s = peek4u({lp,o[2]})
  if lp = lp256 then return s[1] end if
  dealloc(lp)
  return s
end function

----------------------------------------------

global function get4s(object o)
 sequence s
 atom lp
  lp = lp256
  if atom(o) then
    o = {o,1}
  else
    lp = alloc(o[2]*4)
  end if
  poke(lp,getn(o[1],o[2]*4))
  s = peek4s({lp,o[2]})
  if lp = lp256 then return s[1] end if
  dealloc(lp)
  return s
end function

----------------------------------------------

global function get_float32(object o)
 sequence s
 integer fn
  if atom(o) then
    return machine_func(49, getn(o,4))
  else
    if length(o) = 2 then
      fn = o[1]
      s = repeat(0,o[2])
      for n = 1 to o[2] do
        s[n] = machine_func(49, getn(fn,4))
      end for
      return s
    end if
  end if
  return 0
end function

----------------------------------------------

global function get_float64(object o)
 sequence s
 integer fn
  if atom(o) then
    return machine_func(47, getn(o,8))
  else
    if length(o) = 2 then
      fn = o[1]
      s = repeat(0,o[2])
      for n = 1 to o[2] do
        s[n] = machine_func(47, getn(fn,8))
      end for
      return s
    end if
  end if
  return -1
end function

----------------------------------------------

global procedure put_string( integer fn, sequence s)
  if length(s) and sequence(s[1]) then -- an array
    for i = 1 to length(s) do
      put_string(fn,s[i])
    end for
  else -- a null string "" or a single string
    puts(fn,s&NULL)
  end if
end procedure

----------------------------------------------

global procedure put2( integer fn, object o )
 sequence s
 atom a
 s = {}
 if atom(o) then
  o = {o}
 end if
 for n = 1 to length(o) do
  a = o[n]
  if a < 0 then
   a = #FFFF+a+1
  end if
  puts(fn,{remainder(a,#100),floor(a/#100)})
 end for
end procedure

----------------------------------------------

global procedure put4(integer fn, object o)
 atom lp
  lp = lp256
  if atom(o) then
    o = {o}
  else
    lp = alloc(length(o)*4)
  end if
  poke4(lp,o)
  puts(fn,peek({lp,length(o)*4}))
  if lp != lp256 then dealloc(lp) end if
end procedure

----------------------------------------------

global procedure put_float32(integer fn, object o)
 if atom(o) then o = {o} end if
 for n = 1 to length(o) do
  puts(fn,machine_func(48,o[n]))
 end for
end procedure

----------------------------------------------

global procedure put_float64(integer fn, object o)
 if atom(o) then o = {o} end if
 for n = 1 to length(o) do
  puts(fn,machine_func(46,o[n]))
 end for
end procedure

