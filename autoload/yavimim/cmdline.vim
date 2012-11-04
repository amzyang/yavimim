" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

function! yavimim#cmdline#init()
	let s:cmdpos = getcmdpos() - 1
	let s:match_lists = []
	let s:page_nr = 0
	let s:position = 0
	let s:keys = ''
	call yavimim#buffer#create('botright')
endfunction

function! yavimim#cmdline#wubi(char)
	" 先处理之前的输入
	if len(s:keys) > 4
		let s:keys .= a:char
		return ''
	elseif len(s:keys) == 4
		if empty(s:match_lists)
			let s:keys .= a:char
		else
			" 上档、更新选词buffer等
			let s:keys = a:char
			let s:match_lists = []
			" update_buffer()
			" after trigger commit
			return s:match_lists[0]
		endif
		return ''
	else
		let s:keys .= a:char
		let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
		call yavimim#buffer#update(copy(s:match_lists))
	endif
endfunction
