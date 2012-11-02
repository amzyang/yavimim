" vim: set noexpandtab tabstop=4 shiftwidth=4:
scriptencoding utf-8
if exists('g:yavimim')
	finish
endif

let g:yavimim = {}

noremap <silent> <unique>  :call yavimim#yavimim#toggle('normal')<CR>
inoremap <silent> <unique> <expr>  yavimim#yavimim#toggle()
lnoremap <silent> <unique> <expr>  yavimim#yavimim#toggle()

" usage
" YDebug b:yavimim,g:yavimim
" YDebugEval b:yavimim,s:
" @TODO: 添加自定义补全，把 yavimim 中的脚本域的变量名和函数名全部加上
command -nargs=* -complete=var YDebug cal yavimim#yavimim#debug(<f-args>)
augroup YaVimIM
	autocmd VimEnter *
				\ if exists('g:Powerline_loaded') && g:Powerline_loaded
				\ | call Pl#Theme#RemoveSegment('yavimim:statusline')
				\ | call Pl#Theme#InsertSegment('yavimim:statusline',
					\'before', 'fileformat')
				\ | endif
	autocmd SourcePre *autoload/Powerline/Themes/*.vim
				\ if exists('g:Powerline_loaded') && g:Powerline_loaded
				\ | call yavimim#util#powerline_hook()
				\ | endif
augroup END
