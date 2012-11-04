if exists('b:did_ftplugin')
	finish
endif

let b:did_ftplugin = 1

setlocal nolist
setlocal nonu
setlocal colorcolumn=
setlocal nocursorcolumn nocursorline
setlocal foldcolumn=0
setlocal nobuflisted
setlocal buftype=nofile
