" games/racinggame.vim
" A text-based racing game in a Vim buffer.
"
" CONTROLS:
" 'a' - Move Left
" 'd' - Move Right
" 'q' - Quit game early
"
" TO PLAY:
" :source racinggame.vim
" :PlayRace

function! PlayRaceGame()
    " Setup buffer
    enew
    setlocal buftype=nofile bufhidden=wipe noswapfile buflisted nonumber norelativenumber
    setlocal updatetime=100
    
    " Game state variables
    let s:car_pos = 18
    let s:obstacles = [] " List of dicts: {'row': y, 'col': x}
    let s:score = 0
    let s:game_running = 0
    let s:speed = 100 " loop delay in ms

    call s:ShowStartScreen()
endfunction

function! s:ShowStartScreen()
    let l:screen = [
    \ "=========================================",
    \ "|                                       |",
    \ "|         VIM ASCII RACER               |",
    \ "|                                       |",
    \ "|   Avoid the barriers 'X'              |",
    \ "|   Steer left:  [a]                    |",
    \ "|   Steer right: [d]                    |",
    \ "|                                       |",
    \ "|    Press [s] to Start the Engine      |",
    \ "|    Press [q] to Quit                  |",
    \ "|                                       |",
    \ "========================================="
    \ ]
    call setline(1, l:screen)
    
    " Keybinds for Start Screen
    nnoremap <buffer> <silent> s :call <SID>StartGameLoop()<CR>
    nnoremap <buffer> <silent> q :bwipeout!<CR>
endfunction

function! s:StartGameLoop()
    let s:game_running = 1
    let s:score = 0
    let s:car_pos = 18
    let s:obstacles = []
    
    " Gameplay keybinds
    nnoremap <buffer> <silent> a :call <SID>MoveCar(-2)<CR>
    nnoremap <buffer> <silent> d :call <SID>MoveCar(2)<CR>
    nnoremap <buffer> <silent> q :call <SID>GameOver()<CR>
    
    " Begin execution loop
    call s:GameTick()
endfunction

function! s:MoveCar(delta)
    if !s:game_running | return | endif
    let s:car_pos += a:delta
    " Prevent car from flying outside the tracks
    if s:car_pos < 5  | let s:car_pos = 5  | endif
    if s:car_pos > 33 | let s:car_pos = 33 | endif
    call s:Render()
endfunction

function! s:GameTick()
    if !s:game_running | return | endif

    " Move existing obstacles down
    for l:obs in s:obstacles
        let l:obs.row += 1
    endfor

    " Remove obstacles that went off screen
    call filter(s:obstacles, 'v:val.row < 13')

    " Periodically spawn new obstacles randomly
    if rand() % 3 == 0
        " Calculate random lane position between columns 5 and 33
        let l:spawn_col = 5 + (rand() % 28)
        call add(s:obstacles, {'row': 2, 'col': l:spawn_col})
    endif

    " Check Collisions (Player is at Row 11)
    for l:obs in s:obstacles
        if l:obs.row == 11
            " If obstacle hits the width of the car (3 chars wide)
            if l:obs.col >= s:car_pos && l:obs.col <= (s:car_pos + 2)
                call s:GameOver()
                return
            endif
        endif
    endfor

    " Advance score
    let s:score += 1
    
    " Draw frame
    call s:Render()

    " Trigger next tick loop
    let l:cmd = printf("call s:GameTick()")
    call timer_start(s:speed, {-> execute(l:cmd)})
endfunction

function! s:Render()
    let l:lines = []
    call add(l:lines, "=== SCORE: " . s:score . " ============================")
    
    " Generate 12 rows of tracks
    for l:r in range(2, 12)
        let l:row_str = "|   " . repeat(" ", 31) . "   |"
        
        " Draw obstacles in this row
        for l:obs in s:obstacles
            if l:obs.row == l:r
                let l:row_str = l:row_str[:l:obs.col-1] . "X" . l:row_str[l:obs.col+1:]
            endif
        endfor

        " Draw player car at Row 11
        if l:r == 11
            let l:row_str = l:row_str[:s:car_pos-1] . "A^A" . l:row_str[s:car_pos+2:]
        endif

        call add(l:lines, l:row_str)
    endfor
    
    call add(l:lines, "=========================================")
    call setline(1, l:lines)
    redraw
endfunction

function! s:GameOver()
    let s:game_running = 0
    
    let l:game_over_screen = [
    \ "=========================================",
    \ "|                                       |",
    \ "|             GAME OVER                 |",
    \ "|                                       |",
    \ "|         FINAL SCORE: " . printf("%-5d", s:score) . "            |",
    \ "|                                       |",
    \ "|                                       |",
    \ "|    Press [r] to Restart Game          |",
    \ "|    Press [q] to Quit to Vim           |",
    \ "|                                       |",
    \ "========================================="
    \ ]
    call setline(1, l:game_over_screen)
    
    " Post-game controls
    nnoremap <buffer> <silent> r :call <SID>StartGameLoop()<CR>
    nnoremap <buffer> <silent> q :bwipeout!<CR>
endfunction

command! PlayRace call PlayRaceGame()
