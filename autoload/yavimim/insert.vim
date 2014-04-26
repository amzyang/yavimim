" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
" ==============================================================================
" initialization
" ==============================================================================
let s:map_args= "<silent> <buffer>"

function! yavimim#insert#toggle(...)
	call s:plugin_compatible()
	if !&l:modifiable | return '' | endif
	if !exists('b:yavimim') | call s:init_buffer() | endif
	call s:toggle_options()
	if exists('w:yavimim_highlight_id')
		call matchdelete(w:yavimim_highlight_id)
		unlet w:yavimim_highlight_id
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
	let b:yavimim.state = 0
	call s:set_cursor_position()
endfunction

function! s:session_start_running()
	let b:yavimim.state = 1
endfunction

function! s:session_end()
	let b:yavimim.state = 0
endfunction

function! s:init_buffer()
	let b:yavimim = {}
	let b:yavimim.state = 0
	let b:yavimim.pmenu = 0
	let b:yavimim.base = ''
	let b:yavimim.page_nr = 1
	autocmd YaVimIM CursorMovedI <buffer> call s:yavimim_cursor_movedi()
	autocmd YaVimIM InsertEnter <buffer> call s:yavimim_start_insert()
	autocmd YaVimIM InsertLeave <buffer>
				\ call g:Do_after_cancel()
				\ | let b:yavimim.tmp = &l:iminsert
				\ | let &l:iminsert = b:yavimim.iminsert_saved
				\ | let b:yavimim.iminsert_saved = b:yavimim.tmp
				\ | let &l:imsearch = 0
	autocmd YaVimIM BufWinEnter <buffer>
				\ if !exists('b:vimim') && &l:modifiable
				\ | let &l:iminsert = 0
				\ | endif
endfunction

function! s:toggle_options()
	if &l:iminsert == 1
		let &completeopt = get(b:yavimim, 'completeopt_saved', &completeopt)
		let &formatoptions = get(b:yavimim, 'formatoptions_saved', &formatoptions)
	else
		let b:yavimim.completeopt_saved = &completeopt
		let b:yavimim.formatoptions_saved = &formatoptions
		let b:yavimim.iminsert_saved = &l:iminsert
		let &completeopt='menuone'
		let &l:formatoptions.='1vw'
	endif
endfunction

function! g:Change_cursor_pmenu_position(change)
	if pumvisible() && b:yavimim.state == 1
		let b:yavimim.pmenu += a:change
	endif
	return ''
endfunction

function! g:Do_after_commit()
	let b:yavimim.state = 0
	let b:yavimim.pmenu = 0
	call s:set_cursor_position()
	call yavimim#highlight#clear()
	return ''
endfunction

function! g:Do_waiting_commit()
	" 开始中文输入中
	let b:yavimim.state = 1
	call yavimim#highlight#predict()
	return ''
endfunction

function! g:Do_after_cancel()
	let b:yavimim.state = 0
	call s:set_cursor_position()
	call yavimim#highlight#clear()
	return ''
endfunction

function! g:Set_after_insert_beside_chinese()
	" 输入的不是中文汉字
	let b:yavimim.state = 0
	call s:set_cursor_position()
	call yavimim#highlight#clear()
	return ''
endfunction

function! g:Do_trigger_completion()
	if pumvisible() && yavimim#backend#should_auto_commit()
		silent execute printf('return "%s"',
					\ '\<C-Y>\<C-R>=g:Do_after_commit()\<CR>')
	endif
	if pumvisible()
		silent execute printf('return "%s"', '\<C-P>')
	endif
	return ''
endfunction
" ==============================================================================
" key mappings
" ==============================================================================
function! g:Incre_helper(incre, extra)
	if pumvisible() && g:_yavimim_total_nr == 1
		let key = ''
		if b:yavimim.pmenu == 0
			let key = '\<C-N>'
		endif
		let key .= '\<C-Y>\<C-R>=g:Do_after_commit()\<CR>' . a:extra
	elseif pumvisible() && g:_yavimim_total_nr > 1
		let key = printf("\<C-R>=yavimim#insert#page(%d)\<CR>" .
					\ "\<C-E>" .
					\ "\<C-R>=yavimim#insert#complete()\<CR>\<C-P>", a:incre)
	else
		let key = a:extra
	endif
	silent execute printf('return "%s"', key)
