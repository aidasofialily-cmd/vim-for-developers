" ==============================================================================
" Vim for Developers Configuration Engine // Windows 10 Target
" ==============================================================================

" --- Core System Settings ---
set nocompatible              " Break compatibility with vi for modern features
set encoding=utf-8            " Standardize internal string processing
set fileencodings=utf-8,cp936 " Handle UTF-8 safely alongside fallback configurations
set backspace=indent,eol,start" Normalize modern backspace execution keys
syntax on                     " Enable code syntax highlighting engine
filetype plugin indent on     " Activate language-specific file rules

" --- Developer UI Parameters ---
set number                    " Show absolute line numbers
set relativenumber            " Show relative line coordinates for fast jumping
set hlsearch                  " Highlight code search matches
set incsearch                 " Jump to matches as you type the query strings
set scrolloff=8               " Maintain vertical context line buffers when scrolling
set laststatus=2              " Always display the structural status bar window

" --- Code Formatting Rules ---
set expandtab                 " Convert tab key hits into blank spaces
set shiftwidth=4              " Size of an indent step in spaces
set tabstop=4                 " Number of spaces a tab counts for in the file

" ==============================================================================
" NEW FILE CREATION TOOLSET
" ==============================================================================

" Function: CreateNewFile
" Purpose: Prompts the developer for a file path relative to the active directory, 
"          automatically creates parent directories if missing, and loads the buffer.
function! CreateNewFile()
    " Request filename input safely from the command status line
    call inputsave()
    let l:filename = input('Enter path/filename for new file: ')
    call inputrestore()
    
    " Abort if the user canceled or left it empty
    if l:filename == ''
        echo "\nOperation canceled."
        return
    endif
    
    " Extract target path structure relative to current working directory
    let l:filepath = expand('%:p:h') . '/' . l:filename
    let l:dirpath = fnamemodify(l:filepath, ':h')
    
    " Native folder structure validation and generation
    if !isdirectory(l:dirpath)
        call mkdir(l:dirpath, 'p')
    endif
    
    " Initialize the editing screen buffer with the target asset
    execute 'edit ' . fnameescape(l:filepath)
    echo "\n[SUCCESS] Loaded new buffer: " . l:filename
endfunction

" Key Binding Map
" Triggers file creation sequence in normal mode using: Space Bar + n
let mapleader = " "
nnoremap <leader>n :call CreateNewFile()<CR>

" ==============================================================================
" CODE ERRORS AND PROBLEMS (QUICKFIX WORKFLOW)
" ==============================================================================

" Auto-open quickfix window after running :make or external compiler/linter commands
" only if there are actual code errors or problems detected.
autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow

" Key Mappings for Quickfix Navigation:
" Easily open, close, and navigate through syntax/compiler errors and problems.
" Open the quickfix window to view all errors and problems
nnoremap <leader>co :copen<CR>
" Close the quickfix window
nnoremap <leader>cc :cclose<CR>
" Jump to the next code error or problem
nnoremap <leader>cn :cnext<CR>
" Jump to the previous code error or problem
nnoremap <leader>cp :cprevious<CR>

" Key Mappings for Location List Navigation:
" Easily open, close, and navigate through window-local errors and problems.
" Open the location list window
nnoremap <leader>lo :lopen<CR>
" Close the location list window
nnoremap <leader>lc :lclose<CR>
" Jump to the next location error or problem
nnoremap <leader>ln :lnext<CR>
" Jump to the previous location error or problem
nnoremap <leader>lp :lprevious<CR>
