" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

let s:yavimim = {}
let s:yavimim.metadatas = {'wubi': {'full': '五笔', 'short': '五'},
			\ 'pinyin': {'full': '拼音', 'short': '拼'}}

function! s:wbqq_spliter(string)
	" '你好vb' => ['你好', 'vb']
	let l:first = ''
	let l:second = ''
	let l:start = -1
	let l:index = 0
	while l:index < len(a:string)
		let l:char = a:string[l:index]
		if l:char =~ '[a-z]'
			let l:second .= l:char
		else
			let l:first .= l:char
		endif
		let l:index += 1
	endwhile
	return [l:first, l:second]
endfunction

function! yavimim#backend#get_match_lists(key)
	let im = s:yavimim.im
	if im.type == 'wubi'
		if im.id == 'qq'
			let lines = s:getlines(im)
			let l:index = s:find_sorted_idx(lines, a:key)
			if l:index == -1
				return []
			else
				let l:line = s:encoding(lines[l:index])
				let l:parts = split(l:line, '\s\+')
				call remove(l:parts, 0)
				call map(l:parts, "s:wbqq_spliter(v:val)")
				return l:parts
			endif
		else
			return s:get_match_lists_wbpy(a:key)
		endif
	elseif im.type == 'pinyin'
	else
	endif
endfunction

function! s:get_match_lists_wbpy(key)
	let lines = s:getlines(s:yavimim.im)
	" @TODO
	let sep = s:find_sorted_match(lines, a:key)
	if sep == -1
		return []
	endif
	let pattern = '^@\='.a:key
	let matches = []
	let backward = sep
	while backward >= 0 && lines[backward] =~ pattern
		let pair = split(lines[backward])
		if len(pair) != 2
			continue
		endif
		let [first, second] = reverse(pair)
		let offset = second[0] == '@' ? 1 : 0
		let second = second[(len(a:key) + offset) :]
		call add(matches, [first, second])
		let backward -= 1
	endwhile
	call reverse(matches)
	let forward = sep + 1
	while forward < len(lines) && lines[forward] =~ pattern
		let pair = split(lines[forward])
		if len(pair) != 2
			continue
		endif
		let [first, second] = reverse(pair)
		let offset = second[0] == '@' ? 1 : 0
		let second = second[(len(a:key)+offset) :]
		call add(matches, [first, second])
		let forward += 1
	endwhile
	return matches
endfunction

function! yavimim#backend#title()
endfunction

function! s:getlines(im)
	let cht = ''
	if exists('g:yavimim_traditional') && g:yavimim_traditional
		let cht = '_cht'
	endif
	if !has_key(a:im, 'lines'.cht) && a:im.type != 'cloud'
		" @TODO: can we access l:path?
		let l:path = a:im['path'.cht]
		let lines = readfile(l:path)
		if a:im.id != 'qq'
			while lines[0] != '[Data]'
				" @TODO
				call remove(lines, 0)
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
		let a:line = iconv(a:line, 'utf-8', &enc)
		" 移除编码转换失败词组
		let pattern = '?\+\l*'
		let a:line = substitute(a:line, pattern, '', 'g')
		return a:line
	catch /.*/
		echoerr "Maybe iconv feature is missing.
					\ See http://www.vim.org/download.php for more details."
		return ''
	endtry
endfunction

function! s:find_sorted_idx(list, key)
	" a:list: ['a', 'aa', 'ab', ...]
	" a:key:   'def'
	let low = 0
	let high = len(a:list)
	let mid = (low + high) / 2
	let l:key = get(split(a:list[mid], '\s\+'), 0, '')

	while low <= high && l:key != a:key
		if l:key < a:key
			let low = mid + 1
		elseif l:key > a:key
			let high = mid - 1
		endif
		let mid = (low + high) / 2
		if mid >= len(a:list)
			break
		endif
		let l:key = get(split(a:list[mid], '\s\+'), 0, '')
	endwhile

	if l:key == a:key
		return mid
	endif
	return -1
endfunction

function! s:find_sorted_match(list, key)
	" a:list: ['a 工', 'a 戈', '@a 啊', ...]
	" a:key:   'def'
	let low = 0
	let high = len(a:list)
	let mid = (low + high) / 2
	let pattern = '^@\=' . a:key
	let line = a:list[mid]

	while low <= high && line !~ pattern
		let start = line[0] == '@' ? 1 : 0
		let cmp = line[start : len(a:key)]
		if cmp < a:key
			let low = mid + 1
		elseif cmp > a:key
			let high = mid - 1
		endif
		let mid = (low + high) / 2
		let line = a:list[mid]
		if mid >= len(a:list)
			break
		endif
	endwhile

	if line =~ a:key
		return mid
	endif
	return -1
endfunction

function! yavimim#backend#setup_backend()
	let s:yavimim.backends = {
				\ 'wbqq': {'id': 'qq',
					\ 'type': 'wubi',
					\ 'name': 'QQ云五笔'},
				\ 'wbpy': {'id':'wbpy',
				\ 'type': 'wubi',
				\ 'name': '五笔拼音'}
				\ }
	for [key, im] in items(s:yavimim.backends)
		let paths = s:getpaths(im)
		if join(paths, '') == ''
			call remove(s:yavimim.backends, key)
		else
			let im.path = paths[0]
			let im.path_cht = paths[1]
		endif
	endfor
	let user_ims = keys(s:yavimim.backends)
	if exists('g:yavimim_imlist')
		let ims = split(g:yavimim_imlist, ',')
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
	let s:yavimim.im = s:yavimim.backends[user_ims[0]]
endfunction

function! s:getpaths(im)
	let paths = []
	for cht in ['', '_cht']
		let relative = printf('autoload/yavimim/%s/%s%s.txt',
					\ a:im.type, a:im.id, cht)
		let path = split(globpath(&rtp, relative), '\n')
		if len(path) > 0
			if len(path) > 1
				silent call yavimim#util#show_message()
			endif
			call add(paths, path[0])
		else
			call add(paths, '')
		endif
	endfor
	return paths
endfunction

" 简繁转换
function! s:s2t(chars)
	if !exists('s:s2t_lines') || empty(s:s2t_lines)
		let path = sptit(globpath(&rtp, 'autoload/yavimim/data/gbks2t.tab'), '\n')
		if len(path) == 0
			call yavimim#util#show_message("简繁转换数据库不存在，无法使用该功能！")
			return
		endif
		let s:s2t_lines = readfile(path[0])
	endif
	for line in s:s2t_lines
		let pattern = '^'.a:chars
		if line =~ pattern
			return strpart(line, byteidx(line, 1))
	endfor
endfunction

function! yavimim#backend#getim()
	" @TODO deepcopy/copy
	return s:yavimim.im
endfunction
