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
	if exists('g:yavimim_initialized')
		return
	endif
	let g:yavimim_initialized = 1
	runtime autoload/yavimim/user_config.vim
	call yavimim#backend#setup_backend()
endfunction
