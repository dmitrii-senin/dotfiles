# navigation: buffers, windows, tabs, marks, jumps, quickfix

## Buffers

| Command | Action |
|---------|--------|
| `:e {file}` | open file in current window |
| `:b {name\|num}` | switch to buffer by partial name or number |
| `:ls` | list open buffers |
| `]b` / `[b` | next / prev buffer |
| `<Leader>bb` | switch to alternate buffer (`:e #`) |
| `<Leader>bd` | delete buffer (switch to prev first) |
| `C-^` | toggle alternate buffer |
| `:bufdo {cmd}` | run command in all buffers |
| `<Leader>fn` | new empty buffer |

Buffers stay open until explicitly deleted. `:ls` flags: `%`=current, `#`=alternate, `a`=active, `h`=hidden, `+`=modified.

## Windows

### Splitting

| Key | Action |
|-----|--------|
| `<Leader>ws` / `C-w s` | horizontal split |
| `<Leader>wv` / `C-w v` | vertical split |
| `<Leader>wd` / `C-w c` | close window |
| `<Leader>wz` | toggle zoom current window |
| `C-w o` | close all other windows |
| `C-w T` | move window to new tab |

### Navigation (your config: also works with zellij-nav)

| Key | Action |
|-----|--------|
| `C-h` `C-j` `C-k` `C-l` | move to left / down / up / right window |
| `C-w w` | cycle windows |
| `C-w p` | previous window |

### Resizing

| Key | Action |
|-----|--------|
| `M-S-Up` / `M-S-Down` | increase / decrease height by 2 |
| `M-S-Left` / `M-S-Right` | increase / decrease width by 2 |
| `C-w =` | equalize all windows |
| `C-w _` | maximize height |
| `C-w \|` | maximize width |
| `{n}C-w +` / `{n}C-w -` | adjust height by n |
| `{n}C-w >` / `{n}C-w <` | adjust width by n |

### Rearranging

| Key | Action |
|-----|--------|
| `C-w r` / `C-w R` | rotate windows down / up |
| `C-w x` | exchange with next window |
| `C-w H/J/K/L` | move window to far left/bottom/top/right |

## Tabs

| Key | Action |
|-----|--------|
| `<Leader><Tab><Tab>` | new tab |
| `<Leader><Tab>d` | close tab |
| `<Leader><Tab>o` | close other tabs |
| `]<Tab>` / `[<Tab>` | next / prev tab |
| `<Leader><Tab>f` / `<Leader><Tab>l` | first / last tab |
| `gt` / `gT` | next / prev tab |
| `{n}gt` | go to tab n |

## Marks

### Setting and jumping

| Key | Action |
|-----|--------|
| `m{a-z}` | set buffer-local mark |
| `m{A-Z}` | set global mark (across files) |
| `` `{mark} `` | jump to mark (exact position) |
| `'{mark}` | jump to mark (line start) |
| `:marks` | list all marks |
| `:delmarks {marks}` | delete marks |
| `<Leader>f'` | telescope: find marks |

### Special marks

| Mark | Position |
|------|----------|
| `` ` `` `` ` `` | last jump position |
| `` `. `` | last edit position |
| `` `" `` | last position when file was closed |
| `` `[ `` / `` `] `` | start / end of last yank/put |
| `` `< `` / `` `> `` | start / end of last visual selection |
| `` `^ `` | last insert position |

## Jump list and change list

| Key | Action |
|-----|--------|
| `C-o` | jump list: go back |
| `C-i` | jump list: go forward |
| `:jumps` | show jump list |
| `g;` | change list: go to older change |
| `g,` | change list: go to newer change |
| `:changes` | show change list |

Jumps are added by: searches, `G`, `gg`, `%`, `{`, `}`, marks, `C-d/u`, `:edit`, tag jumps.

## Quickfix list

| Key | Action |
|-----|--------|
| `:copen` | open quickfix window |
| `:cclose` | close quickfix window |
| `]q` / `[q` | next / prev quickfix entry |
| `:cnewer` / `:colder` | newer / older quickfix list |
| `:cdo {cmd}` | run command on each quickfix entry |
| `:cfdo {cmd}` | run command on each unique file |
| `:grep {pat} {files}` | populate quickfix (uses rg via grepprg) |
| `<Leader>lq` | Trouble: toggle quickfix |

In telescope: `Tab` to select items, `C-q` to send selection to quickfix.

## Location list

Like quickfix but per-window.

| Key | Action |
|-----|--------|
| `:lopen` | open location list |
| `:lclose` | close |
| `:lnext` / `:lprev` | next / prev entry |
| `<Leader>ll` | Trouble: toggle location list |

## Oil.nvim (file explorer)

| Key | Action |
|-----|--------|
| `<Leader>-` | open parent directory (float) |
| `<Leader>_` | open cwd (float) |
| `-` | go to parent directory |
| `<CR>` | open file/directory |
| `C-s` | open in horizontal split |
| `C-v` | open in vertical split |
| `C-t` | open in new tab |
| `C-p` | preview |
| `g.` | toggle hidden files |
| `Esc` | close oil window |

Edit filenames inline to rename. Delete lines to delete files. Add lines to create files. Save (`:w`) to apply changes.
