if exists('g:loaded_fern_plugin_git')
  finish
endif
let g:loaded_fern_plugin_git = 1

call fern#plugin#git#grantor#init()
call add(g:fern#mapping#mappings, 'plugin_git')
