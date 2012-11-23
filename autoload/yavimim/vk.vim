" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

let s:vk = {}
let s:keyboard = "`1234567890-=qwertyuiop[]asdfghjkl;'\\zxcvbnm,./"
let s:keyboard_shift = '~!@#$%^&*()_+QWERTYUIOP{}ASDFGHJKL:"|ZXCVBNM<>?'
let s:vk_idx = 0
let s:sections = []
let s:vkbl = {'pc103':
			\ ['`1234567890-=', 'qwertyuiop[]\', 'asdfghjkl;''', 'zxcvbnm,./'],
		\ 'pc103_big_enter':
			\ ['`1234567890-=\', 'qwertyuiop[]', 'asdfghjkl;''', 'zxcvbnm,./'],
		\ 'hhkb':
			\ ['1234567890-=\`', 'qwertyuiop[]', 'asdfghjkl;''', 'zxcvbnm,./']}

function! s:char_shift_mod(char)
	let idx = stridx(s:keyboard, a:char)
	return s:keyboard_shift[idx]
endfunction

function! s:init()
	let path_list = split(globpath(&rtp, "autoload/yavimim/data/vk.conf"), '\n')
	if empty(path_list)
		call yavimim#util#show_message("无虚拟键盘数据，该功能无法使用！")
		finish
	endif
	let path = path_list[0]
	let lines = readfile(path)

	for line in lines
		if empty(line) || line =~ '^#' || line == '[VK]'
			continue
		endif

		if line =~ '^NAME='
			let [nouse, section] = split(line, '=')
			let section = yavimim#util#encoding(section)
			call add(s:sections, section)
			continue
		endif
		let line = yavimim#util#encoding(line)
		let key = line[0:0]
		let val = get(split(line[2:]), 0, '')
		let val_shift = get(split(line[2:]), 1, '')
		let key_shift = s:char_shift_mod(key)
		if !has_key(s:vk, section)
			let s:vk[section] = {}
		endif
		let s:vk[section][key] = val
		let s:vk[section][key_shift] = val_shift
	endfor
endfunction

call s:init()

function! s:display_vkb(kb)
	let [lefttop, leftbottom, righttop, rightbottom]    = ['┌', '└', '┐', '┘']
	let [horzup, horzdown, vertleft, vertright]         = ['┴', '┬', '┤', '├']
	let [vertbar, horzbar]                              = ['│', '─']
	let scroll                                          = '┼'
	
	let spin_width = strdisplaywidth(lefttop)
	let bar_repeat = 4 / spin_width

	let topcover = lefttop . repeat(horzbar, bar_repeat) . righttop
	let bottomcover = leftbottom . repeat(horzbar, bar_repeat) . rightbottom
	let block_width = 4 + 2 * spin_width

	let outeridx = 0
	let layout_keys = s:vkbl[g:yavimim_vkbl]
	let max_len = s:max_row_length(layout_keys)
	echohl Comment | echo ">>" | echohl None
	echon s:keys
	let title_offset = repeat(' ',
				\ (max_len * block_width - strdisplaywidth(join(s:sections, ' '))) / 2)
	let idx = 0
	echon "\n".title_offset
	while idx < len(s:sections)
		if (idx == s:vk_idx)
			echohl Title | echon s:sections[idx] | echohl None
		else
			echohl Comment | echon s:sections[idx] | echohl None
		endif
		if (idx < len(s:sections) - 1)
			echon ' '
		endif
		let idx += 1
	endwhile
	while outeridx < len(layout_keys)
		let keys = layout_keys[outeridx]
		let offset = repeat(' ', ((max_len - len(keys)) * block_width) / 2)
		let start = repeat(topcover, strlen(keys))
		echohl Comment | echon "\n".offset.start | echohl None
		let idx = 0
		echon "\n".offset
		while idx < len(keys)
			let key = keys[idx]
			let key_shift = s:char_shift_mod(key)
			let shift = has_key(a:kb, key_shift) ?  a:kb[key_shift] : ''
			let origin = has_key(a:kb, key) ? a:kb[key] : ''
			echohl Comment | echon vertbar | echohl None
			let spaces = repeat(' ', 4 - strdisplaywidth(origin.shift))
			echohl Normal
			echon printf("%-s%s%s", origin, spaces, shift) | echohl None
			echohl Comment | echon vertbar | echohl None
			let idx +=1
		endwhile
		let idx = 0
		echon "\n".offset
		while idx < len(keys)
			let key = keys[idx]
			let key_shift = s:char_shift_mod(key)
			let shift = has_key(a:kb, key_shift) ?  a:kb[key_shift] : ''
			let origin = has_key(a:kb, key) ? a:kb[key] : ''
			echohl Comment | echon vertbar | echohl None
			if empty(shift) && empty(origin)
				echohl Comment | echon printf(" %s  ", toupper(key)) | echohl None
			else
				echohl Keyword | echon printf(" %s  ", toupper(key)) | echohl None
			endif
			echohl Comment | echon vertbar | echohl None
			let idx +=1
		endwhile
		let end = repeat(bottomcover, strlen(keys))
		echohl Comment | echon "\n".offset.end | echohl None
		let outeridx += 1
	endwhile
	echon "\r"
