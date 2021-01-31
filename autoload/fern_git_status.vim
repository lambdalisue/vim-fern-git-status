let s:CancellationToken = vital#fern#import('Async.CancellationToken')
let s:PROCESSING_VARNAME = 'fern_git_status_processing'

function! fern_git_status#init() abort
  if exists('s:ready')
    return
  endif
  let s:ready = 1
  call fern#hook#add('viewer:highlight', function('s:on_highlight'))
  call fern#hook#add('viewer:syntax', function('s:on_syntax'))
  call fern#hook#add('viewer:redraw', function('s:on_redraw'))
endfunction

function! s:on_highlight(...) abort
  highlight default link FernGitStatusBracket Comment
  highlight default link FernGitStatusIndex Special
  highlight default link FernGitStatusWorktree WarningMsg
  highlight default link FernGitStatusUnmerged ErrorMsg
  highlight default link FernGitStatusUntracked Comment
  highlight default link FernGitStatusIgnored Comment
endfunction

function! s:on_syntax(...) abort
  syntax match FernGitStatusBracket /.*/ contained containedin=FernBadge
  syntax match FernGitStatus /\[\zs..\ze\]/ contained containedin=FernGitStatusBracket
  syntax match FernGitStatusIndex     /./ contained containedin=FernGitStatus nextgroup=FernGitStatusWorktree
  syntax match FernGitStatusWorktree  /./ contained

  syntax match FernGitStatusUnmerged  /DD\|AU\|UD\|UA\|DU\|AA\|UU/ contained containedin=FernGitStatus

  syntax match FernGitStatusUntracked /??/ contained containedin=FernGitStatus
  syntax match FernGitStatusIgnored   /!!/ contained containedin=FernGitStatus
endfunction

function! s:on_redraw(helper) abort
  let bufnr = a:helper.bufnr
  let processing = getbufvar(bufnr, s:PROCESSING_VARNAME, 0)
  if a:helper.fern.scheme !=# 'file' || processing
    return
  endif
  let options = {
        \ 'include_ignored': !g:fern_git_status#disable_ignored,
        \ 'include_untracked': !g:fern_git_status#disable_untracked,
        \ 'include_submodules': !g:fern_git_status#disable_submodules,
        \ 'include_directories': !g:fern_git_status#disable_directories,
        \ 'indexed_character': g:fern_git_status#indexed_character,
        \ 'stained_character': g:fern_git_status#stained_character,
        \ 'indexed_patterns': g:fern_git_status#indexed_patterns,
        \ 'stained_patterns': g:fern_git_status#stained_patterns,
        \}
  call fern_git_status#investigator#investigate(a:helper, options)
        \.then({ m -> fern#logger#tap(m) })
        \.then({ m -> map(a:helper.fern.visible_nodes, { -> s:update_node(m, v:val) }) })
        \.then({ -> s:redraw(a:helper) })
        \.catch({ e -> s:handle_error(e) })
endfunction

function! s:update_node(status_map, node) abort
  let path = fern#internal#filepath#to_slash(a:node._path)
  let status = get(a:status_map, path, '')
  let a:node.badge = status ==# '' ? '' : printf(' [%s]', status)
  return a:node
endfunction

function! s:redraw(helper) abort
  let bufnr = a:helper.bufnr
  call setbufvar(bufnr, s:PROCESSING_VARNAME, 1)
  return a:helper.async.redraw()
        \.then({ -> setbufvar(bufnr, s:PROCESSING_VARNAME, 0)})
endfunction

function! s:handle_error(err) abort
  if type(a:err) is# v:t_string
    if a:err ==# s:CancellationToken.CancelledError
      return
    elseif a:err =~# '^fatal: not a git repository'
      return
    endif
  endif
  call fern#logger#error(a:err)
endfunction

let g:fern_git_status#disable_ignored = get(g:, 'fern_git_status#disable_ignored', 0)
let g:fern_git_status#disable_untracked = get(g:, 'fern_git_status#disable_untracked', 0)
let g:fern_git_status#disable_submodules = get(g:, 'fern_git_status#disable_submodules', 0)
let g:fern_git_status#disable_directories = get(g:, 'fern_git_status#disable_directories', 0)
let g:fern_git_status#indexed_character = get(g:, 'fern_git_status#indexed_character', '-')
let g:fern_git_status#stained_character = get(g:, 'fern_git_status#stained_character', '-')
let g:fern_git_status#indexed_patterns = get(g:, 'fern_git_status#indexed_patterns', [
      \ '[MARC][ MD]',
      \ 'D[ RC]',
      \])
let g:fern_git_status#stained_patterns = get(g:, 'fern_git_status#stained_patterns', [
      \ '[ MARC][MD]',
      \ '[ D][RC]',
      \ 'DD\|AU\|UD\|UA\|DU\|AA\|UU',
      \ '??',
      \])
