" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
" ==============================================================================
" initialization
" ==============================================================================
function! yavimim#toggle_insert()
	call s:init()
	return yavimim#insert#toggle()
endfunction

function! yavimim#toggle_cmdline()
	call s:init()
	return yavimim#cmdline#toggle()
endfunction

function! s:init()
	if exists('g:_yavimim_initialized')
		return
	endif
	let g:_yavimim_initialized = 1
	call yavimim#backend#setup_backend()
	call yavimim#highlight#init_color()
endfunction
