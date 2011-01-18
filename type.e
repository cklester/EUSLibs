-- Collection of standard types -- v1.00
-- > by Juergen Luethje <http://home.arcor.de/luethje/>
-- Freeware
-- Standard disclaimer: Use at your own risk!
--
-- These are types included in the Euphoria distribution, which in my
-- opinion are of general use, and some more.
-- All types are collected in a single file for easy reuse.


--==============================[ math ]==============================--

global type boolean (object x)
   if integer(x) and (x = 0 or x = 1) then
      return 1
   end if
   return 0
end type

global type hugeint (object x)
   -- This type can hold huger integers than Euphoria's built-in integer
   -- type (> 1073741823).
   -- It is technically an atom, but mathematically an integer.

   if atom(x) and (x = floor(x)) then
      return 1
   end if
   return 0
end type

global type positive_atom (object x)
   if atom(x) and (x > 0) then
      return 1
   end if
   return 0
end type

global type positive_int (object x)
   if integer(x) and (x > 0) then
      return 1
   end if
   return 0
end type

global type nonnegative_atom (object x)
   if atom(x) and (x >= 0) then
      return 1
   end if
   return 0
end type

global type nonnegative_int (object x)
   if integer(x) and (x >= 0) then
      return 1
   end if
   return 0
end type

global type negative_atom (object x)
   if atom(x) and (x < 0) then
      return 1
   end if
   return 0
end type

global type negative_int (object x)
   if integer(x) and (x < 0) then
      return 1
   end if
   return 0
end type

global type nonpositive_atom (object x)
   if atom(x) and (x <= 0) then
      return 1
   end if
   return 0
end type

global type nonpositive_int (object x)
   if integer(x) and (x <= 0) then
      return 1
   end if
   return 0
end type

global type complex (object x)
   if sequence(x) and (length(x) = 2)
   and atom(x[1]) and atom(x[2]) then
      return 1
   end if
   return 0
end type

global type trig_range (object x)
   --  values passed to arccos and arcsin must be [-1,+1]

   if atom(x) and (-1 <= x) and (x <= 1) then
      return 1
   end if
   return 0
end type


--==============================[ misc ]==============================--

global type byte (object x)
   if integer(x) and (0 <= x) and (x <= #FF) then
      return 1
   end if
   return 0
end type

global type pointer (object x)
   -- 32 bit pointer
   if atom(x) and (x = floor(x))
   and (0 <= x) and (x <= #FFFFFFFF) then
      return 1
   end if
   return 0
end type

global type string (object x)
   object t

   if atom(x) then return 0 end if
   for i = 1 to length(x) do
      t = x[i]
      if (not integer(t)) or (t < 0)  or (t > #FF) then
         return 0
      end if
   end for
   return 1
end type

global type string_256 (object x)
   if (length(x) = 256) and string(x) then
      return 1
   end if
   return 0
end type

global type string_list (object x)
   if atom(x) then return 0 end if
   for i = 1 to length(x) do
      if not string(x[i]) then
         return 0
      end if
   end for
   return 1
end type

global type char (object x)
   -- true if i is a 7-bit ASCII character

   if integer(x) and (0 <= x) and (x <= 127) then
      return 1
   end if
   return 0
end type

global type num_char (object x)
   if integer(x) and ('0' <= x) and (x <= '9') then
      return 1
   end if
   return 0
end type

global type alphanum_char (object x)
   if integer(x) then
      if ('A' <= x and x <= 'Z')
      or ('a' <= x and x <= 'z')
      or ('0' <= x and x <= '9') then
         return 1
      end if
   end if
   return 0
end type

global type keycode (object x)
   -- a keyboard code

   if integer(x) and (-1 <= x) and (x <= 511) then
      return 1
   end if
   return 0
end type

global type file_number (object x)
   if integer(x) and (x >= 0) then
      return 1
   end if
   return 0
end type

global type valid_routine_id (object x)
   if integer(x) and (0 <= x) and (x <= 1000) then
      return 1
   end if
   return 0
end type

global type sorted_ascending (object x)
   -- return TRUE if x is in ascending order

   if atom(x) then return 0 end if
   for i = 1 to length(x)-1 do
      if compare(x[i], x[i+1]) > 0 then
         return 0
      end if
   end for
   return 1
end type

