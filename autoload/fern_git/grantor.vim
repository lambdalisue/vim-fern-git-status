scriptencoding utf-8

let s:Promise = vital#fern#import('Async.Promise')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:CancellationTokenSource = vital#fern#import('Async.CancellationTokenSource')

let s:PATTERN = '^$~.*[]\'

let g:fern_git#grantor#badge_map = get(g:, 'fern_git#grantor#badge_map', {
      \ 'Deleted': 'x',
      \ 'Ignored': '!',
      \ 'Modified': '*',
      \ 'Renamed': 'r',
      \ 'Staged': '+',
      \ 'Unknown': 'U',
      \ 'Unmerged': 'u',
      \ 'Untracked': '?',
      \})

function! fern_git#grantor#init() abort
  call fern#hook#add('renderer:syntax', funcref('s:syntax'))
  call fern#hook#add('renderer:highlight', funcref('s:highlight'))
  call fern#hook#add('fern_git:update', funcref('s:update'))
  call fern#hook#add('viewer:redraw', funcref('s:update'))
endfunction

function! s:update(helper) abort
  if a:helper.fern.scheme !=# 'file'
    return
  endif

  if exists('s:source')
    call s:source.cancel()
  endif
  let s:source = s:CancellationTokenSource.new()

  call fern_git#status#read(a:helper.fern.root._path, s:source.token)
        \.then({ m -> s:update_nodes(a:helper, m) })
        \.catch({ e -> s:echoerr(m) })
endfunction

function! s:update_nodes(helper, status_map) abort
  return s:Promise.resolve(a:helper.fern.nodes)
        \.then(s:AsyncLambda.map_f({ n -> s:update_node(a:status_map, n) }))
        \.then({ -> a:helper.async.redraw() })
endfunction

function! s:update_node(status_map, node) abort
  let s = get(a:status_map, a:node._path, '')
  let a:node.badge = get(g:fern_git#grantor#badge_map, s, '')
  return a:node
endfunction

function! s:echoerr(e) abort
  echohl ErrorMsg
  echomsg printf('[fern-git] %s', string(a:e))
  echohl None
endfunction

function! s:syntax(...) abort
  for [k, v] in items(g:fern_git#grantor#badge_map)
    if !empty(v)
      execute printf(
            \ 'syntax match FernGit%s /%s/ contained containedin=FernBadge',
            \ k, escape(v, s:PATTERN),
            \)
    endif
  endfor
endfunction

function! s:highlight(...) abort
  highlight default link FernGitDeleted   Title
  highlight default link FernGitIgnored   Comment
  highlight default link FernGitModified  WarningMsg
  highlight default link FernGitRenamed   Title
  highlight default link FernGitStaged    Special
  highlight default link FernGitUnknown   Comment
  highlight default link FernGitUnmerged  WarningMsg
  highlight default link FernGitUntracked Comment
endfunction
