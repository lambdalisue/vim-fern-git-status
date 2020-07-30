let s:Process = vital#fern#import('Async.Promise.Process')

function! fern#mapping#plugin_git#init(disable_default_mappings) abort
  let helper = fern#helper#new()

  nnoremap <buffer><silent> <Plug>(fern-action-plugin-git-stage) :<C-u>call <SID>call('stage')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-plugin-git-unstage) :<C-u>call <SID>call('unstage')<CR>

  if !a:disable_default_mappings
        \ && !g:fern#mapping#plugin_git#disable_default_mappings
        \ && helper.sync.get_scheme() ==# 'file'
    nmap <buffer><nowait> << <Plug>(fern-action-plugin-git-stage)
    nmap <buffer><nowait> >> <Plug>(fern-action-plugin-git-unstage)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_stage(helper) abort
  if a:helper.sync.get_scheme() !=# 'file'
    throw printf("plugin-git-stage action requires 'file' scheme")
  endif
  let root = a:helper.sync.get_root_node()
  let nodes = a:helper.sync.get_selected_nodes()
  let nodes = empty(nodes) ? [a:helper.sync.get_cursor_node()] : nodes
  let paths = map(copy(nodes), { -> v:val._path })

  call s:Process.start(['git', '-C', root._path, 'add', '--ignore-errors', '--'] + paths)
        \.then({ -> a:helper.async.update_marks([]) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> fern#hook#emit('plugin:git:update', a:helper) })
endfunction

function! s:map_unstage(helper) abort
  if a:helper.sync.get_scheme() !=# 'file'
    throw printf("plugin-git-unstage action requires 'file' scheme")
  endif
  let root = a:helper.sync.get_root_node()
  let nodes = a:helper.sync.get_selected_nodes()
  let nodes = empty(nodes) ? [a:helper.sync.get_cursor_node()] : nodes
  let paths = map(copy(nodes), { -> v:val._path })

  call s:Process.start(['git', '-C', root._path, 'reset', '--quiet', '--'] + paths)
        \.then({ -> a:helper.async.update_marks([]) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> fern#hook#emit('plugin:git:update', a:helper) })
endfunction


let g:fern#mapping#plugin_git#disable_default_mappings = get(g:, 'fern#mapping#plugin_git#disable_default_mappings', 0)
