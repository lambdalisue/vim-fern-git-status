if exists('g:loaded_fern_git_status')
  finish
endif
let g:loaded_fern_git_status = 1

if !get(g:, 'fern_git_status_disable_startup')
  augroup fern-git-status-internal
    autocmd!
    autocmd VimEnter * ++once call fern_git_status#init()
  augroup END
endif