endfunction
function! s:mappings()
	" binding all keys
	lmapclear
	lmapclear <buffer>
	silent execute "lnoremap" s:map_args "<CR>"
				\ "<C-R>=yavimim#insert#enter()<CR>"
	silent execute "lnoremap" s:map_args "<Space>"
				\ "<C-R>=yavimim#insert#space()<CR>"
	silent execute "lnoremap" s:map_args "<BS>"
				\ "<C-R>=yavimim#insert#backspace()<CR>"
	silent execute "lnoremap" s:map_args "<C-H>"
				\ "<C-R>=yavimim#insert#backspace()<CR>"
	" 只在补全可见时禁用，其它时候可用
	lnoremap <expr> <silent> <buffer> <Home>
				\ "<Home>".(pumvisible() ? g:Do_after_cancel() : '')
	lnoremap <expr> <silent> <buffer> <End>
				\ "<End>".(pumvisible() ? g:Do_after_cancel() : '')
	silent execute "lnoremap" s:map_args "<C-E>"
				\ "<C-R>=yavimim#insert#ctrl_e()<CR>"
	silent execute "lnoremap" s:map_args "<Up>"
				\ "<C-R>=g:Change_cursor_pmenu_position(-1)<CR><Up>"
	silent execute "lnoremap" s:map_args "<Down>"
				\ "<C-R>=g:Change_cursor_pmenu_position(1)<CR><Down>"
	silent execute "lnoremap" s:map_args "-"
				\ "<C-R>=g:Incre_helper(-1, '-')<CR>"
	silent execute "lnoremap" s:map_args "="
				\ "<C-R>=g:Incre_helper(1, '=')<CR>"
	silent execute "lnoremap" s:map_args "<PageUp>"
				\ "<C-R>=g:Incre_helper(-1, '')<CR>"
	silent execute "lnoremap" s:map_args "<PageDown>"
				\ "<C-R>=g:Incre_helper(1, '')<CR>"
	call s:lmap_punctuations()
	silent execute "lnoremap" s:map_args ";;" "<C-R>=yavimim#insert#en()<CR>"
	silent execute "lnoremap" s:map_args "]]" "<C-R>=yavimim#insert#vk()<CR>"
	call s:lmap_numbers()
	call s:lmap_letters()
	" @TODO: uppercase
	for key in ['/', '{', '}']
		silent execute "lnoremap <expr>" s:map_args key
					\ printf("yavimim#insert#special('%s')", key)
	endfor
endfunction

function! yavimim#insert#en()
	call g:Do_after_cancel()
	echohl YaVimIMComment
	call inputsave()
	let key = input('>>')
	call inputrestore()
	echohl None
	return key
endfunction

function! yavimim#insert#vk()
	if pumvisible()
		let key = '\<C-N>\<C-Y>\<C-R>=g:Do_after_commit()\<CR>'
	else
		let key = '\<C-R>=g:Do_after_cancel()\<CR>'
	endif
	let key .= "\<C-R>=yavimim#vk#vk()\<CR>"
	silent execute printf('return "%s"', key)
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
		let key = '\<C-N>\<C-Y>\<C-R>=g:Do_after_commit()\<CR>'
		let key .= tran
	else
		let key = tran
	endif
	silent execute printf('return "%s"', key)
endfunction

function! yavimim#insert#quote(type)
	let tran = yavimim#punctuation#quote(a:type)
	if pumvisible()
		let key = '\<C-N>\<C-Y>\<C-R>=g:Do_after_commit()\<CR>'
		let key .= tran
	else
		let key = tran
	endif
	silent execute printf('return "%s"', key)
endfunction

