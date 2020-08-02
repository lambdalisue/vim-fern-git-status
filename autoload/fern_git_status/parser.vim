let s:Promise = vital#fern#import('Async.Promise')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

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
let s:parse_status_index_map = {
      \ 'M': 'Staged',
      \ 'A': 'Staged',
      \ 'D': 'Deleted',
      \ 'R': 'Renamed',
      \ 'C': 'Staged',
      \}
let s:stained_map = {
      \ 'Unmerged': 1,
      \ 'Modified': 1,
      \ 'Deleted': 1,
      \ 'Renamed': 1,
      \ 'Staged': 1,
      \ 'Untracked': 1,
      \}

function! fern_git_status#parser#parse(root, records, enable_stained) abort
  let m = {}
  let p = s:Promise.resolve(a:records)
      \.then(s:AsyncLambda.map_f({ r -> s:parse_record(a:root, r) }))
      \.then(s:AsyncLambda.map_f({ v -> s:Lambda.let(m, v[0], v[1]) }))
      \.then({ -> m })
  if a:enable_stained
    let p = p.then({ m -> s:complete_directory_status(a:root, m) })
  endif
  return p
endfunction

function! s:parse_record(root, record) abort
  let s = s:parse_status(a:record[:1])
  let p = matchstr(a:record[3:], '\%(.* -> \)\?\zs.*$')
  return [a:root . '/' . p, s]
endfunction

function! s:parse_status(code) abort
  let s = get(s:parse_status_code_map, a:code)
  if s !=# ''
    return s
  endif
  if a:code[1] !=# ' '
    return 'Modified'
  endif
  let s = get(s:parse_status_index_map, a:code[0])
  if s !=# ''
    return s
  endif
  return 'Unknown'
endfunction

function! s:complete_directory_status(root, status_map) abort
  for [k, v] in items(a:status_map)
    if get(s:stained_map, v) isnot# 1
      continue
    endif
    let path = fnamemodify(k, ':h')
    while path !=# a:root && !has_key(a:status_map, path)
      let a:status_map[path] = 'Stained'
      let path = fnamemodify(path, ':h')
    endwhile
  endfor
  return a:status_map
endfunction
