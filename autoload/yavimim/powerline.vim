" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8

function! yavimim#powerline#hook()
    let l:colorschemes = Pl#Colorscheme#Init([
        \ Pl#Hi#Segments(['yavimim:statusline'], {
            \ 'n': ['gray8', 'gray2'],
            \ 'i': ['mediumcyan', 'darkestblue']
            \ })
    \])

    for key in keys(l:colorschemes)
        let g:Powerline#Colorschemes#{g:Powerline_colorscheme}#colorscheme[key]
                    \ = l:colorschemes[key]
    endfor
endfunction

function! yavimim#powerline#inject()
	command -nargs=0 YaVimIMPowerline call s:powerline_inject()
endfunction

function! s:powerline_inject()
	PowerlineClearCache
	PowerlineReloadColorscheme
endfunction
