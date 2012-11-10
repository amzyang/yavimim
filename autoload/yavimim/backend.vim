" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

let s:yavimim = {}
let s:yavimim.metadatas = {'wubi': {'full': '五笔', 'short': '五'},
			\ 'pinyin': {'full': '拼音', 'short': '拼'}}

function! yavimim#backend#wubi_qq_spliter(string)
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

function! yavimim#backend#get_match_lists(im, key)
	let lines = s:getlines(a:im)
	let l:index = s:find_sorted_idx(lines, a:key)
	if l:index == -1
		return []
	else
		let l:line = s:encoding(lines[l:index])
		let l:parts = split(l:line, '\s\+')
		call remove(l:parts, 0)
		return l:parts
	endif
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
	let l:pattern = '^' . a:key . '\s\+'

	let low = 0
	let high = len(a:list)
	let mid = (low + high) / 2
	let pattern = '^' . a:key . '\s\+'
	let l:key = remove(split(a:list[mid], '\s\+'), 0)

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
		let l:key = remove(split(a:list[mid], '\s\+'), 0)
	endwhile

	if l:key == a:key
		return mid
	endif
	return -1
endfunction

function! yavimim#backend#setup_backend()
	let s:yavimim.backends = {
				\ 'wubi_qq': {'id': 'qq',
					\ 'type': 'wubi',
					\ 'name': 'QQ云五笔'}
				\ }
	for [key, im] in items(s:yavimim.backends)
		let paths = s:getpaths(im)
		if join(paths, '') == ''
			call remove(dict, key)
		else
			let im.path = paths[0]
			let im.path_cht = paths[1]
		endif
	endfor
	let keys = keys(s:yavimim.backends)
	let s:yavimim.im = s:yavimim.backends[keys[0]]
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

function! yavimim#backend#getim()
	return s:yavimim.im
endfunction
