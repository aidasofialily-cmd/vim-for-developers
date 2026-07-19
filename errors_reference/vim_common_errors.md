# Vim Common Errors & Pitfalls Reference

This guide covers common errors, warning codes, and configuration conflicts encountered while configuring and using standard Vim on Windows 10 and UNIX environments.

## 1. Comment Mappings Pitfall (Trailing Comments)
* **The Error**: Mapping actions trigger weird cursor motions, append text, or fail to find keystrokes.
* **The Cause**: In Vimscript, putting inline comments directly after mapping statements is not allowed:
  ```vim
  " INCORRECT: The comment is read as keys to press!
  nnoremap <leader>w :call LaunchWebsiteEmulator()<CR> " Launches emulator
  ```
* **The Fix**: Always place explanation comments on a **separate line** above the mapping.
  ```vim
  " CORRECT: Comment is safely parsed on its own line
  nnoremap <leader>w :call LaunchWebsiteEmulator()<CR>
  ```

## 2. Recursive Key Mappings (`map` vs `noremap`)
* **The Error**: Vim freezes, hangs, or displays a "recursive mapping" warning when pressing a hotkey.
* **The Cause**: Using recursive commands like `imap` or `nmap` where the RHS contains the mapped key itself.
* **The Fix**: Use non-recursive mappings (`noremap`, `nnoremap`, `inoremap`, `vnoremap`) by default unless recursive evaluation is intentionally desired.

## 3. Directory and Path Resolution Errors
* **The Error**: Trying to edit or save a file fails with "Can't open file for writing" or "Directory does not exist".
* **The Cause**: Standard Vim doesn't automatically create parent folders when attempting to write to a nested file path.
* **The Fix**: Leverage the custom `CreateNewFile` script defined in your `_vimrc` (accessible via `<Space> + n`). It dynamically ensures nested folders are built using:
  ```vim
  if !isdirectory(l:dirpath)
      call mkdir(l:dirpath, 'p')
  endif
  ```

## 4. Line Number Sync Conflicts
* **The Error**: The gutter displays incorrect coordinates, or relative numbers slow down large codebases.
* **The Cause**: Heavy relative calculations on legacy terminals.
* **The Fix**: Combine absolute and relative rules:
  ```vim
  set number
  set relativenumber
  ```
  This displays the actual line number at the cursor and relative coordinates elsewhere, striking the perfect balance between layout accuracy and navigation performance.
