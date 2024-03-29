" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

let s:map_args = ''
let g:_yavimim_page_nr = 1

function! yavimim#cmdline#toggle()
	let s:cmdpos = getcmdpos() - 1
	let s:match_lists = []
	let g:_yavimim_page_nr = 1
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
	lnoremap <expr> ;; yavimim#cmdline#en() 
	lnoremap <expr> ]] yavimim#vk#vk()
endfunction

function! yavimim#cmdline#en()
	echohl YaVimIMComment
	let string = input(">>")
	echohl None
	return string
endfunction

function! s:lmap_letters()
	for number in range(char2nr('a'), char2nr('z'))
		let char = nr2char(number)
		silent execute "lnoremap <expr>" s:map_args char
					\ printf("yavimim#cmdline#letter('%s')", char)
	endfor
endfunction

function! yavimim#cmdline#letter(char)
	let s:cmdline = getcmdline()
	let s:cmdpos = getcmdpos()
	let s:cmdtype = getcmdtype()
	let im = yavimim#backend#getim()
	let s:keys = a:char
	let g:_yavimim_page_nr = 1
	let s:match_lists = yavimim#backend#matches(s:keys)
	call s:echo()
	while 1
		let nr = getchar()
		let char = type(nr) == type(0) ? nr2char(nr) : nr
		
		" backspace/ctrl-h
		if nr == "\<BS>" || nr == 8
			if !empty(s:keys)
				let len = strlen(s:keys)
				if len == 1
					let s:keys = ''
					return s:do_cancel_commit()
				else
					let s:keys = s:keys[:len - 2]
				endif
			else
				return s:do_cancel_commit()
			endif
			let s:match_lists = yavimim#backend#matches(s:keys)
			let g:_yavimim_page_nr = 1
			call s:echo()
		" space
		elseif nr == 32
			if !empty(s:match_lists)
				return s:do_commit()
			endif	
		elseif nr == "\<Enter>"
			return s:do_cancel_commit()
		" <Ctrl-E>
		elseif nr == 5
			let s:keys = ''
			return s:do_cancel_commit()
		" 普通标点
		elseif yavimim#punctuation#is_in(char)
			let trans = yavimim#punctuation#origin2trans(char)
			if empty(s:match_lists)
				return s:do_cancel_commit() . trans
			else
				return s:do_commit() . trans
			endif
		elseif index(["'", '"', ']'], char) >= 0
			let s:match_lists = yavimim#backend#matches(s:keys)
			let type = 'single'
			if char == '"'
				let type = 'double'
			elseif char == ']'
				let type = 'square'
			endif
			let trans = yavimim#cmdline#quote(type)
			if empty(s:match_lists)
				return s:do_cancel_commit() . trans
			else
				return s:do_commit() . trans
			endif
		" -=翻页
		elseif index(["-", "=", "\<PageUp>", "\<PageDown>"], char) >= 0
			if g:_yavimim_total_nr <= 1
				let s:match_lists = yavimim#backend#matches(s:keys)
				call s:echo()
			else
				if index(["-", "\<PageUp>"], char) >= 0
					let g:_yavimim_page_nr -= 1
				else
					let g:_yavimim_page_nr += 1
				endif
				let s:match_lists = yavimim#backend#matches(s:keys)
				call s:echo()
			endif
		" lowercase character
		elseif char =~ '\l'
			let s:match_lists = yavimim#backend#matches(s:keys)
			if strlen(s:keys) == 4 && !g:_yavimim_pinyin_in_matches &&
						\ len(s:match_lists)
				return s:do_commit()."\<C-R>=".feedkeys(char, 't')." ? '' : ''\<CR>"
			endif
			let s:keys .= char
			let s:match_lists = yavimim#backend#matches(s:keys)
			if len(s:match_lists) &&
						\ yavimim#backend#should_auto_commit(strlen(s:keys))
				return s:do_commit()
			endif
			let g:_yavimim_page_nr = 1
			call s:echo()
		" digit
		elseif char =~ '\d'
			" @TODO: don't overflow
			let char = char ? char : 10
			if char > len(s:match_lists) || char > yavimim#util#get_number()
			else
				let s:match_lists = yavimim#backend#matches(s:keys)
				return s:do_commit(char - 1)
			endif
		else
			return s:do_cancel_commit()
		endif
	endwhile
	return ''
endfunction

function! s:do_commit(...)
	let idx = a:0 > 0 ? a:1 : 0
	return s:match_lists[idx]['word']
endfunction

function! s:do_cancel_commit()
	if empty(s:keys)
		silent execute printf('return "%s"', '\<C-L>')
	else
		return s:keys
	endif
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
	
	" double/single/square quote
	let quotes = {'single': "'", 'double': '"', 'square': ']'}
	for [type, quote] in items(quotes)
		silent execute "lnoremap <expr>" s:map_args quote
					\ printf("yavimim#cmdline#quote('%s')", type)
	endfor
endfunction

function! yavimim#cmdline#quote(type)
	let pairs = yavimim#punctuation#getpairs()[a:type]
	let full_cmdline = getcmdline()
	let cmdpos = getcmdpos()
	let string = full_cmdline[:cmdpos - 2]
	return s:fetch_paired(pairs, string)
endfunction

function! s:echo()
	let pieces = s:get_updated_cmdline()
	echo pieces[0].pieces[1]
	echohl YaVimIM | echon pieces[2] | echohl None
	echon pieces[3]
	echohl YaVimIMComment | echon "\r\n[五]" | echohl None
	if empty(s:match_lists)
		echon " "
		echohl YaVimIMWarningMsg | echon "无候选词" | echohl None 
	else
		let idx = 1
		for item in s:match_lists
			if idx == 1
				echon " "
			else
				echon "  "
			endif
			echohl YaVimIMNumber | echon idx % 10 | echohl None
			echohl YaVimIMComment | echon "." | echohl None
			echon item.word
			echohl YaVimIMComment | echon item.tip | echohl None
			echohl YaVimIMComment | echon item.kind | echohl None
			let idx += 1
		endfor
		if g:_yavimim_total_nr > 1
			echon "  " g:_yavimim_page_nr "/" g:_yavimim_total_nr
		endif
	endif
	echon "\r"
endfunction

function! s:get_updated_cmdline()
	return [getcmdtype(), s:cmdline[:s:cmdpos - 2],
				\ s:keys, s:cmdline[s:cmdpos - 1:]]
endfunction

function! s:fetch_paired(pairs, string)
	let stack = []
	let i = 0
	let length = strlen(substitute(a:string, ".", "x", "g"))
	while i < length
		let char = strpart(a:string, byteidx(a:string, i),
					\ byteidx(a:string , i+1) - byteidx(a:string, i))
		if index(a:pairs, char) >= 0
			if empty(stack)
				call add(stack, char)
			elseif char == stack[len(stack) - 1]
				call remove(stack, len(stack) - 1)
			else
				call add(stack, char)
			endif
		endif
		let i += 1
	endwhile
	let idx = empty(stack) ? 0 : (index(a:pairs, stack[len(stack) - 1]) + 1) % 2
	return a:pairs[idx]
endfunction
