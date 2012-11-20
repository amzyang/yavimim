" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
let s:vk = {}
let s:keyboard = "`1234567890-=qwertyuiop[]asdfghjkl;'\\zxcvbnm,./"
let s:keyboard_shift = '~!@#$%^&*()_+QWERTYUIOP{}ASDFGHJKL:"|ZXCVBNM<>?'
let s:vk_idx = 0
let s:sections = []
let g:yavimim_vkbl = 'pc103'
let s:vkbl = {'pc103': [
			\ ['`1234567890-=', 'qwertyuiop[]\', 'asdfghjkl;''', 'zxcvbnm,./'],
			\ ['~!@#$%^&*()_+', 'QWERTYUIOP{}|', 'ASDFGHJKL:"', 'ZXCVBNM<>?']
		\ ],
		\ 'pc103_big_enter': [
			\ ['`1234567890-=\', 'qwertyuiop[]', 'asdfghjkl;''', 'zxcvbnm,./'],
			\ ['~!@#$%^&*()_+|', 'QWERTYUIOP{}', 'ASDFGHJKL:"', 'ZXCVBNM<>?']
		\ ],
		\ 'hhkb': [
			\ ['1234567890-=\`', 'qwertyuiop[]', 'asdfghjkl;''', 'zxcvbnm,./'],
			\ ['!@#$%^&*()_+|~', 'QWERTYUIOP{}', 'ASDFGHJKL:"', 'ZXCVBNM<>?']
		\ ]}
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
			call add(s:sections, section)
			continue
		endif

		let key = line[0:0]
		let val = get(split(line[2:]), 0, '')
		let val_shift = get(split(line[2:]), 1, '')
		let idx = stridx(s:keyboard, key)
		let key_shift = s:keyboard_shift[idx]
		if !has_key(s:vk, section)
			let s:vk[section] = {}
		endif
		let s:vk[section][key] = val
		let s:vk[section][key_shift] = val_shift
	endfor
endfunction

call s:init()

function! s:display_vkb(kb)
	" @TODO support hhkb/pc103/big enter/laptop
	let [lefttop, leftbottom, righttop, rightbottom]    = ['┌', '└', '┐', '┘']
	let [horzup, horzdown, vertleft, vertright]         = ['┴', '┬', '┤', '├']
	let [vertbar, horzbar]                              = ['│', '─']
	let scroll                                          = '┼'

	let topcover = lefttop . repeat(horzbar, 5) . righttop
	let bottomcover = leftbottom . repeat(horzbar, 5) . rightbottom
	let seperator = ' '

	let outeridx = 0
	let [layout_keys, layout_keys_shift] = s:vkbl[g:yavimim_vkbl]
	let max_len = s:max_row_length(layout_keys)
	echohl Comment | echo ">>" | echohl None
	echon s:keys
	while outeridx < len(layout_keys)
		let keys = layout_keys[outeridx]
		let offset = repeat(' ', (max_len - len(keys)) * 4)
		let start = repeat(topcover . seperator, strlen(keys))
		echohl Comment | echon "\n".offset.start | echohl None
		let keys_shift = layout_keys_shift[outeridx]

		let idx = 0
		echon "\n".offset
		while idx < len(keys)
			let shift = has_key(a:kb, keys_shift[idx]) ?
						\ a:kb[keys_shift[idx]] : ''
			let origin = has_key(a:kb, keys[idx]) ? a:kb[keys[idx]] : ''
			echohl Comment | echon vertbar | echohl None
			let spaces = repeat(' ', 5 - strdisplaywidth(origin.shift))
			echohl Normal
			echon printf("%-s%s%s", origin, spaces, shift) | echohl None
			echohl Comment | echon vertbar.seperator | echohl None
			let idx +=1
		endwhile
		let idx = 0
		echon "\n".offset
		while idx < len(keys)
			let shift = has_key(a:kb, keys_shift[idx]) ?
						\ a:kb[keys_shift[idx]] : ''
			let origin = has_key(a:kb, keys[idx]) ? a:kb[keys[idx]] : ''
			echohl Comment | echon vertbar | echohl None
			if empty(shift) && empty(origin)
				echohl Comment | echon printf("  %s  ", keys[idx]) | echohl None
			else
				echohl Keyword | echon printf("  %s  ", keys[idx]) | echohl None
			endif
			echohl Comment | echon vertbar.seperator | echohl None
			let idx +=1
		endwhile
		let end = repeat(bottomcover . seperator, strlen(keys))
		echohl Comment | echon "\n".offset.end | echohl None
		let outeridx += 1
	endwhile
	let title = (s:vk_idx + 1) . "-" . s:sections[s:vk_idx]
	let title_offset = repeat(' ', (max_len * 8 - strlen(title)) / 2)
	echohl Title | echon "\n".title_offset.title | echohl None
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
		elseif stridx(s:keyboard, char) >= 0 ||
					\ stridx(s:keyboard_shift, char) >= 0
			let val = get(kb, char, '')
			let s:keys .= val
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
		elseif nr == 14
			let kb = s:iter_vkb(1)
			call s:display_vkb(kb)
		" Ctrl-P
		elseif nr == 16
			let kb = s:iter_vkb(-1)
			call s:display_vkb(kb)
		elseif nr == "\<C-l>"
			call s:display_vkb(kb)
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