include std/error.e
include std/get.e
include std/sort.e
include std/filesys.e
include std/console.e
include std/text.e
include std/io.e

integer secs, doOutput
sequence bench_parameters = {}
    
sequence tests
	tests = {{"Default"},{{{},{}}}}

function string(object x)
integer success = sequence(x)
	if success then
		for t=1 to length(x) do
			if sequence(x[t]) then
				return 0
			end if
		end for
	end if
	return success
end function
		
public procedure add_test(sequence name, object id)
integer i
	if atom(id) then
		if id != -1 then
			tests[2][1][1] = append(tests[2][1][1],name)
			tests[2][1][2] &= id
		else
			crash("Bad routine ID")
		end if
	else
		i = find( id[1], tests[1] )
		if i > 0 then -- test exists...
			tests[2][i][1] = append(tests[2][i][1],name)
			tests[2][i][2] &= id[2]
		else
			tests[1] = append(tests[1],id[1])
			tests[2] = append(tests[2],{{name},id[2]})
		end if
	end if
end procedure

public procedure set_bench_timer(integer i)
    secs = i
end procedure

public procedure output_bench_test_result(integer b)
    doOutput = b
end procedure

public procedure add_bench_parameter(sequence o, sequence desc = "")
	bench_parameters = append(bench_parameters,{o,desc})
end procedure

public function get_bench_parameters()
	return bench_parameters
end function

public procedure save_bench_parameters()
atom fn = open("params.txt","w")
	print(fn,bench_parameters)
	close(fn)
end procedure

integer screen_display, file_write
atom file_id = -1

procedure bench_display( sequence s )
	if screen_display then
		display( s )
	end if
	if file_id > 0 then
		puts(file_id,s)
	end if
end procedure

public procedure run_tests( integer show = 0, integer save = 1 )
atom c, t, fn
integer f, err
sequence test_results, currtest, dir_name, bp
object r, temp, test

	dir_name = "bench_test_results"
	screen_display = show
	file_write = save
	
    err = 0

    for a=1 to length(bench_parameters) do
	    clear_screen()
    	bp = bench_parameters[a][1]
		if length( bench_parameters[a][2] ) > 0 then
			bench_display(bench_parameters[a][2] & "\n" )
		end if
	    for testid =1 to length( tests[1] ) do
	    	if length(tests[2][testid][1]) > 0 then
			    test_results = {}
		    	bench_display("Test Name: " & tests[1][testid])
		    	currtest = tests[2][testid]
		    	for x=1 to length(currtest[1]) do
					c=0
					bench_display("\nStarting test " & currtest[1][x] )
					t = time() + secs
					while t > time() do
						test = call_func(currtest[2][x],bp)
						c += 1
					end while
					test_results = append(test_results,{c,currtest[1][x],test})
					printf(1,"...Done! (%d)",{c})
				end for
		
			    clear_screen()  
			    test_results = -sort(-test_results)
			    bench_display("\nFinal Results for Test Set " & sprint(a) & " of " & sprint(length(bench_parameters)) & ":")
				if length( bench_parameters[a][2] ) > 0 then
					bench_display(bench_parameters[a][2])
				end if
			    for x=1 to length(test_results) do
				printf(1,"\n%s - %d",{test_results[x][2],test_results[x][1]})
				
				if file_write then
					file_id = open(dir_name & "\\test_results_" & sprint(x) & ".txt","a")
				end if
	
				if x=1 then
				    bench_display(" <-- Fastest!")
				    f = test_results[x][1]
				    r = test_results[x][3]
				    if doOutput then
				    	temp = dir("test_results")
				    	if atom(temp) then -- directory doesn't exist yet
				    		ifdef LINUX then
				    			system("mkdir " & dir_name,2)
				    		elsedef
				    			system("md " & dir_name,2)
				    		end ifdef
				    	end if
				    	if string(r) then
					    	puts(file_id,"\n" & r)
					    else
					    	print(file_id,"\n" & r)
					    end if
				    	close(fn)
				    end if
				else
				    printf(1," <-- Slower by %f%%",{ 100*(1-(test_results[x][1] / f)) } )
				    if not equal(r,test_results[x][3]) then
						bench_display("\nRESULTS NOT EQUAL!!!")
						if doOutput then
					    	if string(test_results[x][3]) then
						    	puts(file_id,"\n" & test_results[x][3])
						    else
						    	print(file_id,test_results[x][3])
						    end if
						end if
						err = 1
				    end if
				end if
				if err then
				    bench_display("\nSome results were bad.")
				end if
			    if file_write then
					close(file_id)
					file_id = -1
				end if
			    end for
			    if show then
				    display("\n\nPress any key to continue.")
				    if wait_key() then end if
				end if
			end if
	    end for
    end for
	    
    display("\n\nPress 'Y' to run again, any other key to quit.")
    if find(wait_key(),"Yy") > 0 then
	run_tests(show)
    end if

end procedure

set_bench_timer(3)
output_bench_test_result( 0 )

