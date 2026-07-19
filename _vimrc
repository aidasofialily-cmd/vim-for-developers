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

" ==============================================================================
" WEBSITE EMULATOR FOR HTML FILES
" ==============================================================================

" Store configuration directory path during script execution
let s:config_dir = expand('<sfile>:p:h')

" Default emulator port (can be overridden in user settings)
if !exists('g:emulator_port')
    let g:emulator_port = 8000
endif

" Helper: Open URL in the system's default browser
function! OpenURL(url)
    if has('win32unix') && executable('cygstart')
        call system('cygstart ' . shellescape(a:url))
    elseif has('unix') && executable('xdg-open')
        call system('xdg-open ' . shellescape(a:url) . ' &')
    elseif (has('win32') || has('win64')) && executable('cmd')
        silent execute '!start ' . a:url
    elseif (has('macunix') || has('unix') && system('uname') =~ 'Darwin') && executable('open')
        call system('open ' . shellescape(a:url))
    else
        echo "Please open in browser: " . a:url
    endif
endfunction

" Function: LaunchWebsiteEmulator
" Purpose: Starts a local HTTP server in the project root and loads the active
"          HTML page inside the viewport-emulating wrapper.
function! LaunchWebsiteEmulator()
    " Save current file if it has been modified
    if &modified
        silent update
    endif

    " Determine active file path and filename
    let l:full_path = expand('%:p')
    let l:filename = expand('%:t')
    let l:ext = expand('%:e')

    " Check if python is available
    let l:python_cmd = ''
    if executable('python3')
        let l:python_cmd = 'python3'
    elseif executable('python')
        let l:python_cmd = 'python'
    else
        echoerr "[ERROR] Python is required to run the Website Emulator."
        return
    endif

    " Locate workspace root by traversing upwards for .git or _vimrc markers
    let l:root_dir = ''
    let l:root_marker = finddir('.git', '.;')
    if l:root_marker == ''
        let l:root_marker = findfile('_vimrc', '.;')
    endif

    if l:root_marker != ''
        let l:root_dir = fnamemodify(l:root_marker, ':p:h')
    else
        let l:root_dir = expand('%:p:h')
    endif

    " Fallback if l:root_dir is empty or current buffer is empty
    if l:root_dir == ''
        let l:root_dir = getcwd()
    endif

    " Calculate relative path of active file to workspace root
    let l:sep = '/'
    if has('win32') || has('win64')
        let l:sep = '\'
    endif

    let l:root_prefix = l:root_dir
    if l:root_prefix[-1:] != l:sep
        let l:root_prefix .= l:sep
    endif

    let l:rel_path = 'index.html'
    if l:full_path != '' && stridx(l:full_path, l:root_prefix) == 0
        let l:rel_path = strpart(l:full_path, len(l:root_prefix))
        let l:rel_path = substitute(l:rel_path, '\\', '/', 'g')
    elseif l:filename != ''
        let l:rel_path = l:filename
    endif

    " Define absolute path to emulator script
    let l:emulator_script = s:config_dir . '/emulator.py'

    " Ensure emulator script actually exists
    if !filereadable(l:emulator_script)
        echoerr "[ERROR] Website Emulator script not found at: " . l:emulator_script
        return
    endif

    " Spawn Python background server process serving the workspace root
    if has('win32') || has('win64')
        let l:cmd = 'start "" /min ' . l:python_cmd . ' ' . shellescape(l:emulator_script) . ' ' . g:emulator_port . ' ' . shellescape(l:root_dir)
        silent execute '!' . l:cmd
    else
        let l:cmd = l:python_cmd . ' ' . shellescape(l:emulator_script) . ' ' . g:emulator_port . ' ' . shellescape(l:root_dir) . ' > /dev/null 2>&1 &'
        silent execute '!' . l:cmd
    endif

    " Build target emulator URL
    let l:url = 'http://localhost:' . g:emulator_port . '/__emulator__?page=' . l:rel_path

    " Launch URL in browser
    echo "Launching Website Emulator..."
    call OpenURL(l:url)
endfunction

" Map Space Bar + w to launch the Website Emulator
" No trailing comments on mapping to prevent parser issues
nnoremap <leader>w :call LaunchWebsiteEmulator()<CR>
