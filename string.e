-- String routines (tested with Euphoria 2.3+)
--
-- (c) Juergen Luethje <http://luethje.de.vu/>
-- started 2002-03-23
-- Freeware
-- Standard disclaimer: Use at your own risk!


include type.e
include routcons.e
include std/get.e
include std/text.e

constant
   WSP	      = "\t ",
   WHITESPACE = WSP & {10, 11, 12, 13},
   WORD_DELIM = WHITESPACE & "!\"%&=(){[]}\\+-*/#'<>|,;.:"

--======================================================================

global function extract (string source, string s)
   -- liefert alle Zeichen aus source bis zu der Position
   -- (ausschließlich), an der s am weitesten LINKS
   -- auftritt (aehnlich wie bei PB 3.2)
   integer p

   p = match(s, source)
   if p then
      return source[1..p-1]
   else
      return source
   end if
end function


global function rextract (string source, integer chr)
   -- liefert alle Zeichen aus source bis zu der Position
   -- (ausschließlich), an der chr am weitesten RECHTS
   -- auftritt
   -- wird typischerweise benutzt, um den Pfad einer Datei
   -- zu isolieren (mit chr = '\\') oder einen Dateinamen
   -- ohne seine Endung zu erhalten (mit chr = '.')
   integer p

   p = rfind(chr, source)
   if p then
      return source[1..p-1]
   else
      return source
   end if
end function

------------------------------------------------------------------------

global function matchs (sequence s, sequence source, integer start)
   -- * vormals instr()
   -- sucht s in source, beginnend bei start
   -- in : s	  : darf keine leere Sequenz sein
   --	   source : leere Sequenz ==> Funktionswert = 0
   --	   start  : 1..length(source)
   integer p

   if start >= 1 and start <= length(source) then
      p = match(s, source[start..length(source)])
      if p then
	 return p + start - 1
      end if
   end if
   return 0
end function


global function verify (integer start, string source, string charlist)
   -- sucht das erste Nicht-charlist-Zeichen in source, beginnend bei start
   -- und liefert dessen Positin, bzw. 0 wenn kein solches gefunden
   -- Hin : start    : 1..length(source)
   --	    source   : empty sequence ==> function returns 0
   --	    charlist : empty sequence ==> function returns 0
   -- called by trim_left_chars(), parse_any()

   if start >= 1 and length(charlist) then
      for i = start to length(source) do
	 if not find(source[i], charlist) then
	    return i
	 end if
      end for
   end if
   return 0
end function


global function rverify (integer start, string source, string charlist)
   -- called by trim_right_chars()

   if start < 0 then
      start = length(source)
   elsif start > length(source) then
      return 0
   end if

   for i = start to 1 by -1 do
      if not find(source[i], charlist) then
	 return i
      end if
   end for
   return 0
end function


global function rverify_lines (string source, string charlist)
   integer ret, char

   ret = length(source)
   for i = length(source) to 1 by -1 do
      char = source[i]
      if char = '\n' then
	 ret = i
      elsif not find(char, charlist) then
	 return ret
      end if
   end for
   return 0
end function


global function replace (sequence source, sequence WhatToReplace, sequence ReplaceWith)
   integer posn

   if length(WhatToReplace) then
      posn = match(WhatToReplace, source)
      while posn do
	 source = source[1..posn-1] & ReplaceWith & source[posn+length(WhatToReplace)..length(source)]
	 posn = matchs(WhatToReplace, source, posn+length(ReplaceWith))
      end while
   end if
   return source
end function


global function remove_any (string source, string charlist)
   integer pntr, char
   sequence ret

   pntr = 0
   ret = repeat(0, length(source))
   for i = 1 to length(source) do
      char = source[i]
      if not find(char, charlist) then
	 pntr += 1
	 ret[pntr] = char
      end if
   end for
   return ret[1..pntr]
end function


global function crunch (string source, string charlist, integer newchar)
   sequence ret
   integer pntr, char, flag

   pntr = 0
   flag = 1
   ret = repeat(0, length(source))
   for i = 1 to length(source) do
      char = source[i]
      if not find(char, charlist) then
	 pntr += 1
	 ret[pntr] = char
	 flag = 1
      elsif flag then
	 pntr += 1
	 ret[pntr] = newchar
	 flag = 0
      end if
   end for
   return ret[1..pntr]
end function


global function match_word (string search, string main, integer start)
   integer w

   w = length(search)
   if w = 0 or start < 1 then
      return 0
   end if

   while 1 do
      start = matchs(search, main, start)
      if (start = 0)
      or (((start = 1) or find(main[start-1], WORD_DELIM)) and
	  ((start+w = length(main)+1) or find(main[start+w], WORD_DELIM))) then
	 exit
      end if
      start += 1
   end while
   return start
