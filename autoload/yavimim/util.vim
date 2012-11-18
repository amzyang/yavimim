" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

function! yavimim#util#show_message(...)
	let yavimim#util#yavimim_verbose =
				\ exists('g:yavimim_verbose') ? g:yavimim_verbose : 1
	if !yavimim#util#yavimim_verbose
		return
	endif

	for l:message in a:000
		echomsg l:message
		unlet l:message
	endfor
endfunction

function! yavimim#util#pprint(var)
	" pretty printer, your python guys know it. ;)
endfunction

function! yavimim#util#debugprint(list)
	if !has("unix")
		call yavimim#util#show_message(
					\"*nix only, this doesn't support your platform")
	endif

	" happy debugging, ^_^
	" @NOTICE: tail -f /dev/shm/yavimim.debug
	call yavimim#util#show_message("tail -f /dev/shm/yavimim.debug")
	let l:debug_file = "/dev/shm/yavimim.debug"
	let l:tmp = "/dev/shm/.yavimim.debug.tmp"
	if filereadable(l:debug_file)
		call writefile(map(deepcopy(a:list, 1), 'string(v:val)'), l:tmp)
		call system("cat ".l:tmp." >> " . l:debug_file)
	else
		call writefile(map(deepcopy(a:list, 1), 'string(v:val)'), l:debug_file)
	endif
endfunction

function! yavimim#util#getmode()
	return mode(1) == 'i' ? 'insert' : 'cmdline'
endfunction

function! yavimim#util#keycode(name)
	let keycodes = {
				\ 'langmap': 30
				\ }
	return get(keycodes, a:name, 0)
endfunction

function! yavimim#util#nr2float(number)
	return a:number + 0.0
endfunction
