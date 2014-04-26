" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
if exists('g:_yavimim_loaded')
	finish
endif
let g:_yavimim_loaded = 1

"===============================================================================
" 用户配置段
"===============================================================================
" 默认加载的输入法列表 五笔拼音 五笔QQ
let g:yavimim_imlist = get(g:, 'yavimim_imlist', 'wbpy,wbqq')

" 默认输入法 五笔QQ
let g:yavimim_im = get(g:, 'yavimim_im', 'wbqq')

" 繁体 禁用
let g:yavimim_traditional = get(g:, 'yavimim_traditional', 0)

" 逗号分隔，前一个数字代表命令行模式下的候选词个数，后一个数字代表插入模式下
" 的候选词个数，如果为一个单独的数字，则表示这两种模式下候选词个数均为该值。
"" let g:yavimim_number = '5' " 候选词个数 5 5
" 候选词个数，逗号分隔 5 10
let g:yavimim_number = get(g:, 'yavimim_number', '5,10')

" 自动上屏 启用
let g:yavimim_auto_commit = get(g:, 'yavimim_auto_commit', 1)

" 键盘布局 pc103
let g:yavimim_vkbl = get(g:, 'yavimim_vkbl', 'pc103')

" 提示信息 显示
let g:yavimim_verbose = get(g:, 'yavimim_verbose', 1)

" 用户数据目录
" user.txt 用户词库数据
" cache/ 数据缓存
let s:user_dir = has("win32") ? '~/_yavimim/' : '~/.yavimim/'
let g:yavimim_user_dir = get(g:, 'yavimim_user_dir', s:user_dir)
"===============================================================================
" 主程序
"===============================================================================
let g:yavimim_key_trigger = get(g:, 'yavimim_key_trigger', '')
let s:key_trigger = [g:yavimim_key_trigger]
" hack, <C-Space> maybe <Nul> in terminal. I didn't fully test this behavior.
if g:yavimim_key_trigger ==? '<C-Space>' && !has("gui_running")
	let s:key_trigger += ['<Nul>']
endif
for key in s:key_trigger
	silent execute printf(
				\ "inoremap <silent> <expr> %s yavimim#toggle_insert()", key)
	silent execute printf(
				\ "cnoremap <silent> <expr> %s yavimim#toggle_cmdline()", key)
endfor


" usage
" YDebug b:yavimim,g:yavimim
" YDebugEval b:yavimim,s:
" @TODO: 添加自定义补全，把 yavimim 中的脚本域的变量名和函数名全部加上
command -nargs=* -complete=var YDebug call yavimim#debug(<f-args>)
augroup YaVimIM
	autocmd!
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
