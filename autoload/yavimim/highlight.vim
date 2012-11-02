" vim: set noexpandtab tabstop=4 shiftwidth=4:
scriptencoding utf-8
function! yavimim#highlight#predict()
	return yavimim#highlight#highlight(line('.'),
				\ b:yavimim.cursor.column, col('.'))
endfunction

function! yavimim#highlight#highlight(lnum, start, end)
	let pattern = printf("\\%%%sl\\%%>%dc.*\\%%<%dc", a:lnum, a:start, a:end)
	if exists('b:yavimim.highlight_id')
		call matchdelete(b:yavimim.highlight_id)
	endif
	let b:yavimim.highlight_id = matchadd('YaVimIM', pattern)
	return ''
endfunction

" highlight lCursor
" use matchadd or syntax?
" conceal???
highlight  default lCursorIM guifg=NONE guibg=green gui=NONE
highlight! link lCursor lCursorIM
highlight link YaVimIM Visual
