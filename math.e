include std/math.e
include std/get.e

global constant
   E		= 2.718281828459045235,
   PI		= 3.1415926535897932,
   EULER_GAMMA	= 0.57721566490153286,	 -- Euler-Mascheroni constant  
   LN2		= log(2),
   LN10 	= log(10),
   SQRT2	= sqrt(2),
   HALF_SQRT2	= SQRT2/2.0,
   HALF_PI	= PI/2.0, 
   QUARTER_PI	= PI/4.0, 
   TWO_PI	= PI*2.0, 
   EULER_NORMAL = 1/sqrt(TWO_PI),
   PHI = 1.618033988749894848,
   MAX_INTEGER = #3FFFFFFF,	     -- =  power(2,30)-1
   MIN_INTEGER = #C0000000	 -- = -power(2,30)

------------------------------------------------------------------------
----------------------------[ global types ]----------------------------
------------------------------------------------------------------------

global type hugeint (object x)
   -- This type can hold huger integers than Euphoria's built-in
   -- integer type (> 1073741823).
   -- It is technically an atom, but mathematically an integer.

   if atom(x) then
      return x = floor(x)
   end if
   return 0
end type

-- global type hugeint_list (object x)
--    -- list of huge integers (sequence that is not nested), min. 1 element
--
--    if atom(x) or length(x) = 0 then
--	 return 0
--    end if
--    for i = 1 to length(x) do
--	 if not hugeint(x[i]) then return 0 end if
--    end for
--    return 1
-- end type

global type nonnegative_int (object x)
   if integer(x) then
      return x >= 0
   end if
   return 0
end type

global type positive_int (object x)
   if integer(x) then
      return x > 0
   end if
   return 0
end type

------------------------------------------------------------------------
----------------------------[ local types ]-----------------------------
------------------------------------------------------------------------

type positive_not_1 (object x)
   if atom(x) and x > 0 then
      return x != 1
   end if
   return 0
end type


global function log2 (object x)
   -- logarithm base 2
   -- in : (sequence of) real number(s) > 0
   -- out: (sequence of) real number(s)
   -- Note: This function returns _exact_ results for all integral
   --	    powers of 2 in the half-closed interval ]0,#FFFFFFFF]

   if atom(x) then
      if x = #20000000 then
	 return 29		 -- log(x)/LN2 is imprecise in this case 
      elsif x = #80000000 then
	 return 31		 -- log(x)/LN2 is imprecise in this case
      else 
	 return log(x)/LN2
      end if
   end if

   for i = 1 to length(x) do
      x[i] = log2(x[i])
   end for
   return x
end function

global function log10 (object x)
   -- logarithm base 10
   -- in : (sequence of) real number(s) > 0
   -- out: (sequence of) real number(s)

   return log(x)/LN10
end function

global function logx (object x, positive_not_1 base)
   -- general logarithm function
   -- in  : x	: (sequence of) atom(s) > 0
   --	    base: atom > 0 and != 1
   -- out : (sequence of) atom(s)
   -- Note: If x = 1 then the function returns 0 for any possible base.

   return log(x)/log(base)
end function

global function exp (object x)
   return power(E, x)
end function

global function sinh (object x)
   return (exp(x) - exp(-x)) / 2
end function

global function cosh (object x)
   return (exp(x) + exp(-x)) / 2
end function

global function tanh (object x)
   return sinh(x) / cosh(x)
end function

global function arcsinh (object x)
   return log(x + sqrt(x*x+1))
end function

type not_below_1 (object x)
   if atom(x) then
      return x >= 1.0
   end if

   for i = 1 to length(x) do
      if not not_below_1(x[i]) then
	 return 0
      end if
   end for
   return 1
end type

global function arccosh (not_below_1 x)
   return log(x + sqrt(x*x-1))
end function

type abs_below_1 (object x)
   if atom(x) then
      return x > -1.0 and x < 1.0
   end if

   for i = 1 to length(x) do
      if not abs_below_1(x[i]) then
	 return 0
      end if
   end for
   return 1
end type

global function arctanh (abs_below_1 x)
   return log((1+x)/(1-x)) / 2
end function

global function euslibs_abs(object a)
   -- use standard lib abs()
    object t
    if atom(a) then
    	if a >= 0 then
	        return a
    	else
	        return - a
	    end if
    end if
    for i = 1 to length(a) do
    	t = a[i]
	    if atom(t) then
    	    if t < 0 then
		        a[i] = - t
	        end if
    	else
	        a[i] = abs(t)
    	end if
    end for
    return a