function! yavimim#insert#backspace()
	if pumvisible()
		let key = '\<C-E>\<BackSpace>'
	else
		let key = '\<BackSpace>'
	endif
	let step = (col('.') - 1 - b:yavimim.cursor.column)
	let step_left = step - 1
	" 因为此时还没开始做退格操作，在删之后是4个就要做自动补全，所以在删之前是5个
	" 对于混拼，则是计算拼音的长度
	if step_left > 0 && step_left <= yavimim#backend#max_keys()
		let key .= '\<C-R>=g:Do_waiting_commit().yavimim#insert#complete()\<CR>' .
					\ '\<C-R>=g:Do_trigger_completion()\<CR>'
	elseif step_left == 0
		let key .= '\<C-R>=g:Do_after_cancel()\<CR>'
	endif
	silent execute printf('return "%s"', key)
endfunction

function! yavimim#insert#enter()
	let key = '\<CR>'
	if b:yavimim.state == 1
		let key = pumvisible() ? '\<C-E>' : ''
		let key .= repeat('\<BS>', strlen(b:yavimim.base))
		let key .= '\<C-R>=g:Do_after_cancel()\<CR>'
	endif
	silent execute printf('return "%s"', key)
endfunction

function! yavimim#insert#ctrl_e()
	let key = '\<C-E>\<C-R>=g:Do_after_cancel()\<CR>'
	silent execute printf('return "%s"', key)
endfunction

function! yavimim#insert#number(number)
	let l:number = a:number
	if l:number == 0 && b:yavimim.state == 1
		let l:number = 10
	endif
	if b:yavimim.state == 1
		let minus = l:number - b:yavimim.pmenu
		let step = max([minus, 0 - minus])
		let direction = minus > 0 ? '\<Down>' : '\<Up>'
		let l:key = repeat(direction, step) . '\<C-Y>'
		silent execute printf('return "%s%s"', l:key,
					\ '\<C-R>=g:Do_after_commit()\<CR>')
	else
		return l:number
	endif
endfunction

function! yavimim#insert#letter(char)
	let im = yavimim#backend#getim()
	return s:lmap_letter_{im.type}(a:char)
endfunction

function! s:lmap_letter_wubi(char)
	" 五笔
	" 检测我们是否已经输入四个可用字母，此时就可以上屏了
	let b:yavimim.page_nr = 1
	let b:yavimim.pmenu = 0
	call s:fix_cursor_position()
	let l:len = col('.') - b:yavimim.cursor.column - 1
	let key = ''
	if pumvisible() && yavimim#backend#should_auto_commit(l:len)
		let key = '\<C-N>\<C-Y>\<C-R>=g:Do_after_commit()\<CR>'
	endif
	let key .= a:char . '\<C-R>=g:Do_waiting_commit()\<CR>' .
				\ '\<C-R>=yavimim#insert#complete()\<CR>' .
				\ '\<C-R>=g:Do_trigger_completion()\<CR>'
	silent execute printf('return "%s"', key)
endfunction

function! yavimim#insert#special(char)
	if pumvisible()
		" 检查 popup menu 是否高亮被选中
		" :help popupmenu-completion
		let now = getline(b:yavimim.cursor.line)
					\[b:yavimim.cursor.column:col('.') - 2]
		let key = ''
		if now == b:yavimim.base && b:yavimim.pmenu == 0
			let key .= '\<C-N>'
		endif
		let key .= '\<C-Y>\<C-R>=g:Do_after_commit()\<CR>' . a:char
	else
		let key = a:char . '\<C-R>=g:Set_after_insert_beside_chinese()\<CR>'
	endif
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
		let key .= '\<C-Y>\<C-R>=g:Do_after_commit()\<CR>'
	else
		let key = '\<Space>\<C-R>=g:Set_after_insert_beside_chinese()\<CR>'
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

function! yavimim#insert#complete()
		call s:fix_cursor_position()
		let base = getline(b:yavimim.cursor.line)
					\[b:yavimim.cursor.column:col('.') - 2]
		if !strlen(base)
			return ''
		endif
		let b:yavimim.base = base
		let b:yavimim.has = yavimim#backend#has(base)
		if !b:yavimim.has
			return ''
		endif
		call complete(col('.') - strlen(base), yavimim#backend#matches(base))
		return ''
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
