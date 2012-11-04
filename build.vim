" vim: set noexpandtab nolist tabstop=4 shiftwidth=4:
scriptencoding utf-8
let g:vimball_home = "."
e Makefile
v/^SOURCE/d
%s/^SOURCE\s\++\?=\s\+//
execute '%MkVimball!' g:plugin_name