endfunction

function! s:max_row_length(list)
	let max_len = 0
	for item in a:list
		let max_len = max_len < len(item) ? len(item) : max_len
	endfor
	return max_len
endfunction

function! s:cur_kb()
	return s:vk[s:sections[s:vk_idx]]
endfunction

function! yavimim#vk#vk()
	let s:keys = ''
	let kb = s:cur_kb()
	let cmdheight_saved = &cmdheight
	let &cmdheight = 18
	redraw
	call s:display_vkb(kb)

	while 1
		let nr = getchar()
		let char = type(nr) == type(0) ? nr2char(nr) : ''
		
		" backspace/ctrl-h
		if nr == "\<BS>" || nr == 8
			let mb_len = strlen(substitute(s:keys, ".", "x", "g"))
			let s:keys = mb_len <= 1 ? '' :
						\ s:keys[0 : byteidx(s:keys, mb_len - 1) - 1]
			call s:display_vkb(kb)
		elseif nr == "\<ESC>"
			let &cmdheight = cmdheight_saved
			redraw
			return ''
		elseif nr == "\<Enter>"
			let &cmdheight = cmdheight_saved
			redraw
			return s:keys
		" Ctrl-U
		elseif nr == 21
			let s:keys = ''
			call s:display_vkb(kb)
		" Ctrl-N
		elseif nr == 14 || nr == "\<Down>" || nr == "\<Right>"
			let kb = s:iter_vkb(1)
			call s:display_vkb(kb)
		" Ctrl-P
		elseif nr == 16 || nr == "\<Up>" || nr == "\<Left>"
			let kb = s:iter_vkb(-1)
			call s:display_vkb(kb)
		elseif nr == "\<Home>"
			let kb = s:iter_vkb(0 - s:vk_idx)
			call s:display_vkb(kb)
		elseif nr == "\<End>"
			let kb = s:iter_vkb(len(s:vk) - s:vk_idx - 1)
			call s:display_vkb(kb)
		elseif nr == "\<C-l>"
			call s:display_vkb(kb)
		elseif stridx(s:keyboard, char) >= 0 ||
					\ stridx(s:keyboard_shift, char) >= 0
			let val = get(kb, char, '')
			if !empty(val)
				let s:keys .= val
				call s:display_vkb(kb)
			endif
		else
			let &cmdheight = cmdheight_saved
			redraw
			return s:keys
		endif
	endwhile
endfunction

function! s:iter_vkb(step)
	let s:vk_idx += a:step
	if s:vk_idx >= len(s:sections)
		let s:vk_idx = 0
	elseif s:vk_idx < 0
		let s:vk_idx = len(s:sections) - 1
	endif
	return s:cur_kb()
endfunction
