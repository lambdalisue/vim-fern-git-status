if exists('g:loaded_fern_plugin_git')
  finish
endif
let g:loaded_fern_plugin_git = 1

function! s:init() abort
  call add(g:fern#mapping#mappings, 'plugin_git')
  call fern#plugin#git#grantor#init()
endfunction

augroup fern_plugin_git_internal
  autocmd! *
  autocmd User FernInit ++once call s:init()
augroup END
