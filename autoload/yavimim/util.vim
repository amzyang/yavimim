" vim: set noexpandtab tabstop=4 shiftwidth=4:
scriptencoding utf-8
function! yavimim#util#show_message(...)
	let yavimim#util#yavimim_verbose =
				\ exists('g:yavimim_verbose') ? g:yavimim_verbose : 1
	if !yavimim#util#yavimim_verbose
		return
	endif

	for l:message in a:000
		echo l:message
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

function! yavimim#util#powerline_hook()
    let l:colorschemes = Pl#Colorscheme#Init([
        \ Pl#Hi#Segments(['yavimim:statusline'], {
            \ 'n': ['gray8', 'gray2'],
            \ 'i': ['mediumcyan', 'darkestblue']
            \ })
    \])

    for key in keys(l:colorschemes)
        let g:Powerline#Colorschemes#{g:Powerline_colorscheme}#colorscheme[key]
                    \ = l:colorschemes[key]
    endfor
endfunction
