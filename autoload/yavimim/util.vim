" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

function! yavimim#util#show_message(...)
	let yavimim#util#yavimim_verbose =
				\ exists('g:yavimim_verbose') ? g:yavimim_verbose : 1
	if !yavimim#util#yavimim_verbose
		return
	endif

	for l:message in a:000
		" @TODO
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

function! yavimim#util#get_mode()
	return stridx("iR", mode(1)) + 1 ? 'insert' : 'cmdline'
endfunction

function! yavimim#util#get_number()
	let numbers = split(g:yavimim_number, '\s*,\s*')
	let cmdline = str2nr(numbers[0])
	let cmdline = cmdline ? cmdline : 5
	let insert = len(numbers) == 2 ? str2nr(numbers[1]) : cmdline
	let insert = insert ? insert : 10
	let mode = yavimim#util#get_mode()
	let num = mode == 'insert' ? insert : cmdline
	return num
endfunction

function! yavimim#util#get_page_nr()
	let mode = yavimim#util#get_mode()
	let page_nr = mode == 'insert' ? b:yavimim.page_nr :
				\ g:_yavimim_page_nr
	return page_nr
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

function! yavimim#util#encoding(line)
	if &enc == 'utf-8'
		return a:line
	endif
	try
		let line = iconv(a:line, 'utf-8', &enc)
		return line
	catch /.*/
		echoerr "Maybe iconv feature is missing.
					\ See http://www.vim.org/download.php for more details."
		return ''
	endtry
endfunction
