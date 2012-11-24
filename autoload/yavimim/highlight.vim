" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
function! yavimim#highlight#predict()
	return yavimim#highlight#highlight(line('.'),
				\ b:yavimim.cursor.column, col('.'))
endfunction

function! yavimim#highlight#clear()
	if exists('w:yavimim_highlight_id')
		call matchdelete(w:yavimim_highlight_id)
		unlet w:yavimim_highlight_id
	endif
endfunction

function! yavimim#highlight#highlight(lnum, start, end)
	let pattern = printf("\\%%%sl\\%%>%dc.*\\%%<%dc", a:lnum, a:start, a:end)
	call yavimim#highlight#clear()
	let w:yavimim_highlight_id = matchadd('YaVimIM', pattern)
	return ''
endfunction


function! yavimim#highlight#init_color()
	" highlight lCursor
	" use matchadd or syntax?
	" conceal???
	if !hlexists('lCursorIM')
		highlight lCursorIM guifg=NONE guibg=green gui=NONE
	endif
	highlight! default link lCursor lCursorIM
	if !hlexists('YaVimIM')
		highlight link YaVimIM Visual
	endif
	if !hlexists('YaVimIMComment')
		highlight link YaVimIMComment Comment
	endif
	if !hlexists('YaVimIMKeyword')
		highlight link YaVimIMKeyword Keyword
	endif
	if !hlexists('YaVimIMNumber')
		highlight link YaVimIMNumber Number
	endif
	if !hlexists('YaVimIMWarningMsg')
		highlight link YaVimIMWarningMsg WarningMsg
	endif
	if !hlexists('YaVimIMTitle')
		highlight link YaVimIMTitle Title
	endif
	if !hlexists('YaVimIMNormal')
		highlight link YaVimIMNormal Normal
	endif
endfunction
