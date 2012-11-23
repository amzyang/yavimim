" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

let s:yavimim = {}
let s:yavimim.metadatas = {'wubi': {'full': '五笔', 'short': '五'},
			\ 'pinyin': {'full': '拼音', 'short': '拼'}}
let g:_yavimim_only = 0
let g:_yavimim_pinyin_in_matches = 0

function! s:wbqq_spliter(string)
	" '你好vb' => ['你好', 'vb']
	let pattern = '\l*$'
	let l:first = substitute(a:string, pattern, '', '')
	let idx = match(a:string, pattern)
	let l:second = a:string[idx : ]
	return [l:first, l:second]
endfunction

function! yavimim#backend#has(key)
	let im = yavimim#backend#getim()
	let lines = s:getlines(im)
	if im.type == 'wubi'
		if im.id == 'qq'
			let func = 's:cmp'
		else
			let func = 's:cmp_wbpy'
		endif
			let index = s:sorted_idx(lines, a:key, 0, len(lines) - 1, func)
	elseif im.type == 'pinyin'
	else
	endif

	" check user
	let func = 's:cmp_wbpy'
	let user_lines = s:get_user_lines()
	let user_index = s:sorted_idx(user_lines, a:key,
				\ 0, len(user_lines) - 1, func)
	return index >= 0 || user_index >= 0
endfunction

function! yavimim#backend#matches(key)
	let im = yavimim#backend#getim()
	let lines = s:getlines(im)
	let has_user_db = s:enabled_user()
	let range_hub = []
	let matches_hub = []
	let lines_hub = []
	let lines_range_hub = []
	let user_lines = s:get_user_lines()
	let user_range = s:sorted_matches_range(user_lines, a:key, 's:cmp_wbpy')
	call add(range_hub, user_range)
	call add(lines_hub, user_lines)
	call add(lines_range_hub, [user_lines, user_range])
	let words = []
	let g:_yavimim_pinyin_in_matches = 0
	if im.type == 'wubi'
		if im.id == 'qq'
			let index = s:sorted_idx(lines, a:key, 0,
						\ len(lines) - 1, 's:cmp')
			if index == -1 && user_range == [-1, -1]
				return []
			endif
			if index == -1
				let parts = []
				let range = [-1, -1]
			else
				let line = s:encoding(lines[index])
				let parts = split(line, '\s\+')
				call remove(parts, 0)
				let range = [0, len(parts) - 1]
			endif
			call add(lines_range_hub, [parts, range])
			call add(range_hub, range)
			call add(lines_hub, parts)
			let [user_matches, matches] = s:matches(lines_range_hub)
			let g:_yavimim_only = len(user_matches) + len(matches) == 1 ? 1 : 0
			let words = s:format_user(user_matches, a:key)
			for match in matches
				let [word, tip] = s:wbqq_spliter(match)
				call add(words, {'word': word, 'tip': tip, 'kind': ''})
			endfor
		else
			let range = s:sorted_matches_range(lines, a:key, 's:cmp_wbpy')
			if range == [-1, -1] && user_range == [-1, -1]
				return []
			endif
			call add(lines_range_hub, [lines, range])
			call add(range_hub, range)
			call add(lines_hub, lines)
			let [user_matches, matches] = s:matches(lines_range_hub)
			let g:_yavimim_only = len(user_matches) + len(matches) == 1 ? 1 : 0
			let words = s:format_user(user_matches, a:key)
			for match in matches
				let [tip, word] = split(match)
				let word = s:encoding(word)
				if empty(word)
					continue
				endif
				if g:yavimim_traditional
					let word = s:s2t(word)
				endif
				let kind = tip[0] == '@' ? '[拼]' : ''
				let offset = tip[0] == '@' ? 1 : 0
				let g:_yavimim_pinyin_in_matches = offset ||
							\ g:_yavimim_pinyin_in_matches
				let tip = tip[(strlen(a:key) + offset) : ]
				call add(words, {'word': word, 'tip': tip, 'kind': kind})
			endfor
		endif
	else
	endif
	let total_nr = s:total_nr(s:get_len_range_hub(range_hub))

	let mode = yavimim#util#getmode()
	if mode == 'insert'
		call s:data_omni(words)
		if total_nr != 1
			let words[0].kind = printf("%d/%d%s", b:yavimim.page_nr,
						\ total_nr, words[0].kind)
		endif
		call s:data_omni_align_kind(words)
	else
		let g:_yavimim_total_nr = total_nr
	endif
	return words
