# fern-git-status.vim

[![fern renderer](https://img.shields.io/badge/🌿%20fern-plugin-yellowgreen)](https://github.com/lambdalisue/fern.vim)
![Support Vim 8.1 or above](https://img.shields.io/badge/support-Vim%208.1%20or%20above-yellowgreen.svg)
![Support Neovim 0.4 or above](https://img.shields.io/badge/support-Neovim%200.4%20or%20above-yellowgreen.svg)
![Support Git 2.25 or above](https://img.shields.io/badge/support-Git%202.25%20or%20above-green.svg)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Doc](https://img.shields.io/badge/doc-%3Ah%20fern--git--status-orange.svg)](doc/fern-git-status.txt)

[![reviewdog](https://github.com/lambdalisue/fern-git-status.vim/workflows/reviewdog/badge.svg)](https://github.com/lambdalisue/fern-git-status.vim/actions?query=workflow%3Areviewdog)

fern-git-status is a [fern.vim][] plugin to add git status on node's badge asynchronously like:

![fern-git-status](https://user-images.githubusercontent.com/546312/89777703-2483cd80-db47-11ea-84dc-7690d2996d89.png)

[fern.vim]: https://github.com/lambdalisue/fern.vim

## Usage

Just install the plugin and visit a git repository which has some dirty status.

## Status

The plugin shows status of nodes as [short format of git status](https://git-scm.com/docs/git-status#_short_format) like:

```
X          Y     Meaning
-------------------------------------------------
         [AMD]   not updated
M        [ MD]   updated in index
A        [ MD]   added to index
D                deleted from index
R        [ MD]   renamed in index
C        [ MD]   copied in index
[MARC]           index and work tree matches
[ MARC]     M    work tree changed since index
[ MARC]     D    deleted in work tree
[ D]        R    renamed in work tree
[ D]        C    copied in work tree
-------------------------------------------------
D           D    unmerged, both deleted
A           U    unmerged, added by us
U           D    unmerged, deleted by them
U           A    unmerged, added by them
D           U    unmerged, deleted by us
A           A    unmerged, both added
U           U    unmerged, both modified
-------------------------------------------------
?           ?    untracked
!           !    ignored
-------------------------------------------------
```

The status of directory indicates that the directory contains index (left) or work tree (right) changes.
For example, single `-` on right side means that the directory contains some work tree changes but index changes.

## Colors

See `:help fern-git-status-highlight` to customize the colors.

## Performance

Disable the following options one by one if you encounter performance issues.

```vim
" Disable listing ignored files/directories
let g:fern_git_status#disable_ignored = 1

" Disable listing untracked files
let g:fern_git_status#disable_untracked = 1

" Disable listing status of submodules
let g:fern_git_status#disable_submodules = 1

" Disable listing status of directories
let g:fern_git_status#disable_directories = 1
```

:rocket: For large repositories it is also recommended to enable the Git (2.24+)
[manyFiles
feature](https://git-scm.com/docs/git-config#Documentation/git-config.txt-featuremanyFiles)
in the working directory as follows:

```sh
git config feature.manyFiles true
```

## See also

- [fern-mapping-git.vim](https://github.com/lambdalisue/fern-mapping-git.vim) - Add git related mappings
