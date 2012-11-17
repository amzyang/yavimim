" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
if exists('g:yavimim_loaded')
	finish
endif
let g:yavimim_loaded = 1

"===============================================================================
" 用户配置段
"===============================================================================
let g:yavimim_imlist      = 'wbpy, wbqq' " 默认加载的输入法列表 五笔拼音 五笔QQ
let g:yavimim_imlist      = 'wbqq, wbpy' " 默认加载的输入法列表 五笔QQ 五笔拼音
if !exists('g:yavimim_traditional')
	let g:yavimim_traditional = 0        " 禁用繁体
endif
if !exists('g:yavimim_candidate')
	let g:yavimim_candidate = 5          " 命令行候选词个数 5
endif
if !exists('g:yavimim_pumheight')
	let g:yavimim_pumheight = 10         " 插入模式候选词个数 10
endif
if !exists('g:yavimim_auto_commit')
	let g:yavimim_auto_commit = 1        " 启用自动上档
endif
"===============================================================================
" 主程序
"===============================================================================
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
