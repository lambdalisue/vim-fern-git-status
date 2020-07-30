if exists('g:loaded_fern_git')
  finish
endif
let g:loaded_fern_git = 1

call add(g:fern#mapping#mappings, 'git')
call fern_git#grantor#init()
