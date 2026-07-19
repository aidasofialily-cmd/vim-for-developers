" games/snake.vim
" A simple text-based macro game to practice fast target movement (f, t, w, b)

fun! StartSnakeGame()
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile
  
  " Draw map boundary
  call setline(1,  "=========================================")
  call setline(2,  "|                                       |")
  call setline(3,  "|     @                                 |")
  call setline(4,  "|                   *                   |")
  call setline(5,  "|                                       |")
  call setline(6,  "=========================================")
  
  echo "GAME START: Use 'f*' to jump to the food, or 't|' to hit the wall!"
endfun

command! PlaySnake call StartSnakeGame()
