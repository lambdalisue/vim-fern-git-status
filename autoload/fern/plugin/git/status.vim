let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:Promise = vital#fern#import('Async.Promise')
let s:Process = vital#fern#import('Async.Promise.Process')

let s:parse_status_code_map = {
      \ 'DD': 'Unmerged',
      \ 'AU': 'Unmerged',
      \ 'UD': 'Unmerged',
      \ 'UA': 'Unmerged',
      \ 'DU': 'Unmerged',
      \ 'AA': 'Unmerged',
      \ 'UU': 'Unmerged',
      \ '??': 'Untracked',
      \ '!!': 'Ignored',
      \}
let s:parse_status_worktree_map = {
      \ 'M': 'Modified',
      \ 'D': 'Deleted',
      \ 'R': 'Renamed',
      \ 'C': 'Renamed',
      \}
let s:parse_status_index_map = {
      \ 'D': 'Deleted',
      \ 'M': 'Staged',
      \ 'A': 'Staged',
      \ 'R': 'Renamed',
      \ 'C': 'Renamed',
      \}

function! fern#plugin#git#status#read(root, token) abort
  let t = s:git(['rev-parse', '--show-toplevel'], a:root, a:token)
        \.then({ v -> join(v.stdout, '') })
  let s = s:git(['status', '--porcelain', '-uall'], a:root, a:token)
        \.then({ v -> filter(v.stdout, { -> !empty(v:val) }) })
  let ns = {}
  let m = {}
  return s:Promise.all([t, s])
        \.then({ v -> extend(ns, { 't': v[0], 's': v[1] }) })
        \.then({ -> map(ns.s, { -> s:parse_record(v:val) }) })
        \.then(s:AsyncLambda.reduce_f({ a, v -> a + v }, []))
        \.then(s:AsyncLambda.map_f({ v -> s:Lambda.let(m, ns.t . '/' . v[1], v[0]) }))
        \.then({ -> m })
endfunction

function! s:git(args, path, token) abort
  return s:Process.start(['git', '-C', a:path] + a:args, { 'token': a:token })
endfunction

function! s:parse_record(record) abort
  let s = s:parse_status_code(a:record[:1])
  let p = matchstr(a:record[3:], '\%(.* -> \)\?\zs.*$')
  let ts = split(p, '/')
  let rs = [[s, p]]
  while len(ts) > 1
    call remove(ts, -1)
    call add(rs, [s, join(ts, '/')])
  endwhile
  return rs
endfunction

function! s:parse_status_code(code) abort
  let s = get(s:parse_status_code_map, a:code)
  if s !=# ''
    return s
  endif
  let s = get(s:parse_status_worktree_map, a:code[1])
  if s !=# ''
    return s
  endif
  let s = get(s:parse_status_index_map, a:code[0])
  if s !=# ''
    return s
  endif
  return 'Unknown'
endfunction
