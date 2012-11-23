" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

function! Powerline#Functions#yavimim#status()
	if &l:iminsert != 1
		return 'EN'
	endif
	let sim_cht = g:yavimim_traditional ? '繁' : '简'
	let im = yavimim#backend#getim()
	let name = 'name' . (g:yavimim_traditional ? '_cht' : '')
	return im[name]."·".sim_cht
endfunction

