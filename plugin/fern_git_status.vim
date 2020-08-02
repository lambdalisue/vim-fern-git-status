if exists('g:loaded_fern_git_status')
  finish
endif
let g:loaded_fern_git_status = 1

function! s:init() abort
  call fern#hook#add('renderer:highlight', function('fern_git_status#on_highlight'))
  call fern#hook#add('renderer:syntax', function('fern_git_status#on_syntax'))
  call fern#hook#add('viewer:redraw', function('fern_git_status#on_redraw'))
endfunction

augroup fern-git-status-internal
  autocmd!
  autocmd VimEnter * call s:init()
augroup END