end function

global function sign(object x)
   --  x < 0  ==>  -1
   --  x = 0  ==>   0
   --  x > 0  ==>  +1
  return (x > 0) - (x < 0)
end function

global function euslibs_ceil (object x) -- ceil() is now part of Euphoria standard library math.e
   -- the opposite of floor()
   -- Examples: ? ceil(3.2)	     --> 4
   --		? ceil({-3.2,7,1.6}) --> {-3,7,2}

   return -floor(-x)
end function

type sequence_of_a_xor_s (object x)
   -- A sequence whose top-level elements are either only atoms or only
   -- sequences (or which is empty).
   integer object_type

   if atom(x) then
      return 0
   end if

   if length(x) = 0 then
      return 1
   end if

   object_type = atom(x[1])
   for i = 2 to length(x) do
      if object_type != atom(x[i]) then
	 return 0
      end if
   end for
   
   return 1
end type

global function sum (sequence_of_a_xor_s list)
   -- Return the sum of all elements in 'list'.
   -- Note: This does not do a recursive sum of sub-sequences.
   object ret

   if length(list) = 0 then
      return 0
   end if

   ret = list[1]
   for i = 2 to length(list) do
      ret += list[i]
   end for
   return ret
end function

constant RADIANS_TO_DEGREES = 180.0/PI

global function radians_to_degrees (object x)
   -- in : (sequence of) angle(s) in radians
   -- out: (sequence of) angle(s) in degrees

   return x * RADIANS_TO_DEGREES
end function

constant DEGREES_TO_RADIANS = PI/180.0

global function degrees_to_radians (object x)
   -- in : (sequence of) angle(s) in degrees
   -- out: (sequence of) angle(s) in radians

   return x * DEGREES_TO_RADIANS
end function

type trig_range (object x)
   --  values passed to arccos and arcsin must be [-1,+1]
   if atom(x) then
      return x >= -1 and x <= 1
   end if

   for i = 1 to length(x) do
      if not trig_range(x[i]) then
	 return 0
      end if
   end for
   return 1
end type

global function arcsin (trig_range x)
   -- returns angle in radians
   return 2 * arctan(x / (1.0 + sqrt(1.0 - x * x)))
end function

global function arccos (trig_range x)
   -- returns angle in radians
   return HALF_PI - 2 * arctan(x / (1.0 + sqrt(1.0 - x * x)))
end function

type point_pol (object x)
   if sequence(x) and (length(x) = 2)
   and atom(x[1]) and (x[1] >= 0)
   and atom(x[2]) then
      return 1 
   end if
   return 0
end type

global function polar_to_rect (point_pol p)
   -- convert polar coordinates to rectangular coordinates
   -- in : sequence of two atoms: {distance, angle};
   --	   'distance' must be >= 0, 'angle' is in radians 
   -- out: sequence of two atoms: {x, y}
   atom distance, angle, x, y

   distance = p[1]
   angle = p[2]
   x = distance*cos(angle)
   y = distance*sin(angle)
   return {x, y}
end function

type point_xy (object x)
   if sequence(x) and (length(x) = 2)
   and atom(x[1])
   and atom(x[2]) then
      return 1 
   end if
   return 0
end type

global function rect_to_polar (point_xy p)
   -- convert rectangular coordinates to polar coordinates
   -- in : sequence of two atoms: {x, y}
   -- out: sequence of two atoms: {distance, angle}
   --	   - 'distance' is always >= 0
   --	   - 'angle' is an atom that expresses radians,
   --	     and is in the half-closed interval ]-PI,+PI].
   --	     If 'distance' equals 0, then 'angle' is undefined.
   object angle
   atom distance, x, y

   x = p[1]
   y = p[2]
   distance = sqrt(x*x + y*y)
   if x > 0 then
      angle = arctan(y/x) 
   elsif x < 0 then
      if y < 0 then
	 angle = arctan(y/x) - PI
      else
	 angle = arctan(y/x) + PI
      end if
   else
      if y < 0 then
	 angle = -HALF_PI
      elsif y > 0 then
	 angle = HALF_PI
      else
	 angle = 0	       -- The angle is undefined in this case.
      end if
   end if
   return {distance, angle}
end function

global function max (sequence s)
   -- Search for the maximum value in s
   -- Return the value of that element.
atom maxn
    maxn = s[1]
    for i = 2 to length(s) do
	if maxn < s[i] then
	    maxn = s[i]
	end if
    end for
    return maxn
end function

global function max_index (sequence s)
   -- Search for the maximum value in s
   -- Return the index of that element.
