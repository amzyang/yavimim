scriptencoding utf-8

function! airline#extensions#yavimim#init(ext)
  call a:ext.add_statusline_func('airline#extensions#yavimim#apply')
endfunction

function! airline#extensions#yavimim#apply(...)
  let w:airline_section_b = get(w:, 'airline_section_b', g:airline_section_b)
  let w:airline_section_b .= ' %{airline#extensions#yavimim#get_yavimim()}'
endfunction

function! airline#extensions#yavimim#get_yavimim()
  if &l:iminsert != 1
    return ''
  endif
  let sim_cht = g:yavimim_traditional ? '繁' : '简'
  let im = yavimim#backend#getim()
  let name = 'name' . (g:yavimim_traditional ? '_cht' : '')
  return ' '.g:airline_left_alt_sep.' '.im[name]."·".sim_cht
endfunction