endfunction

function! yavimim#backend#cmdline_total_nr()
	return s:cmdline_total_nr
endfunction

function! s:data_omni(list)
	let label = 1
	for item in a:list
		if (v:version == 703 && has('patch713')) || v:version > 703
			let item.abbr = printf("%d.%-11S", label % 10, item.word.item.tip)
		else
			let item.abbr = printf("%d.%-12s", label % 10, item.word.item.tip)
		endif
		let item.dup = 1
		let label += 1
	endfor
endfunction

function! s:data_omni_align_kind(list)
	let max_length = 7
	for item in a:list
		let max_length = max_length < strlen(item.kind) ?
					\ strlen(item.kind) : max_length
	endfor
	for item in a:list
		let item.kind = printf(printf("%%%ds", max_length), item.kind)
	endfor
endfunction

function! s:matches(...)
	"s:matches([[list1, range1], [list2, range2], [list3, range3][,...]])
	if a:0 == 0
		return []
	endif
	" get total item count
	let total_cnt = 0
	for data in a:1
		let range = data[1]
		if range == [-1, -1]
			continue
		endif
		let total_cnt += range[1] - range[0] + 1
	endfor
	let total_nr = s:total_nr(total_cnt)
	let mode = yavimim#util#getmode()
	let page_nr = mode == 'insert' ? b:yavimim.page_nr : g:_yavimim_page_nr
	let num = mode == 'insert' ? &pumheight : g:yavimim_candidate
	if page_nr < 1
		let page_nr = total_nr
	elseif page_nr > total_nr
		let page_nr = 1
	endif
	if mode == 'insert'
		let b:yavimim.page_nr = page_nr
	else
		let g:_yavimim_page_nr = page_nr
	endif
	let result = [] " [matches1, matches2[,...]]
	let left = num
	let offset = 0
	for data in a:1
		let [list, range] = data
		if range == [-1, -1]
			call add(result, [])
			continue
		endif
		
		let length = range[1] - range[0] + 1
		if page_nr * num <= offset || ((page_nr - 1) * num > offset + length)
			call add(result, [])
			let offset += length
			continue
		endif
		
		let start = (page_nr - 1) * num - offset < 0 ?
					\ 0 : (page_nr - 1) * num - offset
		let one = range[0] + start
		let process_cnt = offset - ((page_nr - 1) * num)
		let left = process_cnt > 0 ? num - process_cnt : num
		let two = one + left - 1
		let two = two > range[1] ? range[1] : two
		let offset += length
		call add(result, list[one : two])
	endfor
	return result
endfunction

function! s:get_len_range_hub(hub)
	let total = 0
	for range in a:hub
		if range == [-1, -1]
			continue
		endif
		let total += range[1] - range[0] + 1
	endfor
	return total
endfunction

