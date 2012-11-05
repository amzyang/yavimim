" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

let s:map_args = ''

function! yavimim#cmdline#toggle()
	let s:cmdpos = getcmdpos() - 1
	let s:match_lists = []
	let s:page_nr = 0
	let s:position = 0
	if &iminsert != 1
		call s:mappings()
	else
		lmapclear <buffer>
		lmapclear
	endif
	return nr2char(yavimim#util#keycode('langmap'))
endfunction

function! s:mappings()
	" key mappings
	lmapclear <buffer>
	lmapclear
	call s:lmap_letters()
	call s:lmap_punctuations()
endfunction

function! s:lmap_letters()
	for l:letter in range(char2nr('a'), char2nr('z'))
		silent execute printf("lnoremap %s %s <C-R>=yavimim#cmdline#letter('%s')<CR>",
					\ s:map_args, nr2char(l:letter), nr2char(l:letter))
	endfor
endfunction

function! yavimim#cmdline#letter(char)
	let s:cmdline = getcmdline()
	let s:cmdpos = getcmdpos()
	let s:cmdtype = getcmdtype()
	let im = yavimim#getim()
	let s:keys = a:char
	let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
	call s:echo()
	while 1
		let nr = getchar()
		let char = nr2char(nr)
		
		" lowercase character
		if char =~ '\l'
			let s:keys .= char
			let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
			if len(s:match_lists) == 1
					return s:do_commit(s:match_lists[0])
			else
				call s:echo()
			endif
		" digit
		elseif char =~ '\d'
			" @TODO: don't overflow
			if char > len(s:match_lists)
			else
				let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
				return s:do_commit(s:match_lists[char - 1])
			endif
		" backspace/ctrl-h
		elseif nr == 8 || nr == 0
			if !empty(s:keys)
				let len = len(s:keys)
				if len == 1
					let s:keys = ''
					return s:do_cancel_commit()
				else
					let s:keys = s:keys[:len - 2]
				endif
			else
				return s:do_cancel_commit()
			endif
			let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
			call s:echo()
		" space
		elseif nr == 32
			if !empty(s:match_lists)
				let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
				return s:do_commit(s:match_lists[0])
			endif	
		" enter
		elseif nr == 13
			return s:do_cancel_commit()
		" 普通标点
		elseif yavimim#punctuation#is_in(char)
			let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
			let trans = yavimim#punctuation#origin2trans(char)
			if empty(s:match_lists)
				return s:do_cancel_commit() . trans
			else
				return s:do_commit(s:match_lists[0]) . trans
			endif
		else
			return s:do_cancel_commit()
		endif
	endwhile
	return ''
endfunction

function! s:do_commit(string)
	let s:keys = ''
	let [first, second] = yavimim#backend#wubi_qq_spliter(a:string)
	call s:echo()
	return first
endfunction

function! s:do_cancel_commit()
	let key = s:keys
	let s:keys = ''
	let s:match_lists = []
	return key
endfunction

function! s:lmap_punctuations()
	let index = 0
	let origin = yavimim#punctuation#origin()
	let trans = yavimim#punctuation#trans()
	while index < len(origin)
		let o = origin[index]
		let t = trans[index]
		silent execute "lnoremap" s:map_args o t
		let index += 1
	endwhile
endfunction

function! s:echo()
	let new_cmd = s:get_updated_cmdline()
	echo new_cmd
	echohl Title | echon "\n[五]" | echohl None

	let idx = 1
	if empty(s:match_lists)
		echon "  "
		echohl WarningMsg | echon "无候选词" | echohl None 
	endif
	for match in s:match_lists[0:4]
		let idx = idx % 10
		echon "  "
		echohl LineNr | echon idx | echohl None
		echon "."
		let [first, second] = yavimim#backend#wubi_qq_spliter(match)
		echon first
		echohl Comment | echon second | echohl None
		let idx += 1
	endfor

endfunction

function! s:get_updated_cmdline()
	let commandline = s:cmdline
	if len(commandline) == s:cmdpos - 2
		let commandline_update = commandline . keys
	else
		let commandline_update = commandline[:s:cmdpos - 2] . s:keys . commandline[s:cmdpos - 1:]
	endif
	return getcmdtype() . commandline_update
endfunction

