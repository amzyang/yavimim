" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

let s:cache_dir = g:yavimim_user_dir . "/cache/"
let s:cache_version = 1

let s:FILE_NONEXIST = 1
let s:FILE_INVALIDATE_CACHE = 2
let s:FILE_OK = 3
let s:FILE_AND_CACHE = 0

function! yavimim#cache#cache_name(filename)
	if &enc != 'utf-8'
		return printf("%s.cache.%s", a:filename, &enc)
	else
		return printf("%s.cache", a:filename)
	endif
endfunction

function! yavimim#cache#validation(filename, origin)
	let cache = yavimim#cache#cache_name(a:filename)
	let cache_path = findfile(cache, expand(s:cache_dir))
	if empty(cache_path) || !filereadable(cache_path)
		return 0
	endif
	" compare timestamp
	let origin_ftime = getftime(a:origin)
	let cache_ftime = getftime(cache_path)
	if cache_ftime < origin_ftime
		return 0
	endif

	" compare cache version
	let [l:version] = readfile(cache_path, '', 1)
	if l:version != s:cache_version
		return 0
	endif
	return 1
endfunction

function! yavimim#cache#validation_user()
	let origin_path = findfile('user.txt', expand(g:yavimim_user_dir))
	return yavimim#cache#validation('user.txt', origin_path)
endfunction

function! yavimim#cache#user_create(mb)
	let path = expand(s:cache_dir.yavimim#cache#cache_name("user.txt"))
	if !isdirectory(expand(s:cache_dir))
		call mkdir(expand(s:cache_dir))
	endif
	let lines = copy(a:mb.lines)
	call insert(lines, a:mb.maxlength)
	call insert(lines, a:mb.version)
	call writefile(lines, path)
endfunction

" 用户码表格式
" 第一行：缓存版本相关信息
" 第二行：最长的词语，用于自动上档相关信息
" 接下来就是正式的数据段
function! yavimim#cache#user_load()
	let cache = yavimim#cache#cache_name('user.txt')
	let cache_path = findfile(cache, expand(s:cache_dir))
	let lines = readfile(cache_path)
	let maxlength = lines[1]
	call remove(lines, 0, 1)
	return [lines, maxlength]
endfunction

" @TODO: it doesn't belong here.
let g:yavimim_enable_cache = 1
" return mb
function! yavimim#cache#get_user()
	" @TODO: sort, remove duplicate items
	" check file exists
	let filename = "user.txt"
	let path = findfile(filename, expand(g:yavimim_user_dir))
	if empty(path) || !filereadable(path)
		return []
	endif
	if g:yavimim_enable_cache
		" 初步检测
		let validated = yavimim#cache#validation_user()
		if validated
			return yavimim#cache#user_load()
		endif
	endif
	let lines = readfile(path)
	let length = 0
	let pattern = '\s+'
	let result = []
	for line in lines
		if line =~ '^[;#]' || line =~ '^\s+$'
			continue
		endif
		call add(result, yavimim#util#encoding(line))
		let idx = max([stridx(line, ' '), stridx(line, '\t')])
		let length = length < idx ? idx : length
	endfor
	let mb={'lines':result, 'version':s:cache_version, 'maxlength': length}
	call yavimim#cache#user_create(mb)
	return [result, length]
endfunction

function! yavimim#cache#clear(filename)
	call unlink(yavimim#cache#cache_name(a:filename))
endfunction
