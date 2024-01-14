" ensure correct basic settings
set fileencoding=utf-8

" show line numbers
set number

" set keybinds (home/end)
noremap <C-a> <Home>
imap <C-a> <Home>
noremap <C-e> <End>
imap <C-e> <End>

" expand all tabs and indents to 4 spaces
set tabstop=4
set shiftwidth=4
set expandtab
autocmd FileType go,html,php,css set noexpandtab

" set default clipboard register to system clipboard
set clipboard=unnamedplus

" enable visually indented text wrapping
set wrap
set breakindent
set showbreak=→

" do not auto-break lines unless they are 1000+ characters long
set textwidth=1000

" do not create automatic backups of any sort
set nobackup
set nowritebackup

" default to case insensitive search unless a capital is typed
set ignorecase
set smartcase

" tell vim to remember certain things when exited
"  '10  :  marks will be remembered for up to 10 previously edited files
"  "100 :  will save up to 100 lines for each register
"  :20  :  up to 20 lines of command-line history will be remembered
"  %    :  saves and restores the buffer list
"  n... :  where to save the viminfo files
set viminfo='10,\"100,:20,%,n~/.local/share/nviminfo

" restores cursor position in recently opened files
function! ResCur()
  if line("'\"") <= line("$")
    normal! g`"
    return 1
  endif
endfunction

augroup resCur
  autocmd!
  autocmd BufWinEnter * call ResCur()
augroup END
