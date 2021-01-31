let s:Promise = vital#fern#import('Async.Promise')
let s:Process = vital#fern#import('Async.Promise.Process')
let s:AsyncLambda = vital#fern#import('Async.Lambda')


function! fern_git_status#process#show_toplevel(root, token) abort
  let args = ['git', '-C', a:root, 'rev-parse', '--show-toplevel']
  let Profile = fern#profile#start('fern_git_status#process#show_toplevel')
  return s:Process.start(args, {
        \ 'toekn': a:token,
        \ 'reject_on_failure': v:true,
        \})
        \.catch({e -> s:Promise.reject(s:normalize_error(e)) })
        \.then({v -> join(v.stdout, '') })
        \.then({v -> s:normalize_path(v) })
        \.finally({ -> Profile() })
endfunction

function! fern_git_status#process#status(root, token, options) abort
  let options = extend({
        \ 'paths': [],
        \ 'include_ignored': 0,
        \ 'include_untracked': 0,
        \ 'include_submodules': 0,
        \}, a:options,
        \)
  let args = [
        \ 'git', '-C', a:root, 'status', '--porcelain',
        \ options.include_ignored
        \   ? options.include_untracked
        \     ? '--ignored=matching'
        \     : '--ignored=traditional'
        \   : '--ignored=no',
        \ options.include_untracked ? '-uall' : '-uno',
        \ options.include_submodules
        \   ? '--ignore-submodules=none'
        \   : '--ignore-submodules=all',
        \]
  let args = args + ['--'] + options.paths
  let args = filter(args, '!empty(v:val)')

  let Profile = fern#profile#start('fern_git_status#process#status')
  return s:Process.start(args, {
        \ 'toekn': a:token,
        \ 'reject_on_failure': v:true,
        \})
        \.catch({e -> s:Promise.reject(s:normalize_error(e)) })
        \.then({ v -> v.stdout })
        \.then(s:AsyncLambda.filter_f({ v -> v !=# '' }))
        \.then(s:AsyncLambda.map_f({ v -> s:parse_status(v) }))
        \.finally({ -> Profile() })
endfunction

function! s:normalize_error(error) abort
  if type(a:error) is# v:t_dict && has_key(a:error, 'stderr')
    return join(a:error.stderr, "\n")
  endif
  return a:error
endfunction

function! s:parse_status(record) abort
  let status = a:record[:1]
  let relpath = split(a:record[3:], ' -> ')[-1]
  let relpath = relpath[-1:] ==# '/' ? relpath[:-2] : relpath
  let relpath = s:normalize_path(relpath)
  return [relpath, status]
endfunction

" NOTE:
" Git for Windows return slash separated path but the path is
" not compatible with fern's slash separated path so normalization
" is required
if has('win32')
  function! s:normalize_path(path) abort
    let filepath = fern#internal#filepath#from_slash(a:path)
    return fern#internal#filepath#to_slash(filepath)
  endfunction
else
  function! s:normalize_path(path) abort
    return a:path
  endfunction
endif
