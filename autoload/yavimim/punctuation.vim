" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
let s:punctuation = {
			\ 'origin': [',', '.', ';', '?', '!', '\', ':'],
			\ 'trans': ['，', '。', '；', '？', '！', '、', '：']}

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