atom maxi, maxn
	maxi = 1
	maxn = s[1]
	for i = 2 to length(s) do
		if s[i] > maxn then
			maxn = s[i]
			maxi = i
		end if
	end for
	return maxi
end function

global function min (sequence s)
   -- Search for the minimum value in s
   -- Return the value of that element.
atom maxn
    maxn = s[1]
    for i = 2 to length(s) do
	if maxn > s[i] then
	    maxn = s[i]
	end if
    end for
    return maxn
end function

-- min(sequence s)
-- returns the index of the element having minimum value
global function min_index(sequence s)
object mini, minn
    mini = 1
    minn = s[1]
	
    for i = 2 to length(s) do
	if s[i] < minn then
	    minn = s[i]
	    mini = i
	end if
    end for
    return mini
end function

global function lesser (object x1, object x2)
   -- Return the argument with the lesser value.
   -- Note: This does not do a recursive compare on sub-sequences.

   if compare(x1, x2) <= 0 then
      return x1
   else
      return x2
   end if
end function

global function greater (object x1, object x2)
   -- Return the argument with the greater value.
   -- Note: This does not do a recursive compare on sub-sequences.

   if compare(x1, x2) >= 0 then
      return x1
   else
      return x2
   end if
end function

-- range(object o, object min, object max)
-- returns true if o is between min and max inclusive
global function range(object o, object min, object max)
	return (o >= min) and (o <= max)
end function

global function mod (atom a, atom m)
   -- echte mod() Funktion, d.h. das Ergebnis liegt immer im Intervall [0,m[
   -- (i.Ggs. zu remainder())
   -- [after "Windmills -- Behind Modulo.htm"]
   -- zur Veranschaulichung siehe auch mod_rem.exw
   return a - m*floor(a/m)   -- where floor(x) = largest integer less than or equal to x
end function

global function trunc (object x)
   -- discard the noninteger part of (all elements of) x
   -- x may be an atom or a sequence

   if atom(x) then
      if x >= 0 then
	 return floor(x)
      else
	 return -floor(-x)   -- = ceil(x)
      end if
   end if

   for i = 1 to length(x) do
      x[i] = trunc(x[i])
   end for
   return x
end function


global function frac (object x)
   -- return the noninteger part of (all elements of) x (signed)
   -- (mit Vorzeichen, wie z.B. bei PB 3.2)
   -- x may be an atom or a sequence
   return remainder(x, 1)
end function

global function round_half_up (object x, nonnegative_int digits)
   -- * kaufmaennisch runden *
   -- in: digits: gewuenschte Anzahl der Ziffern rechts vom Dezimalpunkt
   -- (** ginge auch digits < 0 ?)

   -- Im Ggs. zur PB-Funktion ROUND(), die nach dem IEEE-Standard vorgeht,
   -- rundet diese Funktion, wenn der Wert der (digits+1)-ten Stelle 5 ist,
   -- den Betrag immer auf.
   --		      [nach Winer (1991), S. 456]
   atom p

   if atom(x) then
      p = power(10, digits)
      if x >= 0 then
	 return  floor( x*p + 0.5)/p
      else
	 return -floor(-x*p + 0.5)/p
      end if
   end if

   for i = 1 to length(x) do
      x[i] = round_half_up(x[i], digits)
   end for
   return x
end function

global function round_half_even (object x, nonnegative_int digits)
   -- * runden nach dem IEEE-Standard (wie die PB-Funktion ROUND()) *
   -- in: digits: gewuenschte Anzahl der Ziffern rechts vom Dezimalpunkt
   -- (** ginge auch digits < 0 ?)
   atom p, ret

   if atom(x) then
      p = power(10, digits)
      ret = floor(x*p + 0.5)
      if remainder(ret, 2) then
	 ret -= 1
      end if
      return ret/p
   end if

   for i = 1 to length(x) do
      x[i] = round_half_even(x[i], digits)
   end for
   return x
end function

------------------------------------------------------------------------

integer val_err_no
val_err_no = 0

global function val_err ()
   return val_err_no
end function

global function val (sequence s)
   sequence v
   object ret

   v = value(s)
   if v[1] = GET_SUCCESS then
      ret = v[2]
      if atom(ret) then
	 val_err_no = 0
	 return ret
      end if
   end if

   val_err_no = 1
   return 0
end function

global function random (integer lo, integer hi)
   -- return a random integer between lo and hi, inclusive
   -- hi < lo --> error
   lo -= 1
   hi -= lo
   return lo + rand(hi)
end function