end function


integer EolPos

global function match_to_eol (string search, string main, integer start)
   -- sucht <search> in <main>, beginnend bei <start>
   -- in : search : das letzte Zeichen von search kann bis zum
   --		    Zeilenende beliebig oft vorkommen
   integer s, t, lastChar

   if length(search) = 0 then return 0 end if

   s = matchs(search, main, start)
   if s = 0 then
      EolPos = 0
      return 0
   end if

   t = s + length(search)
   EolPos = finds('\n', main, t)-1
   if EolPos = -1 then EolPos = length(main) end if
   lastChar = search[length(search)]
   for i = t to EolPos do
      if main[i] != lastChar then
	 return 0
      end if
   end for

   return s
end function

global function delete_between_last (string source, string begLine1, string begLine2)
   -- delete between last Line1 and Line2
   integer a1, a2, z2, temp

   -- letzte Line2 suchen
   a2 = 0
   z2 = 0
   begLine2 = "\n" & begLine2
   while 1 do
      temp = match_to_eol(begLine2, source, z2+1)
      if temp = 0 then
	 exit
      end if
      a2 = temp
      z2 = EolPos
   end while
   if a2 = 0 then return source end if

   -- letzte Line1 vor Line2 suchen
   a1 = 0
   EolPos = 0
   begLine1 = "\n" & begLine1
   while 1 do
      temp = match_to_eol(begLine1, source, EolPos+1)
      if temp = 0 or EolPos > a2 then
	 exit
      end if
      a1 = temp
   end while
   if a1 = 0 then return source end if

   return source[1..a1-1] & source[z2+1..length(source)]
end function

--======================================================================

-- these string functions now handled by std/text.e

-- global function trim_left_chars (string source, string charlist)
--    -- called by trim_chars(), trim_left()
--    integer p

--    p = verify(1, source, charlist)
--    if p then
--       return source[p..length(source)]
--    else
--       return ""
--    end if
-- end function


-- global function trim_right_chars (string source, string charlist)
--    -- called by trim_chars(), trim_right()
--    integer p

--    p = rverify(-1, source, charlist)
--    if p then
--       return source[1..p]
--    else
--       return ""
--    end if
-- end function


-- global function trim_chars (string source, string charlist)
--    -- called by trim()
--    return trim_left_chars(trim_right_chars(source, charlist), charlist)
-- end function

------------------------------------------------------------------------

-- global function trim_left (string source)
--    return trim_left_chars(source, WHITESPACE)
-- end function


-- global function trim_right (string source)
--    return trim_right_chars(source, WHITESPACE)
-- end function


-- global function trim (string source)
--    -- called by parse()
--    return trim_chars(source, WHITESPACE)
-- end function


global procedure word_wrap (integer fn, sequence source, integer wide)
   -- fn       : device or file for output
   -- source   : string without any '\n'
   -- wide <= 0: no word wrap
   integer p

   if wide > 0 then
      while length(source) > wide do
	 p = length(source) + 1
	 for i = wide+1 to 1 by -1 do
	    if find(source[i], WSP) then
	       p = i
	       exit
	    end if
	 end for
	 if p = length(source) + 1 then
	    for i = wide+2 to length(source) do
	       if find(source[i], WSP) then
		  p = i
		  exit
	       end if
	    end for
	 end if
	 puts(fn, source[1..p-1])

	 while 1 do
	    p += 1
	    if p > length(source) then return end if
	    if not find(source[p], WSP) then exit end if
	 end while
	 puts(fn, "\n")
	 source = source[p..length(source)]
      end while
   end if

   puts(fn, source)
end procedure

--======================================================================

constant eu_escape_chars   = "nrt\\\"\'",
	 eu_unescape_chars = "\n\r\t\\\"\'"

global function eu_escape (string text)
   -- e.g. {9} --> "\t"
   sequence ret
   integer char, f

   ret = ""
   for i = 1 to length(text) do
      char = text[i]
      f = find(char, eu_unescape_chars)
      if f then
	 ret &= "\\" & eu_escape_chars[f]
      else
	 ret &= char
      end if
   end for
   return ret
end function

