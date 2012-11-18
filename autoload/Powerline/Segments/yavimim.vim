" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
let g:Powerline#Segments#yavimim#segments = Pl#Segment#Init(['yavimim',
	\ Pl#Segment#Create('statusline', '%{Powerline#Functions#yavimim#status()}',
	\ Pl#Segment#Modes('irR'))
\ ])
