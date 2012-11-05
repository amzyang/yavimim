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
	if exists('g:yavimim.init')
		return
	endif
	let g:yavimim.init = 1
	let s:yavimim = {}
	runtime autoload/yavimim/user_config.vim
	call s:setup_backend()
endfunction

function! s:setup_backend()
	let l:wubi_qqs = split(globpath(&rtp, 'autoload/yavimim/wubi/qq.txt'), '\n')
	if len(l:wubi_qqs) > 0
		silent call yavimim#util#show_message()
	endif
	let s:yavimim.backends = {
				\ 'wubi_qq': {'path': l:wubi_qqs[0],
					\ 'type': 'wubi',
					\ 'keys': [],
					\ 'lines':[],
					\ 'name': 'QQ云五笔'}
				\ }
	let s:yavimim.metadatas = {'wubi': {'full': '五笔', 'short': '五'},
				\ 'pinyin': {'full': '拼音', 'short': '拼'}}
	let s:yavimim.im = s:yavimim.backends.wubi_qq
endfunction

function! yavimim#getim()
	return s:yavimim.im
endfunction
" ==============================================================================
" key mappings
" ==============================================================================
