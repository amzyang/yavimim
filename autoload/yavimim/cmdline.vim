" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

let s:map_args = ''
let s:cmdline_single_quote = 0
let s:cmdline_double_quote = 0
let s:cmdline_square_quote = 0

autocmd YaVimIM CmdwinEnter call s:cmdline_reset()

function! s:cmdline_reset()
	let s:cmdline_single_quote = 0
	let s:cmdline_double_quote = 0
	let s:cmdline_square_quote = 0
endfunction

function! yavimim#cmdline#toggle()
	let s:cmdpos = getcmdpos() - 1
	let s:match_lists = []
	let s:page_nr = 1
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
endfunction

function! yavimim#cmdline#en()
	call inputsave()
	echohl Comment
	let string = input(">> ")
	echohl None
	call inputrestore()
	return string
endfunction

function! s:lmap_letters()
	for number in range(char2nr('a'), char2nr('z'))
		let char = nr2char(number)
		silent execute "lnoremap <silent>" s:map_args char
					\ printf("<C-R>=yavimim#cmdline#letter('%s')<CR>", char)
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
		if type(nr) == type(0)
			let char = nr2char(nr)
		else
			let char = ''
		endif
		
		" lowercase character
		if char =~ '\l'
			let s:keys .= char
			let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
			if len(s:match_lists) == 1
					return s:do_commit(s:word_return())
			else
				let s:page_nr = 1
				call s:echo()
			endif
		" digit
		elseif char =~ '\d'
			" @TODO: don't overflow
			if char == 0
				char == 10
			endif
			if (s:page_nr -1) * 5 + char > len(s:match_lists) || char > 5
			else
				let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
				return s:do_commit(s:word_return(char - 1))
			endif
		" backspace/ctrl-h
		elseif nr == "\<BS>" || nr == 8
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
			let s:page_nr = 1
			call s:echo()
		" space
		elseif nr == 32
			if !empty(s:match_lists)
				let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
				return s:do_commit(s:word_return())
			endif	
		elseif nr == "\<Enter>"
			return s:do_cancel_commit()
		" 普通标点
		elseif yavimim#punctuation#is_in(char)
			let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
			let trans = yavimim#punctuation#origin2trans(char)
			if empty(s:match_lists)
				return s:do_cancel_commit() . trans
			else
				return s:do_commit(s:word_return()) . trans
			endif
		elseif index(["'", '"', ']'], char) >= 0
			let s:match_lists = yavimim#backend#get_match_lists(im, s:keys)
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
				return s:do_commit(s:word_return()) . trans
			endif
		" -=翻页
		elseif index(["-", "=", "\<PageUp>", "\<PageDown>"], char) >= 0
			if index(["-", "\<PageUp>"], char) >= 0
				let s:page_nr -= 1
				if s:page_nr < 1
					let s:page_nr = s:total_pagenr()
				endif
			else
				let s:page_nr += 1
				if s:page_nr > s:total_pagenr()
					let s:page_nr = 1
				endif
			endif
			call s:echo()
		else
			return s:do_cancel_commit()
		endif
	endwhile
	return ''
endfunction

function! s:word_return(...)
	let idx = (s:page_nr - 1) * 5
	if a:0
		let idx += a:1
	endif
	return s:match_lists[idx]
endfunction

function! s:do_commit(string)
	let s:page_nr = 1
	let s:keys = ''
	let [first, second] = yavimim#backend#wubi_qq_spliter(a:string)
	call s:echo()
	return first
endfunction

function! s:do_cancel_commit()
	let s:page_nr = 1
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
	
	" double/single/square quote
	let quotes = {'single': "'", 'double': '"', 'square': ']'}
	for [type, quote] in items(quotes)
		silent execute "lnoremap" s:map_args quote
					\ printf("<C-R>=yavimim#cmdline#quote('%s')<CR>", type)
	endfor
endfunction

function! yavimim#cmdline#quote(type)
	let pairs = yavimim#punctuation#getpairs()
	silent execute printf("let s:cmdline_%s_quote += 1", a:type)
	silent execute printf("return pairs.%s[(s:cmdline_%s_quote - 1) %% 2]",
				\ a:type, a:type)
endfunction


function! s:echo()
	let new_cmd = s:get_updated_cmdline()
	echo new_cmd
	echohl Comment | echon "\n[五]" | echohl None
	let total_pagenr = s:total_pagenr()
	echon s:pager_label(s:page_nr, total_pagenr)

	let idx = 1
	if empty(s:match_lists)
		echon "  "
		echohl WarningMsg | echon "无候选词" | echohl None 
	endif
	for match in s:match_lists[((s:page_nr - 1) * 5):(s:page_nr * 5 - 1)]
		let idx = idx % 10
		echon "  "
		echohl Number | echon idx | echohl None
		echon "."
		let [first, second] = yavimim#backend#wubi_qq_spliter(match)
		echon first
		echohl Comment | echon second | echohl None
		let idx += 1
	endfor
endfunction

function! s:pager_label(current, total)
	if a:total > 1
		return  " " . printf(printf("%%%dd", len(a:total)), a:current)
					\ . "/" . a:total
	else
		return ""
	endif
endfun

function! s:total_pagenr()
	return float2nr(ceil(len(s:match_lists) / yavimim#util#nr2float(5)))
endfunction

function! s:get_updated_cmdline()
	let commandline = s:cmdline[:s:cmdpos - 2] . s:keys .
				\ s:cmdline[s:cmdpos - 1:]
	return getcmdtype() . commandline
endfunction
