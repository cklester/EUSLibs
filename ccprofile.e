include registration.e

register_code("hirestime.e",{2007,10,18,0,0})

-- Coded by CCHris <ccuvier@free.fr>, v1.0: November 2004
-- hirestime.e - A Win32 library that uses the Windows API to profile Euphoria programs.
-- Terms of use:
-- The author hereby declare to unconditionally reject any kind of liability arising from the use or misuse of this software
-- Use at will, copy at will, modify at will as long as the original author(s) are given due credits.

-- 2007.05.25 - modified by cklester for use with BBCMF
-- 2007.06.13 - modified to not break on Linux/FreeBSD (hires timing is still Win32 only)
-- 2007.10.18 - imported code from ssl.e to avoid duplication in EusLibs

include std/dll.e
include std/machine.e
include misc.e

atom k32, pq, pc, p232, rcp
object xGetTickCount, xSleep

if platform() = WIN32 then
	k32=open_dll("kernel32")
	pq=define_c_func(k32,"QueryPerformanceFrequency",{C_UINT},C_UINT)
	pc=define_c_proc(k32,"QueryPerformanceCounter",{C_UINT})
	xGetTickCount     = define_c_func(open_dll("kernel32"), "GetTickCount", {}, C_LONG)
	xSleep            = define_c_proc(open_dll("kernel32"), "Sleep", {C_ULONG})
else
	k32 = -1
	pq = -1
	pc = -1
end if

p232=power(2,32)

atom ptest
sequence perf,times,total,started,fallback,pnames

perf={} times=perf total=perf started=perf fallback=perf pnames=perf
ptest = allocate(16)

if platform() = WIN32 then
	rcp=c_func(pq,{ptest})-1
else
	rcp = -1
end if

atom timeFactor

function isTF(integer a,object b,object c) if a then return b else return c end if end function
if platform() = WIN32 then
	timeFactor=isTF(rcp>-1,peek4u(ptest)+p232*peek4u(ptest+4),0)
end if

procedure start1(object o)
integer i
	if not sequence(o) then
		o = sprint(o)
	end if
	i = find(o,pnames)
	if i = 0 then
		pnames = append(pnames,o)
		i = length(pnames)
		perf &= 0
		times &= 0
		total &= 0
		started &= 0
		fallback &= 0
		perf[i] = allocate(16)
	end if
	c_proc(pc,{perf[i]})
	started[i]=1
end procedure

procedure stop1(object i)
sequence z
	if not sequence(i) then
		i = sprint(i)
	end if
	i = find(i,pnames)
	if i > 0 then
		if not started[i] then return end if
		c_proc(pc,{perf[i]+8})
		started[i]=0
		times[i]+=1
		z=peek4u({perf[i],4})
		z[3..4]-=z[1..2]
		total[i]+=((z[3]+p232*z[4])/timeFactor)
	end if
end procedure

procedure start2(object o)
integer i
	if not sequence(o) then
		o = sprint(o)
	end if
	i = find(o,pnames)
	if i = 0 then
		pnames = append(pnames,o)
		i = length(pnames)
		perf &= 0
		times &= 0
		total &= 0
		started &= 0
		fallback &= 0
	end if
	fallback[i]=time()
	started[i]=1
end procedure

procedure stop2(object i)
	if not sequence(i) then
		i = sprint(i)
	end if
	i = find(i,pnames)
	if not started[i] then return end if
	fallback[i]-=time()
	started[i]=0
	times[i]+=1
	total[i]-=fallback[i]
end procedure

integer sr_,st_

--map the global symbols to the appropriate internal routines
if find(-1,{k32,pq,pc,rcp}) then
	sr_=routine_id("start2") st_=routine_id("stop2")
else
	sr_=routine_id("start1") st_=routine_id("stop1")
end if

-- call this procedure before the firt statement of a section
global procedure HRT_start(object section)
	call_proc(sr_,{section})
end procedure

-- call this procedure after the last statement of a section
global procedure HRT_stop(object section)
	call_proc(st_,{section})
end procedure

global function HRT_gettime(object o)
	if not sequence(o) then
		o = sprint(o)
	end if
	o = find(o,pnames)
	if o > 0 then
		return total[o]
	else
		return 0
	end if
end function

global function HRT_results()
sequence result
	result = ""
	for i=1 to length(perf) do
		if times[i] > 0 then
			if times[i] > 1 then
				result &= sprintf("%s\n\tTotal time: %f seconds (%d runs); Average time per run: %f seconds\n",{pnames[i],total[i],times[i],total[i]/times[i]})
			else
				result &= sprintf("%s\n\tTotal time: %f seconds\n",{pnames[i],total[i]})
			end if
		else
			result &= sprintf("%s\n\tResults unavailable.\n",{pnames[i]})
		end if
	end for
	return result
end function

--this function returns a more precise value than time(), if the functionality is available.
global function HRT_time()
atom a
	a=allocate(8)
	c_proc(pc,{a})
	a=p232*peek4u(a+4)+peek4u(a)
	return a/timeFactor
end function

global procedure HRT_killtimer(object o)
integer i
	if not sequence(o) then
		o = sprint(o)
	end if
	i = find(o,pnames)
	if i > 0 then
		pnames = pnames[1..i-1] & pnames[i+1..$]
		perf = perf[1..i-1] & perf[i+1..$]
		times = times[1..i-1] & times[i+1..$]
		total = total[1..i-1] & total[i+1..$]
		fallback = fallback[1..i-1] & fallback[i+1..$]
		started = started[1..i-1] & started[i+1..$]
	end if
end procedure

-- timer()
-- functions same as time() but with 1/1000 resolution on Win32
global function timer()
	if platform() = 2 then
		return (c_func(xGetTickCount, {})/1000)
	else
		return time()
	end if
end function

-- stop(atom ms)
-- stops execution of the program by /ms milliseconds
global procedure stop(atom ms)
atom start
	if ms < 0 then ms = 0 end if
	if platform() = WIN32 then
		c_proc(xSleep, {ms})
	else
		start = timer()
		while 1 do
			if timer()-start >= (ms/1000) then
				exit
			end if
		end while
	end if
end procedure

