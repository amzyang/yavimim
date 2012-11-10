" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

let s:yavimim = {}

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
	if empty(a:im.lines) && a:im.type != 'cloud'
		" @TODO: can we access l:path?
		let l:path = a:im.path
		let l:lines = readfile(l:path)
		let a:im.lines = l:lines
	endif
	let l:index = s:find_sorted_idx(a:im.lines, a:key)
	if l:index == -1
		return []
	else
		let l:line = a:im.lines[l:index]
		try
			if &enc != 'utf-8'
				let l:line = iconv(l:line, 'utf-8', &enc)
				" 移除编码转换失败词组
				let pattern = '?\+\l*'
				let l:line = substitute(l:line, pattern, '', 'g')
			endif
		catch /.*/
			echoerr "Maybe iconv feature is missing.
						\ See http://www.vim.org/download.php for more details."
		endtry
		let l:parts = split(l:line, '\s\+')
		call remove(l:parts, 0)
		return l:parts
	endif
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
	let l:wubi_qqs = split(globpath(&rtp, 'autoload/yavimim/wubi/qq.txt'), '\n')
	if len(l:wubi_qqs) > 0
		silent call yavimim#util#show_message()
	endif
	let s:yavimim.backends = {
				\ 'wubi_qq': {'path': l:wubi_qqs[0],
					\ 'type': 'wubi',
					\ 'keys': [],
					\ 'lines':[],
					\ 'name': 'QQ云五笔'}
				\ }
	let s:yavimim.metadatas = {'wubi': {'full': '五笔', 'short': '五'},
				\ 'pinyin': {'full': '拼音', 'short': '拼'}}
	let s:yavimim.im = s:yavimim.backends.wubi_qq
endfunction

function! yavimim#backend#getim()
	return s:yavimim.im
endfunction
