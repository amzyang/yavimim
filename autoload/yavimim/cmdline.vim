" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

function! yavimim#cmdline#init()
	let s:cmdpos = getcmdpos() - 1
	let s:match_lists = []
	let s:page_nr = 0
	let s:position = 0
endfunction

function! yavimim#cmdline#wubi(char)
	let im = yavimim#getim()
	let keys = a:char
	let s:match_lists = []
	while 1
		" 先处理之前的输入
		if len(keys) > 4
			call s:echo()
		elseif len(keys) == 4 || len(s:match_lists) == 1
			if empty(s:match_lists)
			else
				" 上档、更新选词buffer等
				" update_buffer()
				" after trigger commit
				return s:match_lists[0]
			endif
		else
			let s:match_lists = yavimim#backend#get_match_lists(im, keys)
			call s:echo()
		endif
		
		let nr = getchar()
		let char = nr2char(nr)
		
		if char =~ '\l'
			let keys .= char
		elseif char =~ '\d'
			" @TODO: don't overflow
			return s:match_lists[char]
		" space
		elseif nr == 32
			return s:match_lists[0]
		else
			return keys.char
		endif
	endwhile
	return ''
endfunction

function! s:echo()
endfunction
