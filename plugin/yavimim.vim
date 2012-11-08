" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
if exists('g:yavimim')
	finish
endif

let g:yavimim = {}

inoremap <silent> <expr>  yavimim#toggle_insert()
cnoremap <silent> <expr>  yavimim#toggle_cmdline()

" usage
" YDebug b:yavimim,g:yavimim
" YDebugEval b:yavimim,s:
" @TODO: 添加自定义补全，把 yavimim 中的脚本域的变量名和函数名全部加上
command -nargs=* -complete=var YDebug call yavimim#debug(<f-args>)
augroup YaVimIM
	autocmd VimEnter *
				\ if exists('g:Powerline_loaded') && g:Powerline_loaded
				\ | call Pl#Theme#RemoveSegment('yavimim:statusline')
				\ | call Pl#Theme#InsertSegment('yavimim:statusline',
					\'before', 'fileformat')
				\ | call yavimim#powerline#inject()
				\ | endif
	autocmd SourcePre *autoload/Powerline/Themes/*.vim
				\ if exists('g:Powerline_loaded') && g:Powerline_loaded
				\ | call yavimim#powerline#hook()
				\ | endif
augroup END
