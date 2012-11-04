" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
let g:Powerline#Segments#yavimim#segments = Pl#Segment#Init(['yavimim',
	\ Pl#Segment#Create('statusline', '%{&l:iminsert==1 ? "五" : "英"}')
\ ])
