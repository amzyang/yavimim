" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
let s:punctuation = {
			\ 'origin': ['.',  '?',  '!',  ',',  '\',  ';',  ':',
						\'(',  ')',  '[',
						\'$',  '^',  '*',  '_',  '~',
						\'<',  '>'],
			\ 'trans':  ['。', '？', '！', '，', '、', '；', '：',
						\'（', '）', '·',
						\'￥', '……', '×',  '——', '～',
						\'《', '》']
			\ }

let s:pairs = {
			\ 'single': ['‘',  '’'],
			\ 'double': ['“',  '”'],
			\ 'square': ['「', '」']
			\ }

function! yavimim#punctuation#origin()
	return s:punctuation.origin
endfunction

function! yavimim#punctuation#trans()
	return s:punctuation.trans
endfunction

function! yavimim#punctuation#is_in(punctuation)
	return index(yavimim#punctuation#origin(), a:punctuation) == -1 ? 0 : 1
endfunction

function! yavimim#punctuation#origin2trans(origin)
	let index = index(yavimim#punctuation#origin(), a:origin)
	return yavimim#punctuation#trans()[index]
endfunction

function! yavimim#punctuation#trans2origin(trans)
	let index = index(yavimim#punctuation#trans(), a:trans)
	return yavimim#punctuation#origin()[index]
endfunction

function! yavimim#punctuation#getpairs()
	return s:pairs
endfunction

function! yavimim#punctuation#quote(type)
	if !exists(printf('b:yavimim.%s_quote_count', a:type))
		silent execute printf("let b:yavimim.%s_quote_count = 0", a:type)
	else
		silent execute printf("let b:yavimim.%s_quote_count += 1", a:type)
	endif
	silent execute printf('return s:pairs.%s[b:yavimim.%s_quote_count %% 2]',
				\ a:type, a:type)
endfunction
