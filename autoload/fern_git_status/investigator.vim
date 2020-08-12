let s:Promise = vital#fern#import('Async.Promise')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:CancellationToken = vital#fern#import('Async.CancellationToken')
let s:CancellationTokenSource = vital#fern#import('Async.CancellationTokenSource')

let s:GET_TOPLEVEL_CACHE_VARNAME = 'fern_git_status_get_toplevel_cache'
let s:GET_STATUS_SOURCE_VARNAME = 'fern_git_status_get_status_source'

function! fern_git_status#investigator#investigate(helper, options) abort
  let options = extend({
        \ 'include_directories': 0,
        \}, a:options,
        \)
  let toplevel = s:get_toplevel(a:helper)
  let status = s:get_status(a:helper, options)
  if options.include_directories
    let status = status.then(funcref('s:complete_directories', [options]))
  endif
  return s:Promise.all([toplevel, status])
        \.then({ v -> call('s:prepend_toplevel', v) })
        \.then({ v -> s:dict_from_entries(v) })
endfunction

function! s:get_toplevel(helper) abort
  " Prefer cache while fern buffer is unique for the root directory
  let bufnr = a:helper.bufnr
  let cache = getbufvar(bufnr, s:GET_TOPLEVEL_CACHE_VARNAME, v:null)
  if cache isnot# v:null
    return cache
  endif
  " No cache exist, create a promise to resolve git toplevel
  let root = a:helper.fern.root._path
  let token = s:CancellationToken.none
  let p = fern_git_status#process#show_toplevel(root, token)
  call setbufvar(bufnr, s:GET_TOPLEVEL_CACHE_VARNAME, p)
  return p
endfunction

function! s:get_status(helper, options) abort
  let options = extend({
        \ 'include_ignored': 0,
        \ 'include_untracked': 0,
        \ 'include_submodules': 0,
        \}, a:options,
        \)
  " Cancel previous processs and save token source
  let bufnr = a:helper.bufnr
  let source = getbufvar(bufnr, s:GET_STATUS_SOURCE_VARNAME, { 'cancel': { -> 0 } })
  call source.cancel()
  let source = s:CancellationTokenSource.new()
  call setbufvar(bufnr, s:GET_STATUS_SOURCE_VARNAME, source)
  " Return a process to get git status
  let root = a:helper.fern.root._path
  let paths = map(copy(a:helper.fern.visible_nodes), { -> v:val._path })
  let token = source.token
  return fern_git_status#process#status(root, token, {
        \ 'paths': paths,
        \ 'include_ignored': options.include_ignored,
        \ 'include_untracked': options.include_untracked,
        \ 'include_submodules': options.include_submodules,
        \})
endfunction

function! s:prepend_toplevel(toplevel, statuses) abort
  " return map(a:statuses, { _, v -> [a:toplevel . '/' . v[0], v[1]] })
  let Profile = fern#profile#start('fern_git_status#investigator#s:prepend_toplevel')
  return s:AsyncLambda.map(a:statuses, { v -> [a:toplevel . '/' . v[0], v[1]] })
       \.finally({ -> Profile() })
endfunction

function! s:dict_from_entries(entries) abort
  let m = {}
  " call map(a:entries, { _, v -> s:Lambda.let(m, v[0], v[1]) })
  " return m
  let Profile = fern#profile#start('fern_git_status#investigator#s:dict_from_entries')
  return s:AsyncLambda.map(a:entries, { v -> s:Lambda.pass(v, s:Lambda.let(m, v[0], v[1])) })
       \.then({ -> m })
       \.finally({ -> Profile() })
endfunction

function! s:complete_directories(options, statuses) abort
  let options = extend({
        \ 'indexed_character': '-',
        \ 'stained_character': '-',
        \ 'indexed_patterns': [],
        \ 'stained_patterns': [],
        \}, a:options,
        \)
  let imap = {}
  let smap = {}
  let indexed_character = options.indexed_character
  let stained_character = options.stained_character
  let indexed_pattern = printf('^\%%(%s\)$', join(a:options.indexed_patterns, '\|'))
  let stained_pattern = printf('^\%%(%s\)$', join(a:options.stained_patterns, '\|'))
  let Profile = fern#profile#start('fern_git_status#investigator#s:complete_directories')
  try
    for [relpath, status] in a:statuses
      let dirpath = fern#internal#path#dirname(relpath)
      if status =~# indexed_pattern
        let path = dirpath
        while path !=# '' && !has_key(imap, path)
          let imap[path] = indexed_character
          let path = fern#internal#path#dirname(path)
        endwhile
      endif
      if status =~# stained_pattern
        let path = dirpath
        while path !=# '' && !has_key(smap, path)
          let smap[path] = stained_character
          let path = fern#internal#path#dirname(path)
        endwhile
      endif
    endfor
    let directory_statuses = map(
          \ uniq(sort(keys(imap) + keys(smap))),
          \ { _, v -> [v, printf('%s%s', get(imap, v, ' '), get(smap, v, ' '))] },
          \)
    return extend(a:statuses, directory_statuses)
  finally
    call Profile()
  endtry
endfunction
