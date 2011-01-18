-----------------------
-- sPRINT.E  v1.0    --
-- by Gabriel Boehme --
-- modified by       --  
-- matt Lewis        --
-- updated 7/14/2008 --
-----------------------

-- 2008.07.14
-- * Updated to work with Euphoria v4.0

-- Modified print.e by GB to do the same thing, but to act as sprint()
-- include sequence.e
include std/text.e

type string(sequence s)
-- verify that we have a valid Euphoria-representable string
-- (ASCII chars 32-255, 9, 10, 13)
object x
   for i = 1 to length(s) do
      x = s[i]
      if integer(x) then
     if x < ' ' then
        if not find(x, "\t\n\r") then
           return 0
        end if
     elsif x > 255 then
        return 0
     end if
      else
     return 0
      end if
   end for
   return 1
end type

integer fn
sequence result

constant ESCAPE_STRING = {"\\n", "\\t", "\\\"", "\\\\", "\\r"},
     ESCAPED_CHARS = {'\n',  '\t',  '"',    '\\',   '\r'}

procedure SprintEuString(sequence s)
integer c, f
   --puts(fn, '"')
   result &= '"'
   for i = 1 to length(s) do
      c = s[i]
      f = find(c, ESCAPED_CHARS)
      if f then
     --puts(fn, ESCAPE_STRING[f])
     result &= ESCAPE_STRING[f]
      else
     --puts(fn, c)
     result &= c
      end if
   end for
   --puts(fn, '"')
   result &= '"'
end procedure

procedure Sprint(sequence s)
integer len
object x
   len = length(s)
   if len and string(s) then
      -- print the sequence out as a string
      SprintEuString(s)
   else
      -- print the sequence out as...well, a sequence
      --puts(fn, '{')
      result &= '{'
      for i = 1 to len do
     x = s[i]
     if atom(x) then
        -- print out the numeric value
        --print(fn, x)
        result &= sprint(x)
     else
        Sprint(x)
     end if
     if i < len then
        --puts(fn, ',')
        result &= ','
     end if
      end for
      --puts(fn, '}')
      result &= '}'
   end if
end procedure

without warning

-- pretty_sprint() is in std/pretty.e
global function pretty_sprint( object x)

   result = ""
   if atom(x) then
      -- just an atom, printf the value
      return sprint(x)
      --printf(file, "%g", x)
   else
      -- a sequence!
      --fn = file
      if length(x) then
          Sprint(x)
          if result[1] = '"' then
              result = result[2..length(result)-1]
          end if
      end if
      return result
   end if
end function

global function pretty_source( object x )
-- print out any Euphoria object, with strings in quotes
   result = ""
   if atom(x) then
      -- just an atom, printf the value
      return sprint(x)
      --printf(file, "%g", x)
   else
      -- a sequence!
      --fn = file
		if length(x) then
        	Sprint(x)
	  	else
	  		result = "{}"
      end if
      return result
   end if
end function