function! s:total_nr(length)
	let mode = yavimim#util#getmode()
	let num = mode == 'insert' ? &pumheight : g:yavimim_candidate
	return float2nr(ceil(a:length / yavimim#util#nr2float(num)))
endfunction

function! s:getlines(im)
	let cht = ''
	if g:yavimim_traditional && a:im.id == 'qq' &&
				\ has_key(a:im.path_store, 'zh_cht')
		let cht = '_cht'
	endif
	if !has_key(a:im, 'lines'.cht) && a:im.type != 'cloud'
		" @TODO: can we access l:path?
		let l:path = a:im.path_store['zh'.cht]
		let lines = readfile(l:path)
		let first_line = lines[0]
		let pattern = '^;fcitx Version 0x03 Table file$' " fcitx 词库
		if first_line =~ pattern
			while lines[0] != '[Data]'
				let line = remove(lines, 0)
				if line =~ '='
					let [option, value] = split(line, '=')
					let a:im[option] = value
				endif
			endwhile
			call remove(lines, 0)
		endif
		let a:im['lines'.cht] = lines
	endif
	return a:im['lines'.cht]
endfunction

function! s:encoding(line)
	if &enc == 'utf-8'
		return a:line
	endif
	try
		let line = iconv(a:line, 'utf-8', &enc)
		" 移除编码转换失败词组
		let pattern = '\S*?\+\l*'
		let line = substitute(line, pattern, '', 'g')
		let pattern = '^@\?\l*\s*\l*\s*$'
		if line =~ pattern
			return ''
		endif
		return line
	catch /.*/
		echoerr "Maybe iconv feature is missing.
					\ See http://www.vim.org/download.php for more details."
		return ''
	endtry
endfunction

function! s:sorted_idx(list, key, low, high, func)
	if a:high >= len(a:list) || a:low > a:high
		return -1
	endif
	let Cmp = function(a:func)
	let low = a:low
	let high = a:high
	let mid = (low + high) / 2
	let line = a:list[mid]

	while low <= high && low >= a:low && high <= a:high &&
				\ mid >= a:low && mid <= a:high
		let ret = Cmp(line, a:key)
		if ret == 0
			return mid
		elseif ret == -1
			let low = mid + 1
		else
			let high = mid - 1
		endif
		let mid = (low + high) / 2
		let line = a:list[mid]
	endwhile
	return -1
endfunction

function! s:cmp(line, key)
	let l:key = a:line[: stridx(a:line, ' ') - 1]
	return l:key == a:key ? 0 : l:key < a:key ? -1 : 1
endfunction

" @TODO: can this be used to all fcitx database?
function! s:cmp_wbpy(line, key)
	let offset = a:line[0] == '@' ? 1 : 0
	let l:key = a:line[offset : strlen(a:key) + offset - 1]
	return l:key == a:key ? 0 : l:key < a:key ? -1 : 1
endfunction

function! s:sorted_matches_range(list, key, func)
	let high = len(a:list) - 1
	let sep = s:sorted_idx(a:list, a:key, 0, high, a:func)
	if sep == -1
		return [-1, -1]
	endif

	let lower = s:sorted_idx(a:list, a:key, 0, sep - 1, a:func)
	if lower == -1
		let lower_saver = sep
	else
		while lower != -1
			let lower_saver = lower
			let lower = s:sorted_idx(a:list, a:key, 0, lower - 1, a:func)
		endwhile
	endif
	let greater = s:sorted_idx(a:list, a:key, sep + 1, high, a:func)
	if greater == -1
		let greater_saver = sep
	else
		while greater != -1
			let greater_saver = greater
			let greater = s:sorted_idx(a:list, a:key, greater + 1, high, a:func)
		endwhile
	endif
	return [lower_saver, greater_saver]
endfunction

function! yavimim#backend#setup_backend()
	let s:yavimim.backends = {
				\ 'wbqq': {'id': 'qq',
					\ 'type': 'wubi',
					\ 'name': 'QQ五笔'},
				\ 'wbpy': {'id':'wbpy',
				\ 'type': 'wubi',
				\ 'name': '五笔拼音'}
				\ }
	for [key, im] in items(s:yavimim.backends)
		let path_store = s:getpath(im)
		if empty(keys(path_store))
			call remove(s:yavimim.backends, key)
		else
			let im.path_store = path_store
		endif
	endfor
	let user_ims = keys(s:yavimim.backends)
	if exists('g:yavimim_imlist')
		let ims = split(g:yavimim_imlist, '\s*,\s*')
		let _ims = []
		for imkey in ims
			if index(user_ims, imkey) >= 0
				call add(_ims, imkey)
			endif
		endfor
		if !empty(_ims)
			let user_ims = _ims
		endif
	endif
	if !exists('g:yavimim_im') || index(user_ims, g:yavimim_im) == -1
		let g:yavimim_im = user_ims[0]
	endif
endfunction

function! s:getpath(im)
	let path_store = {}
	for type in ['', '_cht']
		let relative = printf('autoload/yavimim/%s/%s%s.txt',
					\ a:im.type, a:im.id, type)
		let path = split(globpath(&rtp, relative), '\n')
		if len(path) > 0
			if len(path) > 1
				silent call yavimim#util#show_message()
			endif
			let path_store['zh'.type] = path[0]
		endif
	endfor
	return path_store
endfunction

" 简繁转换
function! s:s2t(chars)
	if !exists('s:s2t_lines') || empty(s:s2t_lines)
		let path = split(globpath(&rtp, 'autoload/yavimim/data/gbks2t.tab'),
					\ '\n')
		if len(path) == 0
			let message = "简繁转换数据库不存在，无法使用该功能！"
			call yavimim#util#show_message(message)
			return chars
		endif
		let lines = readfile(path[0])
		let s:s2t_lines = {}
		let idx = 0
		let tip = "加载简繁体数据库中"
		" @TODO: take care of zero division
		let percent = len(lines) / 25
		for line in lines
			if idx % percent == 0
				 let finished = idx / percent
				 let left = 25 - finished
				 let progress = repeat('=', finished) . repeat('-', left) . '>'
				 call yavimim#util#show_message(tip.progress)
			endif
			let line = s:encoding(line)
			let s:s2t_lines[char2nr(line)] = line
			let idx += 1
		endfor
	endif
	let cht = ''
	let idx = 0
	let len = strlen(substitute(a:chars, ".", "x", "g"))
	while idx < len
		let mb_char = strpart(a:chars, byteidx(a:chars, idx),
					\ byteidx(a:chars, idx+1) - byteidx(a:chars, idx))
		if !has_key(s:s2t_lines, char2nr(mb_char))
			let cht .= mb_char
		else
			let line = s:s2t_lines[char2nr(mb_char)]
			let cht .= strpart(line, byteidx(line, 1))
		endif
		let idx += 1
	endwhile
	return cht
endfunction

function! yavimim#backend#getim()
	" @TODO deepcopy/copy
	return s:yavimim.backends[g:yavimim_im]
endfunction

function! yavimim#backend#should_auto_commit(...)
	let len = a:0 ? a:1 : 0
	let mode = yavimim#util#getmode()
	let length_checking = mode == 'insert' ? 4 : 5
	" 还有拼音候选
	if g:_yavimim_pinyin_in_matches
		return 0
	elseif len >= length_checking
		return 1
	endif
	if g:_yavimim_only && g:yavimim_auto_commit
		return 1
	endif
	return 0
endfunction

function! yavimim#backend#max_keys()
	let im = yavimim#backend#getim()
	if has_key(im, 'PinyinLength')
		return max([im.Length, im.PinyinLength]) + 1
	else
		return 4 + 1
	endif
endfunction
"===============================================================================
" 用户码表
"===============================================================================
let g:yavimim_user_dir = ''

function! s:enabled_user()
	let s:user_lines = []
	let dir = g:yavimim_user_dir
	if empty(dir)
		let dir = '~/.yavimim/'
	endif
	let path_list = split(globpath(dir, "user.txt"), '\n')
	if len(path_list) != 1
		return 0
	endif
	let path = path_list[0]
	if !filereadable(path)
		return 0
	endif
	let lines = readfile(path)
	let s:user_lines = s:pre(lines)
	return empty(s:user_lines) ? 0 : 1
endfunction

function! s:get_user_lines()
	if !exists('s:user_lines')
		call s:enabled_user()
	endif
	return s:user_lines
endfunction

function! s:format_user(list, key)
	let words = []
	for item in a:list
		let tip = item[0 : stridx(item, ' ') - 1]
		let tip = tip[strlen(a:key) : ]
		let word = item[stridx(item, ' ') + 1 : ]
		let word = s:encoding(word)
		if empty(word)
			continue
		endif
		if g:yavimim_traditional
			let word = s:s2t(word)
		endif
		let kind = '[用]'
		call add(words, {'word': word, 'tip': tip, 'kind': kind})
	endfor
	return words
endfunction

function! s:pre(list)
	" remove comments get maxlength
	let length = 0
	let pattern = '\s+'
	let lines = []
	" @TODO
	" for line in a:list
		" if line =~ '^[;#]'
			" continue
		" endif
		" call add(lines, line)
		" " let idx = stridx(line, pattern)
		" " let length = length < idx ? idx : length
		" " let first = line[: idx - 1]
		" " let length = length < strlen(first) ? strlen(first) : length
		" " let second = substitute(line[idx :], '^\s+', '', '')
	" endfor
	return a:list
endfunction
