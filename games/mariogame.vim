" mariogame.vim
" A side-scrolling platformer mini-game written in pure Vimscript.
"
" CONTROLS:
" <Space> - Jump
" 'q'     - Quit
"
" TO PLAY:
" :source mariogame.vim
" :PlayMario

function! PlayMarioGame()
    " Create a fresh clean buffer
    enew
    setlocal buftype=nofile bufhidden=wipe noswapfile buflisted nonumber norelativenumber
    setlocal updatetime=100
    
    " Game environment states
    let s:mario_y = 7       " 7 is ground level, lower is higher in sky
    let s:mario_v = 0       " vertical velocity
    let s:score = 0
    let s:obstacles = []    " list of columns where obstacles are
    let s:coins = []        " list of dicts: {'x': col, 'y': row}
    let s:game_running = 0
    let s:tick_rate = 120   " ms per frame
    let s:distance = 0

    call s:ShowStartScreen()
endfunction

function! s:ShowStartScreen()
    let l:screen = [
    \ "=========================================================",
    \ "|                                                       |",
    \ "|                 VIM SUPER MARIO                       |",
    \ "|                                                       |",
    \ "|   Jump over obstacles 'T' and collect coins 'o'       |",
    \ "|                                                       |",
    \ "|         Controls: [<Space>] to JUMP                   |",
    \ "|                                                       |",
    \ "|         Press [s] to Start the Game                   |",
    \ "|         Press [q] to Quit Vim                         |",
    \ "|                                                       |",
    \ "========================================================="
    \ ]
    call setline(1, l:screen)
    
    nnoremap <buffer> <silent> s :call <SID>StartGameLoop()<CR>
    nnoremap <buffer> <silent> q :bwipeout!<CR>
endfunction

function! s:StartGameLoop()
    let s:game_running = 1
    let s:score = 0
    let s:distance = 0
    let s:mario_y = 7
    let s:mario_v = 0
    let s:obstacles = []
    let s:coins = []
    
    " In-game key bindings
    nnoremap <buffer> <silent> <Space> :call <SID>Jump()<CR>
    nnoremap <buffer> <silent> q :call <SID>GameOver()<CR>
    
    call s:GameTick()
endfunction

function! s:Jump()
    if !s:game_running | return | endif
    " Only allow jumping if Mario is touching the floor
    if s:mario_y == 7
        let s:mario_v = -3 " Negative velocity moves upward in terminal lines
    endif
endfunction

function! s:GameTick()
    if !s:game_running | return | endif

    " Apply gravity and update Mario vertical position
    let s:mario_v += 1 " Pull down
    let s:mario_y += s:mario_v
    
    " Hard ceiling and floor boundaries
    if s:mario_y > 7
        let s:mario_y = 7
        let s:mario_v = 0
    endif
    if s:mario_y < 2
        let s:mario_y = 2
        let s:mario_v = 0
    endif

    " Scroll items to the left
    call map(s:obstacles, 'v:val - 2')
    for l:c in s:coins
        let l:c.x -= 2
    endfor

    " Remove off-screen items
    call filter(s:obstacles, 'v:val > 2')
    call filter(s:coins, 'v:val.x > 2')

    " Periodically generate procedural levels
    let s:distance += 1
    if s:distance % 6 == 0
        if rand() % 2 == 0
            call add(s:obstacles, 50)
        else
            call add(s:coins, {'x': 50, 'y': rand() % 3 + 4})
        endif
    endif

    " Collision handling (Mario stands horizontally fixed at col 10)
    for l:obs_x in s:obstacles
        if l:obs_x == 10 && s:mario_y == 7
            call s:GameOver()
            return
        endif
    endfor

    " Coin gathering checks
    for l:c in s:coins
        if l:c.x == 10 && l:c.y == s:mario_y
            let s:score += 10
            call filter(s:coins, 'v:val != l:c')
        endif
    endfor

    call s:Render()

    " Trigger next frame cycle asynchronously
    let l:cmd = printf("call s:GameTick()")
    call timer_start(s:tick_rate, {-> execute(l:cmd)})
endfunction

function! s:Render()
    let l:lines = []
    call add(l:lines, "=== SCORE: " . printf("%04d", s:score) . " =============================================")
    
    " Draw sky and open layers (Rows 2 to 7)
    for l:r in range(2, 7)
        let l:row_str = "|" . repeat(" ", 55) . "|"
        
        " Populate coins
        for l:c in s:coins
            if l:c.y == l:r && l:c.x < 56
                let l:row_str = l:row_str[:l:c.x-1] . "o" . l:row_str[l:c.x+1:]
            endif
        endfor

        " Place Mario on his current rendering grid layer
        if s:mario_y == l:r
            let l:row_str = l:row_str[:9] . "M" . l:row_str[11:]
        endif

        call add(l:lines, l:row_str)
    endfor

    " Ground level track generation (Row 8)
    let l:ground = "|" . repeat("_", 55) . "|"
    for l:obs_x in s:obstacles
        if l:obs_x < 56
            let l:ground = l:ground[:l:obs_x-1] . "T" . l:ground[l:obs_x+1:]
        endif
    endfor
    " Put Mario on ground track if floor collision is true
    if s:mario_y == 7
        let l:ground = l:ground[:9] . "M" . l:ground[11:]
    endif
    call add(l:lines, l:ground)

    call add(l:lines, "=========================================================")
    call setline(1, l:lines)
    redraw
endfunction

function! s:GameOver()
    let s:game_running = 0
    
    let l:game_over_screen = [
    \ "=========================================================",
    \ "|                                                       |",
    \ "|                   GAME OVER                           |",
    \ "|                                                       |",
    \ "|               FINAL SCORE: " . printf("%-5d", s:score) . "                      |",
    \ "|                                                       |",
    \ "|                                                       |",
    \ "|         Press [r] to Try Again                        |",
    \ "|         Press [q] to Return to Vim                    |",
    \ "|                                                       |",
    \ "========================================================="
    \ ]
    call setline(1, l:game_over_screen)
    
    nnoremap <buffer> <silent> r :call <SID>StartGameLoop()<CR>
    nnoremap <buffer> <silent> q :bwipeout!<CR>
endfunction

command! PlayMario call PlayMarioGame()
