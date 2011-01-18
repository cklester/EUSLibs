-- Additional miscellaneous routines and constants for Euphoria 2.3
-- by Juergen Luethje

-- include std/misc.e
include std/console.e
include std/get.e
include type.e
include std/math.e
include std/wildcard.e
include math.e

global constant
   FALSE = 0, TRUE = 1


global procedure wait_abort (sequence msg, integer code)
   puts(2, msg & "\n\nPress any key ...")
   if wait_key() then end if
   abort(code)
end procedure


global function iif (integer b, object t, object f)
   if b then return t else return f end if
end function


-- after code by Derek Parnell, August 2002 (EUforum)
global function dim_array (sequence dimension, object init_value)
   -- example: sequence a
   --          a = dim_array({3,7,4}, 0)
   object array

   if length(dimension) = 0 then
      return 0     -- error
   end if

   array = init_value
   for i = length(dimension) to 1 by -1 do
      if atom(dimension[i]) and dimension[i] > 0 then
         array = repeat(array, dimension[i])
      else
         return i  -- error
      end if
   end for

   return array
end function


-- after code by Derek Parnell, June 2003 (EUforum)
global function flatten (sequence s)
   sequence ret
   object x

   ret = {}
   for i = 1 to length(s) do
      x = s[i]
      if atom(x) then
         ret &= x
      else
         ret &= flatten(x)
      end if
   end for

   return ret
end function


-- by Ricardo Forno, March 2002 (EUforum)
-- (The function MaxDepth() is part of his General Functions package.)
global function max_depth (object x)
   -- Returns the maximum depth of object x.
   -- An atom returns 0, a string returns 1,
   --   a composite sequence returns 2 or more.
   integer n, t

   if atom(x) then
      return 0
   else
      n = 1
      for i = 1 to length(x) do
         t = 1 + max_depth(x[i])
         if t > n then
            n = t
         end if
      end for
      return n
   end if
end function


-- after code by Pete Lomax, February 2003 (EUforum)
global function subset (sequence source, sequence iset)
   -- e.g. subset("ABCDEF", {2,4,6})  ==>  "BDF"
   sequence ret
   integer idx

   ret = repeat(0, length(iset))
   for i = 1 to length(iset) do
      idx = iset[i]
      if idx > length(source) then
         return -1   -- error
      end if
      ret[i] = source[idx]
   end for
   return ret
end function


global function remove_duplicates (sequence s)
   sequence ret
   integer p, f

   if length(s) < 2 then return s end if

   ret = repeat(0, length(s))
   p = 1
   ret[1] = s[1]
   for i = 2 to length(s) do
      f = find(s[i], ret)
      if f = 0 or f > p then
         p += 1
         ret[p] = s[i]
      end if
   end for

   return ret[1..p]
end function


global function hex (sequence pre, object x)
   -- modified after misc.e: sprint()
   -- Return the string representation of any Euphoria data object,
   -- in hexadecimal format with optional prefix.
   sequence ret

   if atom(x) then
      return sprintf("%s%02x", {pre, x})   -- x must be <= #FFFFFFFF
   else
      ret = "{"
      for i = 1 to length(x) do
         ret &= hex(pre, x[i])
         if i < length(x) then
            ret &= ','
         end if
      end for
      ret &= "}"
      return ret
   end if
end function


-- global function rgb (byte red, byte green, byte blue)
--    -- wie die entspr. Funktion in VB und PB
--    return (blue*#100+green)*#100 + red
-- end function


constant BYTE_UNITS = {"Byte", "KB", "MB"}

global function flex_bytes (atom bytes)
   for i = 1 to length(BYTE_UNITS) do
      if bytes < 1024 then
         return sprintf("%g %s", {round_half_up(bytes, 2), BYTE_UNITS[i]})
      end if
      bytes /= 1024
   end for
   return sprintf("%g GB", {round_half_up(bytes, 2)})
end function

------------------------------------------------------------------------

global function find_all (object x, sequence source)
   integer p
   sequence ret

   p = find(x, source)
   if p = 0 then
      return {}
   end if

   ret = {p}
   for i = p+1 to length(source) do
      if equal(x, source[i]) then
         ret &= i
      end if
   end for
   return ret
end function


global function finds (object x, sequence source, integer start)
   -- searches for x in source, beginning at start
   -- in : x      : any object
   --      source : empty sequence ==> function returns 0
   --      start  : [1, length(source)]
   integer p

   if start >= 1 and start <= length(source) then
      p = find(x, source[start..length(source)])
      if p then
         return start + p - 1
      end if
   end if
   return 0
end function


global function finds_any (sequence s, sequence source, integer start)
--    * vormals instr_any (integer start, sequence source, sequence s)
   -- sucht nach jedem Element aus s in source, beginnend bei start
   -- und liefert die Position der ersten Uebereinstimmung,
   -- bzw. 0 wenn keine gefunden
   -- Hin : start  : 1..length(source)
   --       source : empty sequence ==> function returns 0
   --       s      : empty sequence ==> function returns 0
   -- called by parse_any()

   if start >= 1 then
      for i = start to length(source) do
         if find(source[i], s) then
            return i
         end if
      end for
   end if
   return 0
end function


global function find_any (sequence s, sequence source)
   for i = 1 to length(source) do
      if find(source[i], s) then
         return i
      end  if
   end for
   return 0
end function


global function rfind (object x, sequence source)
   -- searches in source FROM RIGHT TO LEFT for x
   -- Zurück: Position in source, bei der x gefunden wurde,
   --         VON LINKS gezählt  (0 = nicht gefunden)
   for i = length(source) to 1 by -1 do
      if equal(x, source[i]) then
         return i
      end if
   end for
   return 0
end function


global function find_wild (string searchfor, string_list wildlist)
   -- in: wildlist: list of strings, that may contain wildcards

   for i = 1 to length(wildlist) do
      if wildcard_match(wildlist[i], searchfor) then
         return i
      end if
   end for
   return 0
end function

