" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
" ==============================================================================
" initialization
" ==============================================================================
let s:map_args= "<silent> <buffer> <unique>"

function! yavimim#insert#toggle(...)
	call s:plugin_compatible()
	if !&l:modifiable | return '' | endif
	if !exists('b:yavimim') | call s:init_buffer() | endif
	call s:toggle_options()
	if exists('b:yavimim.highlight_id')
		call matchdelete(b:yavimim.highlight_id)
		unlet b:yavimim.highlight_id
	endif
	call s:set_cursor_position()
	if &l:iminsert != 1
		call s:mappings()
	else
		lmapclear <buffer>
		lmapclear
	endif
	return nr2char(yavimim#util#keycode('langmap'))
endfunction

function! s:plugin_compatible()
	try
		silent NeoComplCacheToggle
	catch /.*/
	endtry
endfunction

function! s:set_cursor_position()
	let b:yavimim.cursor = {'line': line('.'), 'column': col('.') - 1}
endfunction

function! s:yavimim_cursor_movedi()
	if &l:iminsert != 1
		return
	endif

	if !b:yavimim.state
		call s:set_cursor_position()
	endif
endfunction

function! s:yavimim_start_insert()
	call s:reset_start_insert()
	let b:yavimim.tmp = &l:iminsert
	let &l:iminsert = b:yavimim.iminsert_saved
	let b:yavimim.iminsert_saved = b:yavimim.tmp
	if &l:iminsert == 1
		call s:mappings()
	endif
endfunction

function! s:reset_start_insert()
	let b:yavimim.match_lists = []
	let b:yavimim.state = 0
	call s:set_cursor_position()
endfunction

fun! s:session_start_running()
	let b:yavimim.state = 1
endf
fun! s:session_end()
	let b:yavimim.state = 0
endf

function! s:init_buffer()
	let b:yavimim = {}
	let b:yavimim.match_lists = []
	let b:yavimim.state = 0
	let b:yavimim.pmenu = 0
	let b:yavimim.base = ''
	let b:yavimim.page_nr = 1
	autocmd YaVimIM CursorMovedI <buffer> call s:yavimim_cursor_movedi()
	autocmd YaVimIM InsertEnter <buffer> call s:yavimim_start_insert()
	autocmd YaVimIM InsertLeave <buffer>
				\ call g:do_after_cancel()
				\ | let b:yavimim.tmp = &l:iminsert
				\ | let &l:iminsert = b:yavimim.iminsert_saved
				\ | let b:yavimim.iminsert_saved = b:yavimim.tmp
	autocmd YaVimIM BufWinEnter <buffer>
				\ if !exists('b:vimim') && &l:modifiable
				\ | let &l:iminsert = 0
				\ | endif
endfunction

function! s:toggle_options()
	if &l:iminsert == 1
		let &l:omnifunc = b:yavimim.omnifunc_saved
		let &completeopt = b:yavimim.completeopt_saved
		let &pumheight = b:yavimim.pumheight_saved
	else
		let b:yavimim.omnifunc_saved = &l:omnifunc
		let b:yavimim.completeopt_saved = &completeopt
		let b:yavimim.pumheight_saved = &pumheight
		let b:yavimim.iminsert_saved = &l:iminsert
		let &l:omnifunc='g:yavimim_omnifunc'
		let &completeopt='menuone'
		let &pumheight = 10
	endif
endfunction

function! g:change_cursor_pmenu_position(change)
	if pumvisible() && b:yavimim.state == 1
		let b:yavimim.pmenu += a:change
	endif
	return ''
endfunction

function! g:do_after_commit()
	let b:yavimim.state = 0
	let b:yavimim.match_lists = []
	let b:yavimim.pmenu = 0
	call s:set_cursor_position()
	call yavimim#highlight#predict()
	return ''
endfunction

function! g:do_waiting_commit()
	" 开始中文输入中
	let b:yavimim.state = 1
	call yavimim#highlight#predict()
	return ''
endfunction

function! g:do_after_cancel()
	let b:yavimim.state = 0
	let b:yavimim.match_lists = []
	call s:set_cursor_position()
	call yavimim#highlight#predict()
	return ''
endfunction

function! g:set_after_insert_beside_chinese()
	" 输入的不是中文汉字
	let b:yavimim.state = 0
	call s:set_cursor_position()
	call yavimim#highlight#predict()
	return ''
endfunction

function! g:do_trigger_completion()
	if pumvisible() && len(b:yavimim.match_lists) == 1
		silent execute printf('return "%s"',
					\ '\<C-Y>\<C-R>=g:do_after_commit()\<CR>')
	endif
	if pumvisible()
		silent execute printf('return "%s"', '\<C-P>')
	endif
	return ''
endfunction
" ==============================================================================
" key mappings
" ==============================================================================
function! s:mappings()
	" binding all keys
	lmapclear
	lmapclear <buffer>
	silent execute "lnoremap" s:map_args "<CR>" "<C-R>=yavimim#insert#enter()<CR>"
	silent execute "lnoremap" s:map_args "<Space>" "<C-R>=yavimim#insert#space()<CR>"
	silent execute "lnoremap" s:map_args "<BS>" "<C-R>=yavimim#insert#backspace()<CR>"
	silent execute "lnoremap" s:map_args "<C-H>" "<C-R>=yavimim#insert#backspace()<CR>"
	" 只在补全可见时禁用，其它时候可用
	silent execute "lnoremap" s:map_args "<Home> <Nop>"
	silent execute "lnoremap" s:map_args "<End> <Nop>"
	silent execute "lnoremap" s:map_args "<C-E>" "<C-R>=yavimim#insert#ctrl_e()<CR>"
	silent execute "lnoremap" s:map_args "<Up>"
				\ "<C-R>=g:change_cursor_pmenu_position(-1)<CR><Up>"
	silent execute "lnoremap" s:map_args "<Down>"
				\ "<C-R>=g:change_cursor_pmenu_position(1)<CR><Down>"
	silent execute "lnoremap <expr>" s:map_args "-"
				\ "pumvisible() ? yavimim#insert#page(-1) . '<C-E><C-X><C-O><C-P>' : '-'"
	silent execute "lnoremap <expr>" s:map_args "<PageUp>"
				\ "pumvisible() ? yavimim#insert#page(-1) . '<C-E><C-X><C-O><C-P>' : '<PageUp>'"
	silent execute "lnoremap <expr>" s:map_args "="
				\ "pumvisible() ? yavimim#insert#page(1) . '<C-E><C-X><C-O><C-P>' : '='"
	silent execute "lnoremap <expr>" s:map_args "<PageDown>"
				\ "pumvisible() ? yavimim#insert#page(1) . '<C-E><C-X><C-O><C-P>' : '<PageDown>'"
	" silent execute "lnoremap" s:map_args "<C-U>"
				" \ "<C-R>=g:do_after_cancel()<CR><C-U>"
	call s:lmap_punctuations()
	call s:lmap_numbers()
	call s:lmap_letters()
endfunction

function! s:lmap_punctuations()
	let index = 0
	let origins = yavimim#punctuation#origin()
	let trans = yavimim#punctuation#trans()
	while index < len(origins)
		let origin = origins[index]
		let tran = trans[index]
		silent execute "lnoremap" s:map_args origin
					\ "<C-R>=yavimim#insert#punctuation(".index.")<CR>"
		let index += 1
	endwhile

	" single/double/square quote
	let quotes = {'single': "'", 'double': '"', 'square': ']'}
	for [type, quote] in items(quotes)
		silent execute printf("lnoremap %s %s %s",
					\ s:map_args,
					\ quote,
					\ printf("<C-R>=yavimim#insert#quote('%s')<CR>", type))
	endfor
endfunction

function! s:lmap_numbers()
	for l:number in range(10)
		silent execute "lnoremap" s:map_args l:number
					\ "<C-R>=yavimim#insert#number(".l:number.")<CR>"
	endfor
endfunction

function! s:lmap_letters()
	for nr in range(char2nr('a'), char2nr('z'))
		let char = nr2char(nr)
		silent execute
					\ printf("lnoremap %s %s %s",
					\ s:map_args,
					\ char,
					\ printf("<C-R>=yavimim#insert#letter('%s')<CR>", char))
	endfor
endfunction

function! yavimim#insert#punctuation(index)
	let tran = yavimim#punctuation#trans()[a:index]
	if pumvisible()
		let key = '\<C-N>\<C-Y>\<C-R>=g:do_after_commit()\<CR>'
		let key .= tran
	else
		let key = tran
	endif
	silent execute printf('return "%s"', key)
endfunction

function! yavimim#insert#quote(type)
	let tran = yavimim#punctuation#quote(a:type)
	if pumvisible()
		let key = '\<C-N>\<C-Y>\<C-R>=g:do_after_commit()\<CR>'
		let key .= tran
	else
		let key = tran
	endif
	silent execute printf('return "%s"', key)
endfunction

function! yavimim#insert#backspace()
	let key = '\<BackSpace>'
	let step = (col('.') - 1 - b:yavimim.cursor.column)
	" 因为此时还没开始做退格操作，在删之后是4个就要做自动补全，所以在删之前是5个
	if step <= 5
		let key .= '\<C-X>\<C-O>\<C-R>=g:do_trigger_completion()\<CR>'
	endif
	silent execute printf('return "%s"', key)
endfunction

function! yavimim#insert#ctrl_e()
	if b:yavimim.state == 1
		let key = '\<C-R>=g:do_after_cancel()\<CR>'
		if pumvisible()
			let key .= '\<C-E>'
		endif
		let step = col('.') - 1 - b:yavimim.cursor.column
		let key .= repeat('\<BS>', step)
	else
		let key = '\<C-E>'
	endif
	silent execute printf('return "%s"', key)
endfunction

function! yavimim#insert#enter()
	if pumvisible()
		let key = '\<C-Y>'
	elseif b:yavimim.state == 1
		let key = ''
	else
		let key = '\<CR>'
	endif
	let key .= '\<C-R>=g:do_after_cancel()\<CR>'
	silent execute printf('return "%s"', key)
endf

function! yavimim#insert#number(number)
	let l:number = a:number
	if l:number == 0 && b:yavimim.state == 1
		let l:number = 10
	endif
	if b:yavimim.state == 1
		let l:key = repeat('\<Down>', l:number) . '\<C-Y>'
		silent execute printf('return "%s%s"', l:key,
					\ '\<C-R>=g:do_after_commit()\<CR>')
	else
		return l:number
	endif
endfunction

function! yavimim#insert#letter(char)
	let im = yavimim#getim()
	return s:lmap_letter_{im.type}(a:char)
endfunction

function! s:lmap_letter_wubi(char)
	" 五笔
	" 检测我们是否已经输入四个可用字母，此时就可以上档了
	let b:yavimim.page_nr = 1
	call s:fix_cursor_position()
	let l:len = col('.') - b:yavimim.cursor.column - 1
	let key = ''
	if pumvisible() && (l:len == 4 || len(b:yavimim.match_lists) == 1)
		let key = '\<C-N>\<C-Y>\<C-R>=g:do_after_commit()\<CR>'
	endif
	let key .= a:char . '\<C-R>=g:do_waiting_commit()\<CR>' .
				\ '\<C-X>\<C-O>\<C-R>=g:do_trigger_completion()\<CR>'
	silent execute printf('return "%s"', key)
endfunction

function! yavimim#insert#space()
	if pumvisible()
		" 检查 popup menu 是否高亮被选中
		" :help popupmenu-completion
		let now = getline(b:yavimim.cursor.line)
					\[b:yavimim.cursor.column:col('.') - 2]
		let key = ''
		if now == b:yavimim.base && b:yavimim.pmenu == 0
			let key .= '\<C-N>'
		endif
		let key .= '\<C-Y>\<C-R>=g:do_after_commit()\<CR>'
	else
		let key = '\<Space>\<C-R>=g:set_after_insert_beside_chinese()\<CR>'
	endif
	silent execute printf('return "%s"', key)
endfunction
" ==============================================================================
" completion
" ==============================================================================
function! s:fix_cursor_position()
	let line = getline('.')
	let line_nr = line('.')
	let start = col('.') - 1
	if line_nr != b:yavimim.cursor.line
		call s:set_cursor_position()
		" dirty hack
		" 针对 textwidth 不为0自动换行所做的hack
		if b:yavimim.state == 1
			let b:yavimim.cursor.column = 0
			call s:fix_cursor_position()
		endif
		return
	endif

	while start > 0 && start > b:yavimim.cursor.column
				\ && line[start - 1] =~ '\l'
		let start -= 1
	endwhile
	let b:yavimim.cursor.column = start
endfunction

function! g:yavimim_omnifunc(findstart, base)
	" omnifunc
	if a:findstart
		call s:fix_cursor_position()
		let base = getline(b:yavimim.cursor.line)
					\[b:yavimim.cursor.column:col('.') - 2]
		let b:yavimim.base = base
		let b:yavimim.match_lists =
					\ yavimim#backend#get_match_lists(yavimim#getim(), base)
		if !len(b:yavimim.match_lists)
			return -3
		endif
		return b:yavimim.cursor.column
	else
		let l:matches = []
		let l:index = 1
		let match_length = len(b:yavimim.match_lists)
		let total_nr = float2nr(ceil(match_length / yavimim#util#nr2float(&pumheight)))
		if b:yavimim.page_nr < 1
			let b:yavimim.page_nr = total_nr
		elseif b:yavimim.page_nr > total_nr
			let b:yavimim.page_nr = 1
		endif
		let one = (b:yavimim.page_nr - 1) * &pumheight
		let two = one + &pumheight - 1
		let final_list = b:yavimim.match_lists[one : two]
		let max_length = yavimim#util#maxlength(final_list)
		for l:match in final_list
			let [l:word, l:menu] = yavimim#backend#wubi_qq_spliter(l:match)
			let l:abbr = printf("%d %s", l:index % 10, printf(printf("%%-%ds", max_length), l:match))
			call add(l:matches, {'word': l:word, 'abbr': l:abbr})
			let l:index += 1
		endfor
		if total_nr != 1
			let l:matches[0].kind = printf("%d/%d", b:yavimim.page_nr, total_nr)
		endif
		return {'words': l:matches}
	endif
endfunction

function! yavimim#insert#page(incre)
	let b:yavimim.page_nr += a:incre
	return ''
endfunction
" ==============================================================================
" utils
" ==============================================================================
function! s:debug(...)
	call yavimim#util#debugprint(a:000)
endfunction

function! yavimim#insert#debug(...)
	" put here that you can look into script internally variables
	let l:list = []
	for l:var in a:000
		call add(l:list, l:var)
		if type(l:var) == type("")
			try
				silent execute printf("let %s=%s", "l:inspect_var", l:var)
				call add(l:list, l:inspect_var)
				unlet l:inspect_var
			catch /.*/ " @TODO: tips, much more user friendly, don't be so rude.
			endtry
		else
			call add(l:list, l:var)
		endif
		unlet l:var
	endfor
	call yavimim#util#debugprint(l:list)
endfunction
