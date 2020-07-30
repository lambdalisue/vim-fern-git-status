scriptencoding utf-8

let s:Promise = vital#fern#import('Async.Promise')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:CancellationTokenSource = vital#fern#import('Async.CancellationTokenSource')

function! fern#plugin#git#grantor#init() abort
  call fern#hook#add('viewer:redraw', funcref('s:update'))
  call fern#hook#add('plugin:git:update', funcref('s:update'))
endfunction

function! s:update(helper) abort
  if a:helper.fern.scheme !=# 'file'
    return
  endif

  if exists('s:source')
    call s:source.cancel()
  endif
  let s:source = s:CancellationTokenSource.new()

  call fern#plugin#git#status#read(a:helper.fern.root._path, s:source.token)
        \.then({ m -> s:update_nodes(a:helper, m) })
        \.catch({ e -> s:echoerr(m) })
endfunction

function! s:update_nodes(helper, status_map) abort
  let bufnr = a:helper.bufnr
  let signs = copy(a:helper.fern.visible_nodes)
  call map(signs, { k, v -> [get(a:status_map, v._path, ''), k + 1] })
  call filter(signs, { _, v -> !empty(v[0]) })
  call execute(printf('sign unplace * group=fern-plugin-git buffer=%d', bufnr))
  call map(signs, { k, v -> execute(printf(
        \ 'sign place %d group=fern-plugin-git line=%d name=FernPluginGitSign%s buffer=%d',
        \ v[1],
        \ v[1],
        \ v[0],
        \ bufnr,
        \))})
endfunction

function! s:echoerr(e) abort
  echohl ErrorMsg
  echomsg printf('[fern-plugin-git] %s', a:e)
  echohl None
endfunction

function! s:signs() abort
  sign define FernPluginGitSignDeleted   text=x texthl=FernPluginGitDeleted
  sign define FernPluginGitSignIgnored   text=i texthl=FernPluginGitIgnored
  sign define FernPluginGitSignModified  text=* texthl=FernPluginGitModified
  sign define FernPluginGitSignRenamed   text=% texthl=FernPluginGitRenamed
  sign define FernPluginGitSignStaged    text=+ texthl=FernPluginGitStaged
  sign define FernPluginGitSignUnknown   text=@ texthl=FernPluginGitUnknown
  sign define FernPluginGitSignUnmerged  text=! texthl=FernPluginGitUnmerged
  sign define FernPluginGitSignUntracked text=? texthl=FernPluginGitUntracked
endfunction
call s:signs()

function! s:highlight() abort
  highlight default link FernPluginGitDeleted   WarningMsg
  highlight default link FernPluginGitIgnored   SpecialKey
  highlight default link FernPluginGitModified  Special
  highlight default link FernPluginGitRenamed   Title
  highlight default link FernPluginGitStaged    Function
  highlight default link FernPluginGitUnknown   Comment
  highlight default link FernPluginGitUnmerged  Label
  highlight default link FernPluginGitUntracked Comment
endfunction
call s:highlight()

augroup fern_plugin_git_grantor_internal
  autocmd!
  autocmd ColorScheme * call s:highlight()
augroup END
