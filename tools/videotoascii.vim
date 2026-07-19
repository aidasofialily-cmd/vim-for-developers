" videotoascii.vim
" A live video-to-ASCII player inside a Vim buffer.
"
" DEPENDENCIES:
" Make sure your system has 'ffmpeg' and 'jp2a' installed:
" macOS: brew install ffmpeg jp2a
" Linux: sudo apt install ffmpeg jp2a
"
" USAGE:
" :source videotoascii.vim
" :PlayVideo /path/to/your/video.mp4

function! PlayVideoFile(video_path)
    if empty(a:video_path) || !filereadable(a:video_path)
        echoerr "Error: Valid video file path required."
        return
    endif

    " Check dependencies
    if !executable('ffmpeg') || !executable('jp2a')
        echoerr "Missing dependencies! Please install 'ffmpeg' and 'jp2a'."
        return
    endif

    " Setup rendering buffer
    enew
    setlocal buftype=nofile bufhidden=wipe noswapfile buflisted nonumber norelativenumber
    let b:video_temp_dir = mkdir(tempname(), "p")
    let b:current_frame = 1
    let b:total_frames = 0
    let b:playback_timer = -1

    echo "Decoding video frames to temporary space... please wait..."
    redraw

    " Extract frames at 15fps, downscaling width to 70 characters for clear buffer alignment
    let l:ffmpeg_cmd = printf("ffmpeg -i %s -vf fps=15,scale=70:-1 %s/frame_%%04d.jpg", 
    \ shellescape(a:video_path), b:video_temp_dir)
    
    " Use async job so Vim doesn't lock up during initial conversion
    let l:job = job_start(['sh', '-c', l:ffmpeg_cmd], {
    \ 'close_cb': {channel -> s:StartPlayback()}
    \ })
endfunction

function! s:StartPlayback()
    " Count generated frames
    let l:frames = globpath(b:video_temp_dir, "*.jpg", 0, 1)
    let b:total_frames = len(l:frames)

    if b:total_frames == 0
        echoerr "Failed to extract frames from video."
        return
    endif

    " Map 'q' to stop playback immediately
    nnoremap <buffer> <silent> q :call <SID>StopVideo()<CR>

    " Start frame tick loop at roughly ~66ms intervals (15 FPS match)
    let b:playback_timer = timer_start(66, function('s:RenderNextFrame'), {'repeat': -1})
endfunction

function! s:RenderNextFrame(timer)
    if b:current_frame > b:total_frames
        call s:StopVideo()
        echo "Playback finished."
        return
    endif

    let l:frame_file = printf("%s/frame_%04d.jpg", b:video_temp_dir, b:current_frame)
    
    if filereadable(l:frame_file)
        " Convert frame to text matrix via jp2a tool
        let l:ascii_art = systemlist(printf("jp2a --width=70 --chars=' .:-=+*#%%@' %s", shellescape(l:frame_file)))
        
        " Replace lines in current buffer and force instantaneous repaint
        call setline(1, l:ascii_art)
        redraw
    endif

    let b:current_frame += 1
endfunction

function! s:StopVideo()
    if exists('b:playback_timer') && b:playback_timer != -1
        call timer_stop(b:playback_timer)
        let b:playback_timer = -1
    endif
    
    " Wipe clean disk artifacts left behind
    if exists('b:video_temp_dir') && isdirectory(b:video_temp_dir)
        call delete(b:video_temp_dir, "rf")
    endif
    
    echo "Video stopped."
endfunction

" Custom initialization alias binding
command! -nargs=1 -complete=file PlayVideo call PlayVideoFile(<q-args>)
