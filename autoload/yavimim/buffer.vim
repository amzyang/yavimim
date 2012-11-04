" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

function! yavimim#buffer#create(position)
	silent execute 'keepalt' (a:position ? 'botright' : 'topleft') '1new YaVimIM'
	let s:yavimim_bufnr = bufnr('%')
	call setbufvar(s:yavimim_bufnr, '&filetype', 'YaVimIM')
	hide
endfunction

function! yavimim#buffer#getbufnr()
	return s:yavimim_bufnr
endfunction

function! yavimim#buffer#update(list)
	silent execute "buffer" s:yavimim_bufnr
	call setline(1, join(a:list, '\t'))
endfunction
