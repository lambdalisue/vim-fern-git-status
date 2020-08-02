let s:Process = vital#fern#import('Async.Promise.Process')
let s:Promise = vital#fern#import('Async.Promise')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:CancellationToken = vital#fern#import('Async.CancellationToken')
let s:CancellationTokenSource = vital#fern#import('Async.CancellationTokenSource')

let s:PATTERN = '^$~.*[]\'
let s:processing = 0


function! fern_git_status#on_redraw(helper) abort
  if a:helper.fern.scheme !=# 'file' || s:processing
    return
  endif

  if exists('s:source')
    call s:source.cancel()
  endif
  let s:source = s:CancellationTokenSource.new()

  call s:read(a:helper.fern.root._path, s:source.token)
        \.then({ m -> s:update_nodes(a:helper, m) })
        \.then({ -> s:redraw(a:helper) })
        \.catch({ e -> timer_start(0, { -> s:echoerr(e) }) })
endfunction

function! fern_git_status#on_highlight(...) abort
  highlight default link FernGitDeleted   Title
  highlight default link FernGitIgnored   Comment
  highlight default link FernGitModified  WarningMsg
  highlight default link FernGitRenamed   Title
  highlight default link FernGitStaged    Special
  highlight default link FernGitUnknown   Comment
  highlight default link FernGitUnmerged  WarningMsg
  highlight default link FernGitUntracked Comment
  highlight default link FernGitStained   WarningMsg
endfunction

function! fern_git_status#on_syntax(...) abort
  for [k, v] in items(g:fern_git_status#badge_map)
    if !empty(v)
      execute printf(
            \ 'syntax match FernGit%s /%s/ contained containedin=FernBadge',
            \ k, escape(v, s:PATTERN),
            \)
    endif
  endfor
endfunction

function! s:read(root, token) abort
  let t = s:Process.start(
        \ ['git', '-C', a:root, 'rev-parse', '--show-toplevel'],
        \ { 'token': a:token },
        \)
        \.then({ v -> v.exitval ? s:Promise.reject(join(v.stderr, "\n")) : v.stdout })
        \.then({ v -> join(v, '') })
  let args = [
        \ g:fern_git_status#disable_untracked ? '' : '-uall',
        \ g:fern_git_status#disable_ignored ? '' : '--ignored',
        \]
  let s = s:Process.start(
        \ ['git', '-C', a:root, 'status', '--porcelain'] + filter(args, { -> !empty(v:val) }),
        \ { 'token': a:token },
        \)
        \.then({ v -> v.exitval ? s:Promise.reject(join(v.stderr, "\n")) : v.stdout })
  return s:Promise.all([t, s])
        \.then({ v -> v + [!g:fern_git_status#disable_stained] })
        \.then({ v -> call('fern_git_status#parser#parse', v) })
endfunction

function! s:update_nodes(helper, status_map) abort
  return s:Promise.resolve(a:helper.fern.nodes)
        \.then(s:AsyncLambda.map_f({ n -> s:update_node(a:status_map, n) }))
endfunction

function! s:update_node(status_map, node) abort
  let s = get(a:status_map, a:node._path, '')
  let a:node.badge = get(g:fern_git_status#badge_map, s, '')
  return a:node
endfunction

function! s:redraw(helper) abort
  let s:processing = 1
  return a:helper.async.redraw()
        \.then({ -> s:Lambda.let(s:, 'processing', 0)})
endfunction

function! s:echoerr(error) abort
  if a:error ==# s:CancellationToken.CancelledError
    return
  endif
  echohl ErrorMsg
  for line in split(a:error, '\n')
    echomsg printf('[fern-git-status] %s', line)
  endfor
  echohl None
endfunction

let g:fern_git_status#disable_untracked = get(g:, 'fern_git_status#disable_untracked', 0)
let g:fern_git_status#disable_ignored = get(g:, 'fern_git_status#disable_ignored', 0)
let g:fern_git_status#disable_stained = get(g:, 'fern_git_status#disable_stained', 0)
let g:fern_git_status#badge_map = get(g:, 'fern_git_status#badge_map', {
      \ 'Deleted': 'x',
      \ 'Ignored': '!',
      \ 'Modified': '*',
      \ 'Renamed': 'r',
      \ 'Staged': '+',
      \ 'Stained': '"',
      \ 'Unknown': 'U',
      \ 'Unmerged': 'u',
      \ 'Untracked': '?',
      \})