global function eu_unescape (string text)
   -- e.g. "\t" --> {9}
   sequence ret
   integer i, char, f

   ret = ""
   i = 1
   while i <= length(text) do
      char = text[i]
      if char = '\\' then
	 f = 0
	 if i < length(text) then
	    f = find(text[i+1], eu_escape_chars)
	 end if
	 if f = 0 then
	    return i+1	     -- error
	 end if
	 ret &= eu_unescape_chars[f]
	 i += 2
      else
	 ret &= char
	 i += 1
      end if
   end while
   return ret
end function

------------------------------------------------------------------------

constant HEX_CHARS = "0123456789ABCDEFabcdef"

global function qp_decode (string text)
   -- decode Quoted-Printable encoded text
   -- [after RFC 2045]
   sequence s, ret	   -- Wenn ret als string deklariert ist, kann
   integer t, r, n, char   -- diese Funkrion with typecheck teilweise
			   -- *sehr* lange dauern!
   t = 1
   r = 1
   n = length(text)
   ret = repeat(0, n)
   while t <= n do
      char = text[t]
      if char = '=' then
	 if t < n then
	    if text[t+1] != '\n' then
	       t += 1
	       if t < n and text[t] != '\r' then
		  if  find(text[t],   HEX_CHARS)
		  and find(text[t+1], HEX_CHARS) then
		     s = value('#' & upper(text[t..t+1]))
		     ret[r] = s[2]
		  else
		     ret[r] = '='
		     t -= 1
		  end if
		  r += 1
	       end if
	    end if
	 end if
	 t += 1
      else
	 ret[r] = char
	 r += 1
      end if
      t += 1
   end while
   return ret[1..r-1]
end function

--======================================================================

constant DQ = '"'


global function trim_DQ (string source)
   -- called by parse()
   sequence ret
   integer n

   ret = trim(source)
   n = length(ret)
   if n >= 2 and ret[1] = DQ and ret[n] = DQ then
      return ret[2..n-1]
   end if
   return ret
end function

-- parse is now done by text.e's split()
-- global function parse (string source, integer delim)
--    -- parse string source that is a list, into a sequence of values
--    -- e.g.  parse("*.gif,*.jpg", ',')  ==>  {"*.gif","*.jpg"}
--    sequence charlist, ret
--    integer begpos, p

--    charlist = {DQ, delim}
--    ret = {}
--    p = 0
--    while 1 do
--       begpos = p + 1
--       while 1 do
-- 	 p = finds_any(charlist, source, p+1)
-- 	 if p = 0 or source[p] != DQ then exit end if
-- 	 p = finds(DQ, source, p+1)
-- 	 if p = 0 then exit end if
--       end while
--       if p = 0 then exit end if
--       ret = append(ret, trim_DQ(source[begpos..p-1]))
--    end while

--    return append(ret, trim_DQ(source[begpos..length(source)]))
-- end function

global function parse_trim (string source, integer delim)
   -- like parse(), but using trim() instead of trim_DQ()
   sequence charlist, ret
   integer begpos, p

   charlist = {DQ, delim}
   ret = {}
   p = 0
   while 1 do
      begpos = p + 1
      while 1 do
	 p = finds_any(charlist, source, p+1)
	 if p = 0 or source[p] != DQ then exit end if
	 p = finds(DQ, source, p+1)
	 if p = 0 then exit end if
      end while
      if p = 0 then exit end if
      ret = append(ret, trim(source[begpos..p-1]))
   end while

   return append(ret, trim(source[begpos..length(source)]))
end function


global function parse_any (string source, string delimlist)
   -- Funktion zum Aufteilen von Strings in Wörter
   -- in : source    : ""  ==>	return 0
   --	   delimlist : ""  ==>	return 0
   --** korrekte Behandlung von DQ?
   sequence ret
   integer begpos, p, dq

   delimlist = remove_any(delimlist, {DQ})
   ret = {}
   p = 1
   dq = 0
   while 1 do
      begpos = verify(p+dq, source, delimlist)
      if begpos = 0 then exit end if

      if source[begpos] = DQ then
	 dq = 1
	 p = finds(DQ, source, begpos+1)
      else
	 dq = 0
	 p = finds_any(delimlist, source, begpos)
      end if
      if p then
	 ret = append(ret, source[begpos..p-1+dq])
      else
	 ret = append(ret, source[begpos..length(source)])
	 exit
      end if
   end while
   return ret
end function


--======================================================================

global function rot13 (string text)
   integer c

   for i = 1 to length(text) do
      c = text[i]
      if 'A' <= c and c <= 'Z' then
	 c += 32	-- 'A' --> 'a'
      end if
      if 'a' <= c and c <= 'm' then
	 text[i] += 13
      elsif 'n' <= c and c <= 'z' then
	 text[i] -= 13
      end if
   end for
   return text
end function

