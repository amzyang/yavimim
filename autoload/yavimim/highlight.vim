" vim: set noexpandtab tabstop=4 shiftwidth=4:
scriptencoding utf-8
function! yavimim#highlight#predict()
	let line = line('.')
	let start = b:yavimim.cursor.column
	let pattern = printf("\\%%%sl\\%%>%dc.*\\%%<%dc", line, start, col('.'))
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
